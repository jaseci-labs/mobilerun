import builtins;

import from typing { Any }

import from llama_index.llms.google_genai { GoogleGenAI }

class MobilerunGoogleGenAI(GoogleGenAI) {
    def init(**init_kwargs: Any);

    def _sanitize_call_kwargs(
        call_kwargs: builtins.dict[builtins.str, Any]
    ) -> builtins.dict[builtins.str, Any];

    def _chat(messages: Any, **kwargs: Any) -> Any;

    async def _achat(messages: Any, **kwargs: Any) -> Any;

    def _stream_chat(messages: Any, **kwargs: Any) -> Any;

    async def _astream_chat(messages: Any, **kwargs: Any) -> Any;

    def structured_predict_without_function_calling(
        output_cls: Any,
        prompt: Any,
        llm_kwargs: builtins.dict[builtins.str, Any] | None = None,
        **prompt_args: Any,
    ) -> Any;

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

    def stream_structured_predict(
        output_cls: Any,
        prompt: Any,
        llm_kwargs: builtins.dict[builtins.str, Any] | None = None,
        **prompt_args: Any,
    ) -> Any;

    async def astream_structured_predict(
        output_cls: Any,
        prompt: Any,
        llm_kwargs: builtins.dict[builtins.str, Any] | None = None,
        **prompt_args: Any,
    ) -> Any;
}
