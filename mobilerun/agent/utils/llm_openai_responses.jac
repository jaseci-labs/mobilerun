import builtins;

import from typing { Any }

import from typing { ClassVar }

import from llama_index.core.base.llms.types { LLMMetadata }

import from llama_index.llms.openai.responses { OpenAIResponses }

import from llama_index.llms.openai.utils { to_openai_message_dicts }

glob OPENAI_RESPONSES_MODELS_WITHOUT_SAMPLING_PARAMS: any = {
    "gpt-6-astra",
    "gpt-6.1-sol",
    "gpt-6-sol",
    "gpt-6-luna",
    "gpt-5.6-sol",
    "gpt-5.6-terra",
    "gpt-5.6-luna",
    "gpt-5.4",
    "gpt-5.4-mini",
    "gpt-5.4-nano",
};

glob OPENAI_RESPONSES_UNSUPPORTED_SAMPLING_PARAMS: any = {"temperature", "top_p"};

glob OPENAI_ASTRA_MODEL: any = "gpt-6-astra";

glob OPENAI_GPT6_UNSUPPORTED_PARAMS: any = {"logprobs", "top_logprobs"};

glob OPENAI_GPT6_UNSUPPORTED_INCLUDE: any = "message.output_text.logprobs";

def _openai_responses_model_omits_sampling_params(model: builtins.object) -> builtins.bool;

class MobilerunOpenAIResponses(OpenAIResponses) {
    has supports_native_tool_calls: ClassVar[builtins.bool] = True;

    has _grok: ClassVar[builtins.bool] = False;

    static def _validate_gpt6_reasoning(model: builtins.str, reasoning: builtins.object) -> None;

    class def _sanitize_gpt6_payload_fields(
        model: builtins.str,
        payload: builtins.dict[builtins.str, Any],
        *,
        drop_model: builtins.bool = False,
    ) -> builtins.dict[builtins.str, Any];

    def _gpt6_model(effective_model: builtins.object) -> builtins.str | None;

    def _sanitize_call_kwargs(
        call_kwargs: builtins.dict[builtins.str, Any], *, omit_tool_choice: builtins.bool = False
    ) -> builtins.dict[builtins.str, Any];

    def _get_model_kwargs(**kwargs: Any) -> builtins.dict[builtins.str, Any];

    has metadata: LLMMetadata {
        getter {
            if self.model not in OPENAI_GPT6_MODELS {
                return OpenAIResponses.metadata.fget(self);
            }
            return LLMMetadata(
                context_window=self.context_window or OPENAI_GPT6_CONTEXT_WINDOW,
                num_output=self.max_output_tokens or -1,
                is_chat_model=True,
                is_function_calling_model=True,
                model_name=self.model,
            );
        }
    }

    def _sanitize_structured_call_kwargs(
        call_kwargs: builtins.dict[builtins.str, Any]
    ) -> builtins.dict[builtins.str, Any];

    def structured_predict(
        output_cls: Any,
        prompt: Any,
        llm_kwargs: builtins.dict[builtins.str, Any] | None = None,
        **prompt_args: Any,
    ) -> Any;

    async def astructured_predict(
        output_cls: Any,
        prompt: Any,
        llm_kwargs: builtins.dict[builtins.str, Any] | None = None,
        **prompt_args: Any,
    ) -> Any;
}

"""The same adapter speaking to xAI's Responses API."""
class MobilerunGrokResponses(MobilerunOpenAIResponses) {
    has _grok: ClassVar[builtins.bool] = True;
}

with entry {
    value_: any = "MobilerunOpenAIResponses";
    MobilerunGrokResponses.__name__ = value_;
    MobilerunGrokResponses.__qualname__ = value_;
}
