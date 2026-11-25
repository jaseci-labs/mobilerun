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

glob _current_agent: ContextVar[Optional["MobileAgent"]] = ContextVar(
    "_current_agent", default=None
);

glob _root_span_context: ContextVar[Optional[Context]] = ContextVar(
    "_root_span_context", default=None
);

glob _last_step_span_context: ContextVar[Optional[Context]] = ContextVar(
    "_last_step_span_context", default=None
);

glob MAX_IMAGE_SIZE_KB: any = 10000;

glob logger: any = logging.getLogger("mobilerun");

def set_current_agent(agent: "MobileAgent") -> None;

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
class _LangfuseTracerProvider {
    has _provider: any,
        _normalizer: any;

    def init(provider, normalizer: LangfuseSpanProcessor);

    def add_span_processor(processor: SpanProcessor) -> None;

    def __getattr__(name) -> any;
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

    def shutdown -> None;

    def force_flush(timeout_millis: builtins.int = 30000) -> builtins.bool;

    def _format_complete(span: ReadableSpan) -> None;

    def _format_chat(span: ReadableSpan) -> None;

    def _process_field(attrs: builtins.dict, field: builtins.str) -> None;

    static def _has_blocks_to_transform(data: builtins.object) -> builtins.bool;

    def _transform_and_set_field(
        attrs: builtins.dict, field: builtins.str, data: builtins.dict
    ) -> None;

    def _transform_blocks_to_content(data: builtins.dict) -> builtins.str;

    def _convert_message_array(messages: builtins.list) -> builtins.list;

    def _convert_blocks_to_content(blocks: builtins.list) -> builtins.list;

    class def _sanitize_serialized_data_uris(value: Any) -> builtins.tuple[Any, builtins.bool];

    def _process_screenshot_span(span: ReadableSpan) -> None;

    static def _prepare_image_for_native_upload(block: builtins.dict) -> Optional[builtins.dict];
}
