impl _openai_responses_model_omits_sampling_params(model: builtins.object) -> builtins.bool {
    return `str(model or "").strip() in OPENAI_RESPONSES_MODELS_WITHOUT_SAMPLING_PARAMS;
}

impl MobilerunOpenAIResponses._validate_gpt6_reasoning(
    model: builtins.str, reasoning: builtins.object
) -> None {
    if reasoning is None {
        return;
    }
    if not isinstance(reasoning, `dict) {
        raise ValueError(f"{model} reasoning must be a mapping with an optional 'effort' value.");
    }
    effort: any = reasoning.get("effort");
    if effort is None {
        return;
    }
    supported_efforts: any = OPENAI_REASONING_EFFORTS[model];
    if effort not in supported_efforts {
        supported: any = ", ".join(sorted(supported_efforts));
        raise ValueError(
            f"{model} does not support reasoning effort {effort!r}; use one of: {supported}."
        );
    }
}

impl MobilerunOpenAIResponses._sanitize_gpt6_payload_fields(
    model: builtins.str,
    payload: builtins.dict[builtins.str, Any],
    *,
    drop_model: builtins.bool = False,
) -> builtins.dict[builtins.str, Any] {
    sanitized: any = `dict(payload);
    unsupported: any = OPENAI_RESPONSES_UNSUPPORTED_SAMPLING_PARAMS
        | OPENAI_GPT6_UNSUPPORTED_PARAMS;
    for param in unsupported {
        sanitized.pop(param, None);
    }

    `include: any = sanitized.get("include");
    if isinstance(`include, (`list, `tuple)) {
        filtered_include: any = [
            value
            for value in `include
            if value != OPENAI_GPT6_UNSUPPORTED_INCLUDE
        ];
        sanitized["include"] = filtered_include or None;
    }

    cls._validate_gpt6_reasoning(model, sanitized.get("reasoning"));
    if drop_model {
        sanitized.pop("model", None);
    }
    return sanitized;
}

impl MobilerunOpenAIResponses._gpt6_model(effective_model: builtins.object) -> builtins.str | None {
    if self.model in OPENAI_GPT6_MODELS {
        return self.model;
    }
    if effective_model in OPENAI_GPT6_MODELS {
        return `str(effective_model);
    }
    return None;
}

impl MobilerunOpenAIResponses._sanitize_call_kwargs(
    call_kwargs: builtins.dict[builtins.str, Any], *, omit_tool_choice: builtins.bool = False
) -> builtins.dict[builtins.str, Any] {
    sanitized: any = `dict(call_kwargs);
    if self._grok {
        sanitized = `dict(
            sanitize_grok_responses_kwargs(sanitized, omit_tool_choice=omit_tool_choice)
        );
        sanitized["model"] = self.model;
        return sanitized;
    }
    effective_model: any = sanitized.get("model", self.model);
    if _openai_responses_model_omits_sampling_params(effective_model) {
        for param in OPENAI_RESPONSES_UNSUPPORTED_SAMPLING_PARAMS {
            sanitized.pop(param, None);
        }
    }
    gpt6_model: any = self._gpt6_model(effective_model);
    if gpt6_model is not None {
        sanitized = self._sanitize_gpt6_payload_fields(gpt6_model, sanitized);
        if gpt6_model == OPENAI_ASTRA_MODEL {
            sanitized.setdefault("reasoning", {"effort": OPENAI_ASTRA_DEFAULT_REASONING_EFFORT});
        }
        extra_body: any = sanitized.get("extra_body");
        if isinstance(extra_body, `dict) {
            sanitized["extra_body"] = self._sanitize_gpt6_payload_fields(
                gpt6_model, extra_body, drop_model=True
            );
        }
        if self.model in OPENAI_GPT6_MODELS {
            sanitized["model"] = self.model;
        }
    }
    return sanitized;
}

impl MobilerunOpenAIResponses._get_model_kwargs(**kwargs: Any) -> builtins.dict[builtins.str, Any] {
    model_kwargs: any = super._get_model_kwargs(**kwargs);
    effective_model: any = model_kwargs.get("model", self.model);
    if self._gpt6_model(effective_model) is not None
        and "reasoning" not in model_kwargs
        and self.reasoning_options is not None
    {
        model_kwargs["reasoning"] = self.reasoning_options;
    }
    return self._sanitize_call_kwargs(model_kwargs);
}

impl MobilerunOpenAIResponses._sanitize_structured_call_kwargs(
    call_kwargs: builtins.dict[builtins.str, Any]
) -> builtins.dict[builtins.str, Any] {
    merged: any = `dict(call_kwargs);
    if not self._grok and self.model in OPENAI_GPT6_MODELS {
        configured: builtins.dict[builtins.str, Any] = {};
        if self.include is not None {
            configured["include"] = self.include;
        }
        if self.reasoning_options is not None {
            configured["reasoning"] = self.reasoning_options;
        }
        configured.update(self.additional_kwargs or {});
        configured.update(merged);
        merged = configured;
    }

    sanitized: any = self._sanitize_call_kwargs(merged, omit_tool_choice=self._grok);
    if self._grok {
        sanitized.pop("store", None);
        sanitized.pop("model", None);
        sanitized.pop("tool_choice", None);
    } elif self.model in OPENAI_GPT6_MODELS {
        sanitized.pop("model", None);
        sanitized.pop("store", None);
        sanitized.pop("tool_choice", None);
    }
    return sanitized;
}

impl MobilerunOpenAIResponses.structured_predict(
    output_cls: Any,
    prompt: Any,
    llm_kwargs: builtins.dict[builtins.str, Any] | None = None,
    **prompt_args: Any,
) -> Any {
    if self._grok {
        messages: any = prompt.format_messages(**prompt_args);
        message_dicts: any = to_openai_message_dicts(
            messages, model=self.model, is_responses_api=True
        );
        response: any = self._client.responses.parse(
            model=self._responses_model,
            input=message_dicts,
            text_format=output_cls,
            store=self.store,
            **self._sanitize_structured_call_kwargs(`dict(llm_kwargs or {})),
        );
        if response.output_parsed is not None {
            return response.output_parsed;
        }
        raise ValueError("Failed to produce a structured response from the model.");
    }
    return super.structured_predict(
        output_cls,
        prompt,
        llm_kwargs=self._sanitize_structured_call_kwargs(`dict(llm_kwargs or {})),
        **prompt_args,
    );
}

impl MobilerunOpenAIResponses.astructured_predict(
    output_cls: Any,
    prompt: Any,
    llm_kwargs: builtins.dict[builtins.str, Any] | None = None,
    **prompt_args: Any,
) -> Any {
    if self._grok {
        messages: any = prompt.format_messages(**prompt_args);
        message_dicts: any = to_openai_message_dicts(
            messages, model=self.model, is_responses_api=True
        );
        response: any = (await 
            self._aclient.responses.parse(
                model=self._responses_model,
                input=message_dicts,
                text_format=output_cls,
                store=self.store,
                **self._sanitize_structured_call_kwargs(`dict(llm_kwargs or {})),
            )
        );
        if response.output_parsed is not None {
            return response.output_parsed;
        }
        raise ValueError("Failed to produce a structured response from the model.");
    }
    return (await 
        super.astructured_predict(
            output_cls,
            prompt,
            llm_kwargs=self._sanitize_structured_call_kwargs(`dict(llm_kwargs or {})),
            **prompt_args,
        )
    );
}
