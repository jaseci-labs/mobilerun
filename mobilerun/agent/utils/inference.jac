import builtins;

import operator;

import asyncio;

import logging;

import from typing { Type, TypeVar }

import from llama_index.core.base.llms.types {
    ChatMessage,
    ChatResponse,
    CompletionResponse,
    ToolCallBlock,
}

import from llama_index.core.prompts { PromptTemplate }

import from pydantic { BaseModel }

glob logger: any = logging.getLogger("mobilerun");

glob T: any = TypeVar("T", bound=BaseModel);

glob _RETRYABLE_HTTP_CLIENT_STATUS_CODES: any = {408, 409, 425, 429};

glob _BLOCKED: any = {
    "safety",
    "recitation",
    "blocklist",
    "prohibited_content",
    "content_filter",
    "refusal",
};

glob _TRUNCATED: any = {"max_tokens", "length", "max_output_tokens"};

def _as_dict(value: builtins.object) -> builtins.dict;

def _first_choice(mapping: builtins.dict, key: builtins.str) -> builtins.dict;

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

def _is_permanent_http_client_error(error: any) -> builtins.bool;

async def _collect_stream(await_stream) -> builtins.tuple;

async def acall_with_retries(
    llm,
    messages: builtins.list,
    retries: builtins.int = 3,
    timeout: builtins.float = 500,
    delay: builtins.float = 1.0,
    stream: builtins.bool = False,
    **chat_kwargs,
) -> ChatResponse;

async def _stream_response(
    llm, messages: builtins.list, timeout: builtins.float, **chat_kwargs
) -> ChatResponse;

async def acomplete_with_retries(
    llm,
    prompt: builtins.str,
    retries: builtins.int = 3,
    timeout: builtins.float = 500,
    delay: builtins.float = 1.0,
    stream: builtins.bool = False,
) -> CompletionResponse;

async def _stream_complete_response(
    llm, prompt: builtins.str, timeout: builtins.float
) -> CompletionResponse;

async def astructured_predict_with_retries(
    llm,
    output_cls: Type[T],
    prompt: PromptTemplate,
    retries: builtins.int = 3,
    timeout: builtins.float = 500,
    delay: builtins.float = 1.0,
    **prompt_args,
) -> T;
