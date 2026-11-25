"""OpenTelemetry span preprocessing for the Langfuse integration.

Langfuse owns span export, batching, and media upload. Its processor receives
a normalized export snapshot; other processors retain the original ended span.
"""

import builtins;

import operator;

import base64;

import json;

import logging;

import from contextvars { ContextVar }

import from copy { copy }

import from typing { TYPE_CHECKING, Any, Optional }

import from opentelemetry { trace }

import from opentelemetry.attributes { BoundedAttributes }

import from opentelemetry.context { Context }

import from opentelemetry.sdk.trace { ReadableSpan, Span, SpanProcessor }

glob _current_agent: ContextVar[Optional["MobileAgent"]];

glob _root_span_context: ContextVar[Optional[Context]];

glob _last_step_span_context: ContextVar[Optional[Context]];

glob MAX_IMAGE_SIZE_KB: any;

glob logger: any;

with entry {
    _current_agent = ContextVar("_current_agent", default=None);
    _root_span_context = ContextVar("_root_span_context", default=None);
    _last_step_span_context = ContextVar("_last_step_span_context", default=None);

    MAX_IMAGE_SIZE_KB = 10000;

    logger = logging.getLogger("mobilerun");
}

def set_current_agent(agent: "MobileAgent") -> None;

"""Store the root span context for screenshots created outside an active span."""
def set_root_span_context(span: Span) -> None;

def get_root_span_context -> Optional[Context];

def set_last_step_span_context(span: Span) -> None;

def get_last_step_span_context -> Optional[Context];

"""Wrap the SDK processor without adding an exporter, queue, or uploader."""
class _LangfuseSpanProcessor(SpanProcessor) {
    def init(processor: SpanProcessor, normalizer: LangfuseSpanProcessor);

    def on_start(span: Span, parent_context: Optional[Context] = None) -> None;

    def _on_ending(span: Span) -> None;

    def on_end(span: ReadableSpan) -> None;

    def force_flush(timeout_millis: builtins.int = 30000) -> builtins.bool;

    def shutdown -> None;
}

"""Let the public Langfuse client register its processor on our provider."""
obj _LangfuseTracerProvider {
    has _provider: any,
        _normalizer: any;

    def init(provider, normalizer: LangfuseSpanProcessor);

    def add_span_processor(processor: SpanProcessor) -> None;

    def __getattr__(name) -> any;

    def __repr__ -> str;

    def __eq__(other: any) -> bool;

    def __hash__ -> int;
}

"""Enrich live spans and normalize writable Langfuse export snapshots.

    This processor deliberately does not export, batch, upload, or own threads.
    Use it through _LangfuseTracerProvider so on_end only receives private copies.
    """
class LangfuseSpanProcessor(SpanProcessor) {
    def init(agent: Optional["MobileAgent"] = None);

    has agent: Optional["MobileAgent"] {
        getter {
            return _current_agent.get();
        }
    }

    def _extract_agent_input -> Optional[builtins.dict];

    def on_start(span: Span, parent_context: Optional[Context] = None) -> None;

    def on_end(span: ReadableSpan) -> None;

    """No-op: the public Langfuse client owns exporter shutdown."""
    def shutdown -> None;

    """The processor has no queue; all preprocessing is synchronous."""
    def force_flush(timeout_millis: builtins.int = 30000) -> builtins.bool;

    def _format_complete(span: ReadableSpan) -> None;

    def _format_chat(span: ReadableSpan) -> None;

    """Normalize an OpenInference input/output value for Langfuse."""
    def _process_field(attrs: builtins.dict, field: builtins.str) -> None;

    static def _has_blocks_to_transform(data: builtins.object) -> builtins.bool;

    def _transform_and_set_field(
        attrs: builtins.dict, field: builtins.str, data: builtins.dict
    ) -> None;

    def _transform_blocks_to_content(data: builtins.dict) -> builtins.str;

    def _convert_message_array(messages: builtins.list) -> builtins.list;

    def _convert_blocks_to_content(blocks: builtins.list) -> builtins.list;

    """Apply media limits to base64 data URIs already serialized as content."""
    class def _sanitize_serialized_data_uris(value: Any) -> builtins.tuple[Any, builtins.bool];

    def _process_screenshot_span(span: ReadableSpan) -> None;

    """Return media in a form Langfuse v4 uploads during span export."""
    static def _prepare_image_for_native_upload(block: builtins.dict) -> Optional[builtins.dict];
}
