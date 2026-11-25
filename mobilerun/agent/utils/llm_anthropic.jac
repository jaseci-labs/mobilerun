import builtins;

import operator;

import from typing { Any }

import from llama_index.core.base.llms.types { LLMMetadata }

import inspect;

import from functools { wraps }

import from llama_index.llms.anthropic { Anthropic }

class MobilerunAnthropic(Anthropic) {
    def init(**kwargs: Any);

    def stream_chat(messages: Any, **kwargs: Any) -> Any;

    async def astream_chat(messages: Any, **kwargs: Any) -> Any;

    @wraps(Anthropic._prepare_chat_with_tools)
    def _prepare_chat_with_tools(*args_: Any, **kwargs: Any) -> builtins.dict[builtins.str, Any];

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

    def _get_all_kwargs(**kwargs: Any) -> builtins.dict[builtins.str, Any];

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
