"""
Arize Phoenix tracing integration for Mobilerun.

This module provides Phoenix instrumentation for tracing LLM calls and agent execution.
It includes utilities for creating custom spans with clean names and context management.
"""

import builtins;

import asyncio;

import functools;

import inspect;

import os;

import uuid;

import from contextvars { Token, copy_context }

import from typing { Any, Callable }

import from llama_index.core.callbacks.base_handler { BaseCallbackHandler }

import from llama_index_instrumentation { get_dispatcher }

import from openinference.instrumentation { TraceConfig }

glob dispatcher: any;

with entry {
    dispatcher = get_dispatcher();
}

"""
    Create and configure an Arize Phoenix callback handler for LlamaIndex.

    This function sets up OpenTelemetry tracing with Phoenix backend for monitoring
    LLM calls and agent execution.

    Args:
        **kwargs: Optional configuration overrides
            - endpoint: Phoenix server URL (default: http://0.0.0.0:6006 or PHOENIX_URL env var)
            - tracer_provider: Custom tracer provider
            - separate_trace_from_runtime_context: Separate traces from runtime context

    Returns:
        Configured LlamaIndex instrumentor instance

    Environment Variables:
        - PHOENIX_URL: Phoenix server URL
        - PHOENIX_PROJECT_NAME: Project name for organizing traces
    """
def arize_phoenix_callback_handler(**kwargs: Any) -> BaseCallbackHandler;

async def _clean_span_async(
    span_name: builtins.str, func: Callable, args: builtins.tuple, kwargs: builtins.dict
) -> any;

"""
    Create a span with a clean name (without class prefix).

    This function returns a decorator that creates spans with custom names
    instead of the default class.method format.

    It preserves parent-child relationships by using the same active span
    context variable as the built-in dispatcher decorator does.

    Args:
        span_name: The desired name for the span

    Returns:
        A decorator function
    """
def clean_span(span_name: builtins.str) -> any;
