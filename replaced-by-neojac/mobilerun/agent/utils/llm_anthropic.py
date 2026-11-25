"""MobilerunAnthropic, kept apart so its provider package loads only when used."""

from mobilerun.agent.providers.anthropic import ANTHROPIC_UNSUPPORTED_SAMPLING_PARAMS
from typing import Any
from llama_index.core.base.llms.types import LLMMetadata
from mobilerun.agent.providers.anthropic import StreamUsage
from mobilerun.agent.providers.anthropic import anthropic_model_context_window
from mobilerun.agent.providers.anthropic import anthropic_model_omits_sampling_params
from mobilerun.agent.providers.anthropic import collect_stream_usage
import inspect
from mobilerun.agent.providers.anthropic import record_stream_usage
from functools import wraps
from llama_index.llms.anthropic import Anthropic


class MobilerunAnthropic(Anthropic):
    def __init__(self, **kwargs: Any) -> None:
        super().__init__(**kwargs)
        record_stream_usage(self._client.messages)
        record_stream_usage(self._aclient.messages, is_async=True)

    def stream_chat(self, messages: Any, **kwargs: Any) -> Any:
        usage = StreamUsage()
        with collect_stream_usage(usage):
            response = super().stream_chat(messages, **kwargs)
        return usage.track(response)

    async def astream_chat(self, messages: Any, **kwargs: Any) -> Any:
        usage = StreamUsage()
        with collect_stream_usage(usage):
            response = await super().astream_chat(messages, **kwargs)
        return usage.atrack(response)

    @wraps(Anthropic._prepare_chat_with_tools)
    def _prepare_chat_with_tools(self, *args: Any, **kwargs: Any) -> dict[str, Any]:
        # FunctionCallingProgram passes None by default, overwriting the
        # valid tool-choice object built by the upstream adapter.
        if kwargs.get("tool_choice") is None:
            kwargs.pop("tool_choice", None)
        return super()._prepare_chat_with_tools(*args, **kwargs)

    @property
    def _model_kwargs(self) -> dict[str, Any]:
        model_kwargs = Anthropic._model_kwargs.fget(self)
        if anthropic_model_omits_sampling_params(
            model_kwargs.get("model", self.model)
        ) and "temperature" not in (self.additional_kwargs or {}):
            model_kwargs.pop("temperature", None)
        return model_kwargs

    def _get_all_kwargs(self, **kwargs: Any) -> dict[str, Any]:
        model_kwargs = super()._get_all_kwargs(**kwargs)
        # LlamaIndex's structured program supplies an OpenAI-style string
        # after the Anthropic adapter has prepared its tool choice.
        tool_choice = model_kwargs.get("tool_choice")
        if isinstance(tool_choice, str) and tool_choice in {
            "auto",
            "required",
            "none",
        }:
            model_kwargs["tool_choice"] = {
                "type": "any" if tool_choice == "required" else tool_choice
            }
        extra_body = dict(model_kwargs.get("extra_body") or {})
        effective_model = extra_body.get(
            "model", model_kwargs.get("model", self.model)
        )
        if anthropic_model_omits_sampling_params(effective_model):
            for param in ANTHROPIC_UNSUPPORTED_SAMPLING_PARAMS:
                model_kwargs.pop(param, None)
                extra_body.pop(param, None)
        else:
            # Anthropic SDK 1.x removed named sampling arguments even for
            # older models whose HTTP API still supports them. Preserve
            # the SDK's extra_body precedence and older SDK signatures.
            parameters = inspect.signature(self._client.messages.create).parameters
            accepts_kwargs = any(
                p.kind == inspect.Parameter.VAR_KEYWORD for p in parameters.values()
            )
            for param in ANTHROPIC_UNSUPPORTED_SAMPLING_PARAMS:
                if (
                    param in model_kwargs
                    and param not in parameters
                    and not accepts_kwargs
                ):
                    extra_body.setdefault(param, model_kwargs.pop(param))
        if extra_body or "extra_body" in model_kwargs:
            model_kwargs["extra_body"] = extra_body
        return model_kwargs

    @property
    def metadata(self) -> LLMMetadata:
        context_window = anthropic_model_context_window(self.model)
        if context_window is None:
            return Anthropic.metadata.fget(self)
        return LLMMetadata(
            context_window=context_window,
            num_output=self.max_tokens,
            is_chat_model=True,
            model_name=self.model,
            is_function_calling_model=True,
        )
