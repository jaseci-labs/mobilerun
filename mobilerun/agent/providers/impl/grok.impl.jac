impl normalize_grok_model_id(model: object) -> str {
    model_id: any = `str(model or "").strip();
    if model_id.startswith("xai/") {
        model_id = model_id.removeprefix("xai/");
    }
    return GROK_MODEL_ALIASES.get(model_id, model_id);
}

impl sanitize_grok_responses_kwargs(
    payload: MutableMapping[str, Any],
    *,
    omit_sampler_fields: bool = False,
    omit_tool_choice: bool = False,
) -> MutableMapping[str, Any] {
    filtered_params: any = `set(GROK_UNSUPPORTED_SAMPLING_PARAMS);
    if omit_sampler_fields {
        filtered_params.update(("temperature", "top_p"));
    }
    if omit_tool_choice {
        filtered_params.add("tool_choice");
    }

    param: any;
    for param in filtered_params {
        payload.pop(param, None);
    }
    payload["store"] = False;
    payload.pop("reasoning", None);
    extra_body: any = payload.get("extra_body");
    if extra_body is not None {
        if not isinstance(extra_body, Mapping) {
            payload.pop("extra_body", None);
        } else {
            sanitized_extra_body: any = `dict(extra_body);
            for param in filtered_params {
                sanitized_extra_body.pop(param, None);
            }
            for param in ("model", "store", "reasoning") {
                sanitized_extra_body.pop(param, None);
            }
            payload["extra_body"] = sanitized_extra_body;
        }
    }
    return payload;
}
