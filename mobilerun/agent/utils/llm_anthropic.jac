import builtins;

import operator;

import from typing { Any }

import from llama_index.core.base.llms.types { LLMMetadata }

import inspect;

import from functools { wraps }

import from llama_index.llms.anthropic { Anthropic }

class MobilerunAnthropic(Anthropic) {
    def init(**kwargs: Any) {
        super.__init__(**kwargs);
        record_stream_usage(self._client.messages);
        record_stream_usage(self._aclient.messages, is_async=True);
    }

    def stream_chat(messages: Any, **kwargs: Any) -> Any {
        usage: any = StreamUsage();
        with collect_stream_usage(usage) {
            response: any = super.stream_chat(messages, **kwargs);
        }
        return usage.track(response);
    }

    async def astream_chat(messages: Any, **kwargs: Any) -> Any {
        usage: any = StreamUsage();
        with collect_stream_usage(usage) {
            response: any = (await super.astream_chat(messages, **kwargs));
        }
        return usage.atrack(response);
    }

    @wraps(Anthropic._prepare_chat_with_tools)
    def _prepare_chat_with_tools(*args_: Any, **kwargs: Any) -> builtins.dict[builtins.str, Any] {
        args: any = tuple(args_);
        if kwargs.get("tool_choice") is None {
            kwargs.pop("tool_choice", None);
        }
        return super._prepare_chat_with_tools(*args, **kwargs);
    }

    has _model_kwargs: builtins.dict[builtins.str, Any] {
        getter {
            model_kwargs: any = Anthropic._model_kwargs.fget(self);
            if anthropic_model_omits_sampling_params(model_kwargs.get("model", self.model))
                and "temperature" not in (self.additional_kwargs or {})
            {
                model_kwargs.pop("temperature", None);
            }
            return model_kwargs;
        }
    }

    def _get_all_kwargs(**kwargs: Any) -> builtins.dict[builtins.str, Any] {
        model_kwargs: any = super._get_all_kwargs(**kwargs);
        tool_choice: any = model_kwargs.get("tool_choice");
        if isinstance(tool_choice, `str) and tool_choice in {"auto", "required", "none"} {
            model_kwargs["tool_choice"] = {
                "type": "any" if tool_choice == "required" else tool_choice,
            };
        }
        extra_body: any = `dict(model_kwargs.get("extra_body") or {});
        effective_model: any = extra_body.get("model", model_kwargs.get("model", self.model));
        if anthropic_model_omits_sampling_params(effective_model) {
            for param in ANTHROPIC_UNSUPPORTED_SAMPLING_PARAMS {
                model_kwargs.pop(param, None);
                extra_body.pop(param, None);
            }
        } else {
            parameters: any = inspect.signature(self._client.messages.create).parameters;
            accepts_kwargs: any = `any(
                operator.eq(p.kind, inspect.Parameter.VAR_KEYWORD) for p in parameters.values()
            );
            for param in ANTHROPIC_UNSUPPORTED_SAMPLING_PARAMS {
                if param in model_kwargs and param not in parameters and not accepts_kwargs {
                    extra_body.setdefault(param, model_kwargs.pop(param));
                }
            }
        }
        if extra_body or "extra_body" in model_kwargs {
            model_kwargs["extra_body"] = extra_body;
        }
        return model_kwargs;
    }

    has metadata: LLMMetadata {
        getter {
            context_window: any = anthropic_model_context_window(self.model);
            if context_window is None {
                return Anthropic.metadata.fget(self);
            }
            return LLMMetadata(
                context_window=context_window,
                num_output=self.max_tokens,
                is_chat_model=True,
                model_name=self.model,
                is_function_calling_model=True,
            );
        }
    }
}
