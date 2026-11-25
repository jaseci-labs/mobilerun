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

def arize_phoenix_callback_handler(**kwargs: Any) -> BaseCallbackHandler;

async def _clean_span_async(
    span_name: builtins.str, func: Callable, args: builtins.tuple, kwargs: builtins.dict
) -> any;

def clean_span(span_name: builtins.str) -> any;
