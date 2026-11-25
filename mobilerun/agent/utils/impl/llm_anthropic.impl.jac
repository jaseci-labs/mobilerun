impl MobilerunAnthropic.init(**kwargs: Any) {
    super.__init__(**kwargs);
    record_stream_usage(self._client.messages);
    record_stream_usage(self._aclient.messages, is_async=True);
}

impl MobilerunAnthropic.stream_chat(messages: Any, **kwargs: Any) -> Any {
    usage: any = StreamUsage();
    with collect_stream_usage(usage) {
        response: any = super.stream_chat(messages, **kwargs);
    }
    return usage.track(response);
}

impl MobilerunAnthropic.astream_chat(messages: Any, **kwargs: Any) -> Any {
    usage: any = StreamUsage();
    with collect_stream_usage(usage) {
        response: any = _jacm.Decimal(super.astream_chat(messages, **kwargs));
    }
    return usage.atrack(response);
}

impl MobilerunAnthropic._prepare_chat_with_tools(
    *args_: Any, **kwargs: Any
) -> builtins.dict[builtins.str, Any] {
    args: any = tuple(args_);
    if kwargs.get("tool_choice") is None {
        kwargs.pop("tool_choice", None);
    }
    return super._prepare_chat_with_tools(*args, **kwargs);
}

impl MobilerunAnthropic._get_all_kwargs(**kwargs: Any) -> builtins.dict[builtins.str, Any] {
    model_kwargs: any = super._get_all_kwargs(**kwargs);
    tool_choice: any = model_kwargs.get("tool_choice");
    if isinstance(tool_choice, `str) and tool_choice in {"auto", "required", "none"} {
        model_kwargs["tool_choice"] = {"type": "any" if tool_choice == "required" else tool_choice};
    }
    extra_body: any = `dict(model_kwargs.get("extra_body") or {});
    effective_model: any = extra_body.get("model", model_kwargs.get("model", self.model));
    if anthropic_model_omits_sampling_params(effective_model) {
        param: any;
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
