import builtins;

import operator;

import asyncio;

import logging;

import from typing { Optional, Type, TypeVar }

import from llama_index.core.base.llms.types {
    ChatMessage,
    ChatResponse,
    CompletionResponse,
    ToolCallBlock,
}

import from llama_index.core.prompts { PromptTemplate }

import from pydantic { BaseModel }

glob logger: any;

glob T: any;

glob _RETRYABLE_HTTP_CLIENT_STATUS_CODES: any;

glob _BLOCKED: any;

glob _TRUNCATED: any;

with entry {
    logger = logging.getLogger("mobilerun");

    T = TypeVar("T", bound=BaseModel);

    _RETRYABLE_HTTP_CLIENT_STATUS_CODES = {408, 409, 425, 429};

    _BLOCKED = {
        "safety",
        "recitation",
        "blocklist",
        "prohibited_content",
        "content_filter",
        "refusal",
    };
    _TRUNCATED = {"max_tokens", "length", "max_output_tokens"};
}

def _as_dict(value: builtins.object) -> builtins.dict;

def _first_choice(mapping: builtins.dict, key: builtins.str) -> builtins.dict;

"""Redacted metadata (types, key names, scalars) for an unusable response. Never content."""
def _empty_response_diagnostics(
    response: builtins.object, llm: builtins.object, *, stream: builtins.bool = False
) -> builtins.dict[builtins.str, builtins.object];

def _log_empty_response(
    response: builtins.object,
    llm: builtins.object,
    attempt: builtins.int,
    *,
    stream: builtins.bool = False,
) -> None;

"""Return whether an HTTP client error should fail without another attempt."""
def _is_permanent_http_client_error(error: any) -> builtins.bool;

"""Log a stream's deltas as they arrive; return the text and the last chunk."""
async def _collect_stream(await_stream) -> builtins.tuple;

"""
    Call LLM with retries and timeout handling.

    Args:
        llm: The LLM client instance
        messages: List of messages to send
        retries: Number of retry attempts
        timeout: Timeout in seconds for each attempt
        delay: Base delay between retries (multiplied by attempt number)
        stream: If True, stream response chunks to console in real-time
        chat_kwargs: Extra request arguments, such as native tool definitions

    Returns:
        The LLM ChatResponse object
    """
async def acall_with_retries(
    llm,
    messages: builtins.list,
    retries: builtins.int = 3,
    timeout: builtins.float = 500,
    delay: builtins.float = 1.0,
    stream: builtins.bool = False,
    **chat_kwargs,
) -> ChatResponse;

"""
    Stream LLM response chunks to console and return accumulated response.

    Args:
        llm: The LLM client instance
        messages: List of messages to send
        timeout: Timeout in seconds for the entire stream

    Returns:
        ChatResponse with accumulated content
    """
async def _stream_response(
    llm, messages: builtins.list, timeout: builtins.float, **chat_kwargs
) -> ChatResponse;

"""
    Call LLM completion with retries and timeout handling.

    Args:
        llm: The LLM client instance
        prompt: The prompt string to send
        retries: Number of retry attempts
        timeout: Timeout in seconds for each attempt
        delay: Base delay between retries (multiplied by attempt number)
        stream: If True, stream response chunks to console in real-time

    Returns:
        The LLM CompletionResponse object
    """
async def acomplete_with_retries(
    llm,
    prompt: builtins.str,
    retries: builtins.int = 3,
    timeout: builtins.float = 500,
    delay: builtins.float = 1.0,
    stream: builtins.bool = False,
) -> CompletionResponse;

"""
    Stream LLM completion response chunks to console and return accumulated response.

    Args:
        llm: The LLM client instance
        prompt: The prompt string to send
        timeout: Timeout in seconds for the entire stream

    Returns:
        CompletionResponse with accumulated content
    """
async def _stream_complete_response(
    llm, prompt: builtins.str, timeout: builtins.float
) -> CompletionResponse;

"""
    Call LLM structured predict with retries and timeout handling.

    Args:
        llm: The LLM client instance
        output_cls: The Pydantic model class for structured output
        prompt: PromptTemplate with {variables}
        retries: Number of retry attempts
        timeout: Timeout in seconds for each attempt
        delay: Base delay between retries (multiplied by attempt number)
        **prompt_args: Values for template variables

    Returns:
        Instance of the output_cls Pydantic model
    """
async def astructured_predict_with_retries(
    llm,
    output_cls: Type[T],
    prompt: PromptTemplate,
    retries: builtins.int = 3,
    timeout: builtins.float = 500,
    delay: builtins.float = 1.0,
    **prompt_args,
) -> T;
