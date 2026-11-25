import builtins;

import from typing { Any }

import from llama_index.llms.google_genai { GoogleGenAI }

class MobilerunGoogleGenAI(GoogleGenAI) {
    def init(**init_kwargs: Any) {
        super.__init__(**init_kwargs);
        if gemini_model_omits_sampling_params(self.model) {
            for param in GEMINI_UNSUPPORTED_SAMPLING_PARAMS {
                self._generation_config.pop(param, None);
            }
        }
    }

    def _sanitize_call_kwargs(
        call_kwargs: builtins.dict[builtins.str, Any]
    ) -> builtins.dict[builtins.str, Any] {
        if not gemini_model_omits_sampling_params(self.model) {
            return call_kwargs;
        }

        sanitized: any = `dict(call_kwargs);
        for param in GEMINI_UNSUPPORTED_SAMPLING_PARAMS {
            sanitized.pop(param, None);
        }

        generation_config: any = sanitized.get("generation_config");
        if generation_config is not None {
            if hasattr(generation_config, "model_dump") {
                generation_config = generation_config.model_dump();
            } elif isinstance(generation_config, `dict) {
                generation_config = `dict(generation_config);
            } else {
                return sanitized;
            }
            for param in GEMINI_UNSUPPORTED_SAMPLING_PARAMS {
                generation_config.pop(param, None);
            }
            sanitized["generation_config"] = generation_config;
        }
        return sanitized;
    }

    def _chat(messages: Any, **kwargs: Any) -> Any {
        return super._chat(messages, **self._sanitize_call_kwargs(`dict(kwargs)));
    }

    async def _achat(messages: Any, **kwargs: Any) -> Any {
        return (await super._achat(messages, **self._sanitize_call_kwargs(`dict(kwargs))));
    }

    def _stream_chat(messages: Any, **kwargs: Any) -> Any {
        return super._stream_chat(messages, **self._sanitize_call_kwargs(`dict(kwargs)));
    }

    async def _astream_chat(messages: Any, **kwargs: Any) -> Any {
        return (await super._astream_chat(messages, **self._sanitize_call_kwargs(`dict(kwargs))));
    }

    def structured_predict_without_function_calling(
        output_cls: Any,
        prompt: Any,
        llm_kwargs: builtins.dict[builtins.str, Any] | None = None,
        **prompt_args: Any,
    ) -> Any {
        return super.structured_predict_without_function_calling(
            output_cls,
            prompt,
            llm_kwargs=self._sanitize_call_kwargs(`dict(llm_kwargs or {})),
            **prompt_args,
        );
    }

    def structured_predict(
        output_cls: Any,
        prompt: Any,
        llm_kwargs: builtins.dict[builtins.str, Any] | None = None,
        **prompt_args: Any,
    ) -> Any {
        return super.structured_predict(
            output_cls,
            prompt,
            llm_kwargs=self._sanitize_call_kwargs(`dict(llm_kwargs or {})),
            **prompt_args,
        );
    }

    async def astructured_predict(
        output_cls: Any,
        prompt: Any,
        llm_kwargs: builtins.dict[builtins.str, Any] | None = None,
        **prompt_args: Any,
    ) -> Any {
        return (
            await super.astructured_predict(
                output_cls,
                prompt,
                llm_kwargs=self._sanitize_call_kwargs(`dict(llm_kwargs or {})),
                **prompt_args,
            )
        );
    }

    def stream_structured_predict(
        output_cls: Any,
        prompt: Any,
        llm_kwargs: builtins.dict[builtins.str, Any] | None = None,
        **prompt_args: Any,
    ) -> Any {
        return super.stream_structured_predict(
            output_cls,
            prompt,
            llm_kwargs=self._sanitize_call_kwargs(`dict(llm_kwargs or {})),
            **prompt_args,
        );
    }

    async def astream_structured_predict(
        output_cls: Any,
        prompt: Any,
        llm_kwargs: builtins.dict[builtins.str, Any] | None = None,
        **prompt_args: Any,
    ) -> Any {
        return (
            await super.astream_structured_predict(
                output_cls,
                prompt,
                llm_kwargs=self._sanitize_call_kwargs(`dict(llm_kwargs or {})),
                **prompt_args,
            )
        );
    }
}
