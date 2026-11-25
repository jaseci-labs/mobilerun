import builtins;

import from collections.abc { MutableMapping }

import from contextlib { contextmanager }

import from contextvars { ContextVar }

import from functools { partial, wraps }

import from typing { Any }

glob ANTHROPIC_API_DEFAULT_MODEL: any = "claude-sonnet-5";

glob ANTHROPIC_OAUTH_DEFAULT_MODEL: any = ANTHROPIC_API_DEFAULT_MODEL;

glob ANTHROPIC_FABLE_5_1_MODEL: any = "claude-fable-5-1";

glob ANTHROPIC_OPUS_5_5_MODEL: any = "claude-opus-5-5";

glob ANTHROPIC_SONNET_5_5_MODEL: any = "claude-sonnet-5-5";

glob ANTHROPIC_API_MODELS: any = (
    ANTHROPIC_API_DEFAULT_MODEL,
    ANTHROPIC_SONNET_5_5_MODEL,
    ANTHROPIC_OPUS_5_5_MODEL,
    ANTHROPIC_FABLE_5_1_MODEL,
);

glob ANTHROPIC_OAUTH_MODELS: any = (
    ANTHROPIC_OAUTH_DEFAULT_MODEL,
    ANTHROPIC_SONNET_5_5_MODEL,
    ANTHROPIC_OPUS_5_5_MODEL,
    ANTHROPIC_FABLE_5_1_MODEL,
);

glob ANTHROPIC_MODEL_CONTEXT_WINDOWS: any = {
    ANTHROPIC_SONNET_5_5_MODEL: 1000000,
    ANTHROPIC_OPUS_5_5_MODEL: 1000000,
    "claude-opus-5": 1000000,
    "claude-sonnet-5": 1000000,
    ANTHROPIC_FABLE_5_1_MODEL: 1000000,
    "claude-fable-5": 1000000,
    "claude-opus-4-8": 1000000,
    "claude-opus-4-7": 1000000,
    "claude-opus-4-6": 1000000,
    "claude-sonnet-4-6": 1000000,
    "claude-haiku-4-5": 200000,
};

glob ANTHROPIC_MODELS_WITHOUT_SAMPLING_PARAMS: any = frozenset({
    ANTHROPIC_SONNET_5_5_MODEL,
    ANTHROPIC_OPUS_5_5_MODEL,
    "claude-opus-5",
    "claude-sonnet-5",
    ANTHROPIC_FABLE_5_1_MODEL,
    "claude-fable-5",
    "claude-opus-4-8",
    "claude-opus-4-7",
});

glob ANTHROPIC_UNSUPPORTED_SAMPLING_PARAMS: any = frozenset({"temperature", "top_p", "top_k"});

glob ANTHROPIC_MODELS_WITHOUT_FORCED_TOOL_CHOICE: any = frozenset({
    ANTHROPIC_FABLE_5_1_MODEL,
    ANTHROPIC_OPUS_5_5_MODEL,
    ANTHROPIC_SONNET_5_5_MODEL,
});

glob ANTHROPIC_HIGHRES_MODELS: any = frozenset({
    "claude-opus-4-7",
    "claude-opus-4-8",
    "claude-opus-5",
    ANTHROPIC_OPUS_5_5_MODEL,
    ANTHROPIC_SONNET_5_5_MODEL,
    "claude-sonnet-5",
    ANTHROPIC_FABLE_5_1_MODEL,
    "claude-fable-5",
    "claude-mythos-5",
});

glob _stream_usage: ContextVar[StreamUsage | None];

def anthropic_model_context_window(model: object) -> int | None {
    return ANTHROPIC_MODEL_CONTEXT_WINDOWS.get(`str(model or "").strip());
}

def anthropic_model_omits_sampling_params(model: object) -> bool {
    return `str(model or "").strip() in ANTHROPIC_MODELS_WITHOUT_SAMPLING_PARAMS;
}

def strip_anthropic_sampling_params(payload: MutableMapping[str, Any]) -> MutableMapping[str, Any] {
    model: any = payload.get("model");
    if anthropic_model_omits_sampling_params(model) {
        for param in ANTHROPIC_UNSUPPORTED_SAMPLING_PARAMS {
            payload.pop(param, None);
        }
    }
    return payload;
}

"""Usage of one Anthropic stream, attached to its latest chunk.

    The LlamaIndex adapter only yields content deltas, so the usage carried by
    ``message_start`` and ``message_delta`` never reaches callers. Usage is
    written onto the last yielded chunk before the stream ends, where both
    callers and LlamaIndex callbacks read it.
    """
class StreamUsage {
    has usage: any,
        _chunk: any;

    def init {
        self.usage = {};
        self._chunk = None;
    }

    def track(chunks: Any) -> Generator[any, any, any] {
        for chunk in chunks {
            self._chunk = chunk;
            yield chunk;
        }
    }

    async def atrack(chunks: Any) -> AsyncIterator[any] {
        async for chunk in (chunks) {
            self._chunk = chunk;
            yield chunk;
        }
    }

    def record(event: Any) -> None {
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
}

with entry {
    _stream_usage = ContextVar("anthropic_stream_usage", default=None);
}

"""Record the usage of Anthropic streams opened in this block."""
@contextmanager
def collect_stream_usage(usage: StreamUsage) -> Generator[any, any, any] {
    token: any = _stream_usage.set(usage);
    try {
        yield;
    } finally {
        _stream_usage.reset(token);
    }
}

def _wrap_stream(stream: Any, usage: StreamUsage | None, kwargs: dict[str, any]) -> Any {
    if usage is None or not kwargs.get("stream") {
        return stream;
    }
    return _UsageRecordingStream(stream, usage);
}

async def _acreate(create: Any, *args_: Any, **kwargs: Any) -> Any {
    args: any = tuple(args_);
    usage: any = _stream_usage.get();
    return _wrap_stream(await create(*args, **kwargs), usage, kwargs);
}

def record_stream_usage(messages: Any, *, is_async: bool = False) -> None {
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

class _UsageRecordingStream {
    has _stream: any,
        _usage: any;

    def init(stream: Any, usage: StreamUsage) {
        self._stream = stream;
        self._usage = usage;
    }

    def __getattr__(name: str) -> Any {
        return getattr(self._stream, name);
    }

    def __iter__ -> Generator[any, any, any] {
        for event in self._stream {
            self._usage.record(event);
            yield event;
        }
    }

    async def __aiter__ -> AsyncIterator[any] {
        async for event in (self._stream) {
            self._usage.record(event);
            yield event;
        }
    }
}
