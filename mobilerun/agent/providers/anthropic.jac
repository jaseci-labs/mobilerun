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

def anthropic_model_context_window(model: object) -> int | None;

def anthropic_model_omits_sampling_params(model: object) -> bool;

def strip_anthropic_sampling_params(payload: MutableMapping[str, Any]) -> MutableMapping[str, Any];

"""Usage of one Anthropic stream, attached to its latest chunk.

    The LlamaIndex adapter only yields content deltas, so the usage carried by
    ``message_start`` and ``message_delta`` never reaches callers. Usage is
    written onto the last yielded chunk before the stream ends, where both
    callers and LlamaIndex callbacks read it.
    """
class StreamUsage {
    has usage: any,
        _chunk: any;

    def init;

    def track(chunks: Any) -> Generator[any, any, any];

    async def atrack(chunks: Any) -> AsyncIterator[any];

    def record(event: Any) -> None;
}

with entry {
    _stream_usage = ContextVar("anthropic_stream_usage", default=None);
}

"""Record the usage of Anthropic streams opened in this block."""
@contextmanager
def collect_stream_usage(usage: StreamUsage) -> Generator[any, any, any];

def _wrap_stream(stream: Any, usage: StreamUsage | None, kwargs: dict[str, any]) -> Any;

async def _acreate(create: Any, *args_: Any, **kwargs: Any) -> Any;

def record_stream_usage(messages: Any, *, is_async: bool = False) -> None;

class _UsageRecordingStream {
    has _stream: any,
        _usage: any;

    def init(stream: Any, usage: StreamUsage);

    def __getattr__(name: str) -> Any;

    def __iter__ -> Generator[any, any, any];

    async def __aiter__ -> AsyncIterator[any];
}
