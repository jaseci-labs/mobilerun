"""Shared Anthropic model catalog and capability metadata."""

import builtins;

import from collections.abc { Iterator, MutableMapping }

import from contextlib { contextmanager }

import from contextvars { ContextVar }

import from functools { partial, wraps }

import from typing { Any }

glob ANTHROPIC_API_DEFAULT_MODEL: any = "claude-sonnet-5";

glob ANTHROPIC_OAUTH_DEFAULT_MODEL: any;

glob ANTHROPIC_FABLE_5_1_MODEL: any;

glob ANTHROPIC_OPUS_5_5_MODEL: any;

glob ANTHROPIC_SONNET_5_5_MODEL: any;

glob ANTHROPIC_API_MODELS: any;

glob ANTHROPIC_OAUTH_MODELS: any;

glob ANTHROPIC_MODEL_CONTEXT_WINDOWS: any;

glob ANTHROPIC_MODELS_WITHOUT_SAMPLING_PARAMS: any;

glob ANTHROPIC_UNSUPPORTED_SAMPLING_PARAMS: any;

glob ANTHROPIC_MODELS_WITHOUT_FORCED_TOOL_CHOICE: any;

glob ANTHROPIC_HIGHRES_MODELS: any;

glob _stream_usage: ContextVar[StreamUsage | None];

with entry {
    ANTHROPIC_OAUTH_DEFAULT_MODEL = ANTHROPIC_API_DEFAULT_MODEL;
    ANTHROPIC_FABLE_5_1_MODEL = "claude-fable-5-1";
    ANTHROPIC_OPUS_5_5_MODEL = "claude-opus-5-5";
    ANTHROPIC_SONNET_5_5_MODEL = "claude-sonnet-5-5";

    ANTHROPIC_API_MODELS = (
        ANTHROPIC_API_DEFAULT_MODEL,
        ANTHROPIC_SONNET_5_5_MODEL,
        ANTHROPIC_OPUS_5_5_MODEL,
        ANTHROPIC_FABLE_5_1_MODEL,
    );

    ANTHROPIC_OAUTH_MODELS = (
        ANTHROPIC_OAUTH_DEFAULT_MODEL,
        ANTHROPIC_SONNET_5_5_MODEL,
        ANTHROPIC_OPUS_5_5_MODEL,
        ANTHROPIC_FABLE_5_1_MODEL,
    );
    ANTHROPIC_MODEL_CONTEXT_WINDOWS = {
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
    ANTHROPIC_MODELS_WITHOUT_SAMPLING_PARAMS = frozenset({
        ANTHROPIC_SONNET_5_5_MODEL,
        ANTHROPIC_OPUS_5_5_MODEL,
        "claude-opus-5",
        "claude-sonnet-5",
        ANTHROPIC_FABLE_5_1_MODEL,
        "claude-fable-5",
        "claude-opus-4-8",
        "claude-opus-4-7",
    });
    ANTHROPIC_UNSUPPORTED_SAMPLING_PARAMS = frozenset({"temperature", "top_p", "top_k"});
    ANTHROPIC_MODELS_WITHOUT_FORCED_TOOL_CHOICE = frozenset({
        ANTHROPIC_FABLE_5_1_MODEL,
        ANTHROPIC_OPUS_5_5_MODEL,
        ANTHROPIC_SONNET_5_5_MODEL,
    });
    ANTHROPIC_HIGHRES_MODELS = frozenset({
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
}

"""Return the verified context window for a known Anthropic model."""
def anthropic_model_context_window(model: object) -> int | None;

"""Whether the model rejects Anthropic sampling controls."""
def anthropic_model_omits_sampling_params(model: object) -> bool;

"""Remove unsupported sampling fields from a final Anthropic payload."""
def strip_anthropic_sampling_params(payload: MutableMapping[str, Any]) -> MutableMapping[str, Any];

"""Usage of one Anthropic stream, attached to its latest chunk.

    The LlamaIndex adapter only yields content deltas, so the usage carried by
    ``message_start`` and ``message_delta`` never reaches callers. Usage is
    written onto the last yielded chunk before the stream ends, where both
    callers and LlamaIndex callbacks read it.
    """
obj StreamUsage {
    has usage: any,
        _chunk: any;

    def init;

    def track(chunks: Any) -> Generator[any, any, any];

    async def atrack(chunks: Any) -> AsyncIterator[any];

    def record(event: Any) -> None;

    def __repr__ -> str;

    def __eq__(other: any) -> bool;

    def __hash__ -> int;
}

with entry {
    _stream_usage = ContextVar("anthropic_stream_usage", default=None);
}

"""Record the usage of Anthropic streams opened in this block."""
@contextmanager
def collect_stream_usage(usage: StreamUsage) -> Generator[any, any, any];

def _wrap_stream(stream: Any, usage: StreamUsage | None, kwargs: dict[str, any]) -> Any;

async def _acreate(create: Any, *args_: Any, **kwargs: Any) -> Any;

"""Wrap an SDK ``messages`` resource so streams report their usage."""
def record_stream_usage(messages: Any, *, is_async: bool = False) -> None;

obj _UsageRecordingStream {
    has _stream: any,
        _usage: any;

    def init(stream: Any, usage: StreamUsage);

    def __getattr__(name: str) -> Any;

    def __iter__ -> Generator[any, any, any];

    async def __aiter__ -> AsyncIterator[any];

    def __repr__ -> str;

    def __eq__(other: any) -> bool;

    def __hash__ -> int;
}
