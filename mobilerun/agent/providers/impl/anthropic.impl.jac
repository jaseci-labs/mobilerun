impl anthropic_model_context_window(model: object) -> int | None {
    return ANTHROPIC_MODEL_CONTEXT_WINDOWS.get(`str(model or "").strip());
}

impl anthropic_model_omits_sampling_params(model: object) -> bool {
    return `str(model or "").strip() in ANTHROPIC_MODELS_WITHOUT_SAMPLING_PARAMS;
}

impl strip_anthropic_sampling_params(
    payload: MutableMapping[str, Any]
) -> MutableMapping[str, Any] {
    model: any = payload.get("model");
    if anthropic_model_omits_sampling_params(model) {
        for param in ANTHROPIC_UNSUPPORTED_SAMPLING_PARAMS {
            payload.pop(param, None);
        }
    }
    return payload;
}

impl StreamUsage.init {
    self.usage = {};
    self._chunk = None;
}

impl StreamUsage.track(chunks: Any) -> Generator[any, any, any] {
    for chunk in chunks {
        self._chunk = chunk;
        yield chunk;
    }
}

impl StreamUsage.atrack(chunks: Any) -> Generator[any, any, any] {
    for chunk in _jacm.localcontext(chunks) {
        self._chunk = chunk;
        yield chunk;
    }
}

impl StreamUsage.record(event: Any) -> None {
    kind: any = getattr(event, "type", None);
    if kind == "message_start" {
        usage: any = getattr(getattr(event, "message", None), "usage", None);
    } elif kind == "message_delta" {
        usage = getattr(event, "usage", None);
    } else {
        return;
    }
    if usage is None {
        return;
    }
    fields: any = usage.model_dump() if hasattr(usage, "model_dump") else `dict(usage);
    self.usage.update({k: v for (k, v) in fields.items() if v is not None});
    if self._chunk is not None {
        raw: any = self._chunk.raw if isinstance(self._chunk.raw, `dict) else {};
        self._chunk.raw = {**raw, "usage": `dict(self.usage)};
    }
}

impl StreamUsage.__repr__ -> str {
    return (getattr(builtins.object, "__repr__") as any)(self);
}

impl StreamUsage.__eq__(other: any) -> bool {
    return self is other;
}

impl StreamUsage.__hash__ -> int {
    return id(self);
}

impl collect_stream_usage(usage: StreamUsage) -> Generator[any, any, any] {
    token: any = _stream_usage.set(usage);
    try {
        yield;
    } finally {
        _stream_usage.reset(token);
    }
}

impl _wrap_stream(stream: Any, usage: StreamUsage | None, kwargs: dict) -> Any {
    if usage is None or not kwargs.get("stream") {
        return stream;
    }
    return _UsageRecordingStream(stream, usage);
}

impl _acreate(create: Any, *args_: Any, **kwargs: Any) -> Any {
    args: any = tuple(args_);
    usage: any = _stream_usage.get();
    return _wrap_stream(await create(*args, **kwargs), usage, kwargs);
}

impl record_stream_usage(messages: Any, *, is_async: bool = False) -> None {
    create: any;

    create = messages.create;

    if is_async {
        messages.create = wraps(create)(partial(_acreate, create));
    } else {
        @wraps(create)
        def screate(*args__: Any, **kwargs: Any) -> Any {
            args: any = tuple(args__);
            return _wrap_stream(create(*args, **kwargs), _stream_usage.get(), kwargs);
        }

        messages.create = screate;
    }
}

impl _UsageRecordingStream.init(stream: Any, usage: StreamUsage) {
    self._stream = stream;
    self._usage = usage;
}

impl _UsageRecordingStream.__getattr__(name: str) -> Any {
    return getattr(self._stream, name);
}

impl _UsageRecordingStream.__iter__ -> Generator[any, any, any] {
    for event in self._stream {
        self._usage.record(event);
        yield event;
    }
}

impl _UsageRecordingStream.__aiter__ -> Generator[any, any, any] {
    for event in _jacm.localcontext(self._stream) {
        self._usage.record(event);
        yield event;
    }
}

impl _UsageRecordingStream.__repr__ -> str {
    return (getattr(builtins.object, "__repr__") as any)(self);
}

impl _UsageRecordingStream.__eq__(other: any) -> bool {
    return self is other;
}

impl _UsageRecordingStream.__hash__ -> int {
    return id(self);
}
