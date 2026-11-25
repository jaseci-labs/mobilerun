import builtins;

import operator;

import importlib;

import base64;

import logging;

import os;

import threading;

import from collections.abc { Iterator }

import from contextlib { contextmanager }

import from contextvars { Token }

import from typing { Any, Optional, cast }

import from uuid { uuid4 }

import llama_index.core;

glob logger: any;

glob _default_session_id: builtins.str;

glob _legacy_session_context: builtins.tuple[builtins.str, builtins.str];

glob _tracing_initialized: builtins.bool;

glob _tracing_provider: Optional[builtins.str];

glob _langfuse_client: Optional[builtins.object];

glob _langfuse_preprocessor: Optional[builtins.object];

glob _langfuse_tracer_provider: Optional[builtins.object];

glob _langfuse_setup_attempted: builtins.bool;

glob _tracing_setup_lock: any;

glob DEFAULT_LANGFUSE_BASE_URL: any;

with entry {
    logger = logging.getLogger("mobilerun");

    _default_session_id = `str(uuid4());
    _legacy_session_context = (_default_session_id, "anonymous");
    _tracing_initialized = False;
    _tracing_provider = None;
    _langfuse_client = None;
    _langfuse_preprocessor = None;
    _langfuse_tracer_provider = None;
    _langfuse_setup_attempted = False;
    _tracing_setup_lock = threading.Lock();

    DEFAULT_LANGFUSE_BASE_URL = "https://us.cloud.langfuse.com";
}

def setup_tracing(tracing_config: TracingConfig, agent: Optional[builtins.object] = None) -> None;

def _check_phoenix_reachable(
    endpoint: builtins.str, timeout: builtins.float = 3.0
) -> builtins.bool;

def _setup_phoenix_tracing -> builtins.bool;

def _setup_langfuse_tracing(
    tracing_config: TracingConfig, agent: Optional[builtins.object] = None
) -> builtins.bool;

def _resolve_langfuse_base_url(tracing_config: TracingConfig) -> builtins.str;

def _export_all_spans(_span) -> builtins.bool;

def _provider_has_langfuse_processor(tracer_provider: builtins.object) -> builtins.bool;

def _provider_has_owned_langfuse_pipeline(tracer_provider: builtins.object) -> builtins.bool;

def _provider_span_processors(tracer_provider: builtins.object) -> any;

def _attach_session_context(
    session_id: Optional[builtins.str], user_id: Optional[builtins.str]
) -> Token;

def apply_session_context -> None;

"""Scope Langfuse identifiers and agent metadata to workflow scheduling."""
@contextmanager
def session_context(
    session_id: Optional[builtins.str] = None,
    user_id: Optional[builtins.str] = None,
    agent: Optional[builtins.object] = None,
) -> Generator[any, any, any];

def record_langfuse_screenshot(
    screenshot: builtins.bytes,
    mime_type: builtins.str = "image/png",
    parent_span=None,
    screenshots_enabled: builtins.bool = False,
    vision_enabled: builtins.bool = False,
) -> None;
