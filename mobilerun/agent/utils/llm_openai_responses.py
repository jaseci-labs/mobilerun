"""MobilerunOpenAIResponses, kept apart so its provider package loads only when used."""

from typing import Any
from typing import ClassVar
from llama_index.core.base.llms.types import LLMMetadata
from mobilerun.agent.providers.registry import OPENAI_ASTRA_DEFAULT_REASONING_EFFORT
from mobilerun.agent.providers.registry import OPENAI_GPT6_CONTEXT_WINDOW
from mobilerun.agent.providers.registry import OPENAI_GPT6_MODELS
from mobilerun.agent.providers.registry import OPENAI_REASONING_EFFORTS
from mobilerun.agent.providers.grok import sanitize_grok_responses_kwargs
from llama_index.llms.openai.responses import OpenAIResponses
from llama_index.llms.openai.utils import to_openai_message_dicts
from mobilerun.agent.utils.llm_picker import (
    OPENAI_ASTRA_MODEL,
    OPENAI_GPT6_UNSUPPORTED_INCLUDE,
    OPENAI_GPT6_UNSUPPORTED_PARAMS,
    OPENAI_RESPONSES_UNSUPPORTED_SAMPLING_PARAMS,
    _openai_responses_model_omits_sampling_params,
)


class MobilerunOpenAIResponses(OpenAIResponses):
    supports_native_tool_calls: ClassVar[bool] = True
    _grok: ClassVar[bool] = False

    @staticmethod
    def _validate_gpt6_reasoning(model: str, reasoning: object) -> None:
        if reasoning is None:
            return
        if not isinstance(reasoning, dict):
            raise ValueError(
                f"{model} reasoning must be a mapping with an optional "
                "'effort' value."
            )
        effort = reasoning.get("effort")
        if effort is None:
            return
        supported_efforts = OPENAI_REASONING_EFFORTS[model]
        if effort not in supported_efforts:
            supported = ", ".join(sorted(supported_efforts))
            raise ValueError(
                f"{model} does not support reasoning effort {effort!r}; "
                f"use one of: {supported}."
            )

    @classmethod
    def _sanitize_gpt6_payload_fields(
        cls,
        model: str,
        payload: dict[str, Any],
        *,
        drop_model: bool = False,
    ) -> dict[str, Any]:
        sanitized = dict(payload)
        unsupported = (
            OPENAI_RESPONSES_UNSUPPORTED_SAMPLING_PARAMS
            | OPENAI_GPT6_UNSUPPORTED_PARAMS
        )
        for param in unsupported:
            sanitized.pop(param, None)

        include = sanitized.get("include")
        if isinstance(include, (list, tuple)):
            filtered_include = [
                value
                for value in include
                if value != OPENAI_GPT6_UNSUPPORTED_INCLUDE
            ]
            sanitized["include"] = filtered_include or None

        cls._validate_gpt6_reasoning(model, sanitized.get("reasoning"))
        if drop_model:
            sanitized.pop("model", None)
        return sanitized

    def _gpt6_model(self, effective_model: object) -> str | None:
        if self.model in OPENAI_GPT6_MODELS:
            return self.model
        if effective_model in OPENAI_GPT6_MODELS:
            return str(effective_model)
        return None

    def _sanitize_call_kwargs(
        self,
        call_kwargs: dict[str, Any],
        *,
        omit_tool_choice: bool = False,
    ) -> dict[str, Any]:
        sanitized = dict(call_kwargs)
        if self._grok:
            sanitized = dict(
                sanitize_grok_responses_kwargs(
                    sanitized,
                    omit_tool_choice=omit_tool_choice,
                )
            )
            # Runtime and additional kwargs are merged after constructor
            # defaults. Re-pin the canonical model after that final merge.
            sanitized["model"] = self.model
            return sanitized
        effective_model = sanitized.get("model", self.model)
        if _openai_responses_model_omits_sampling_params(effective_model):
            for param in OPENAI_RESPONSES_UNSUPPORTED_SAMPLING_PARAMS:
                sanitized.pop(param, None)
        gpt6_model = self._gpt6_model(effective_model)
        if gpt6_model is not None:
            sanitized = self._sanitize_gpt6_payload_fields(gpt6_model, sanitized)
            if gpt6_model == OPENAI_ASTRA_MODEL:
                # Apply the default after configured and per-call overrides.
                sanitized.setdefault(
                    "reasoning",
                    {"effort": OPENAI_ASTRA_DEFAULT_REASONING_EFFORT},
                )
            extra_body = sanitized.get("extra_body")
            if isinstance(extra_body, dict):
                sanitized["extra_body"] = self._sanitize_gpt6_payload_fields(
                    gpt6_model,
                    extra_body,
                    drop_model=True,
                )
            if self.model in OPENAI_GPT6_MODELS:
                sanitized["model"] = self.model
        return sanitized

    def _get_model_kwargs(self, **kwargs: Any) -> dict[str, Any]:
        model_kwargs = super()._get_model_kwargs(**kwargs)
        effective_model = model_kwargs.get("model", self.model)
        # llama-index forwards reasoning_options only for ids it knows.
        if (
            self._gpt6_model(effective_model) is not None
            and "reasoning" not in model_kwargs
            and self.reasoning_options is not None
        ):
            model_kwargs["reasoning"] = self.reasoning_options
        return self._sanitize_call_kwargs(model_kwargs)

    @property
    def metadata(self) -> LLMMetadata:
        if self.model not in OPENAI_GPT6_MODELS:
            return super().metadata
        return LLMMetadata(
            context_window=self.context_window or OPENAI_GPT6_CONTEXT_WINDOW,
            num_output=self.max_output_tokens or -1,
            is_chat_model=True,
            is_function_calling_model=True,
            model_name=self.model,
        )

    def _sanitize_structured_call_kwargs(
        self, call_kwargs: dict[str, Any]
    ) -> dict[str, Any]:
        merged = dict(call_kwargs)
        if not self._grok and self.model in OPENAI_GPT6_MODELS:
            configured: dict[str, Any] = {}
            if self.include is not None:
                configured["include"] = self.include
            if self.reasoning_options is not None:
                configured["reasoning"] = self.reasoning_options
            configured.update(self.additional_kwargs or {})
            configured.update(merged)
            merged = configured

        sanitized = self._sanitize_call_kwargs(merged, omit_tool_choice=self._grok)
        if self._grok:
            # The upstream structured adapter passes ``store=self.store``
            # explicitly. The constructor already pins that field false.
            # xAI also rejects tool_choice when no tools are supplied, so
            # structured parsing must not allow either the upstream default
            # or a generic caller override to restore it.
            sanitized.pop("store", None)
            sanitized.pop("model", None)
            sanitized.pop("tool_choice", None)
        elif self.model in OPENAI_GPT6_MODELS:
            # The upstream structured adapter supplies these explicitly.
            sanitized.pop("model", None)
            sanitized.pop("store", None)
            sanitized.pop("tool_choice", None)
        return sanitized

    def structured_predict(
        self,
        output_cls: Any,
        prompt: Any,
        llm_kwargs: dict[str, Any] | None = None,
        **prompt_args: Any,
    ) -> Any:
        if self._grok:
            messages = prompt.format_messages(**prompt_args)
            message_dicts = to_openai_message_dicts(
                messages, model=self.model, is_responses_api=True
            )
            response = self._client.responses.parse(
                model=self._responses_model,
                input=message_dicts,
                text_format=output_cls,
                store=self.store,
                **self._sanitize_structured_call_kwargs(dict(llm_kwargs or {})),
            )
            if response.output_parsed is not None:
                return response.output_parsed
            raise ValueError(
                "Failed to produce a structured response from the model."
            )
        return super().structured_predict(
            output_cls,
            prompt,
            llm_kwargs=self._sanitize_structured_call_kwargs(
                dict(llm_kwargs or {})
            ),
            **prompt_args,
        )

    async def astructured_predict(
        self,
        output_cls: Any,
        prompt: Any,
        llm_kwargs: dict[str, Any] | None = None,
        **prompt_args: Any,
    ) -> Any:
        if self._grok:
            messages = prompt.format_messages(**prompt_args)
            message_dicts = to_openai_message_dicts(
                messages, model=self.model, is_responses_api=True
            )
            response = await self._aclient.responses.parse(
                model=self._responses_model,
                input=message_dicts,
                text_format=output_cls,
                store=self.store,
                **self._sanitize_structured_call_kwargs(dict(llm_kwargs or {})),
            )
            if response.output_parsed is not None:
                return response.output_parsed
            raise ValueError(
                "Failed to produce a structured response from the model."
            )
        return await super().astructured_predict(
            output_cls,
            prompt,
            llm_kwargs=self._sanitize_structured_call_kwargs(
                dict(llm_kwargs or {})
            ),
            **prompt_args,
        )


class MobilerunGrokResponses(MobilerunOpenAIResponses):
    """The same adapter speaking to xAI's Responses API."""

    _grok: ClassVar[bool] = True


MobilerunGrokResponses.__name__ = MobilerunGrokResponses.__qualname__ = "MobilerunOpenAIResponses"
