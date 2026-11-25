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

def _as_dict(value: builtins.object) -> builtins.dict {
    if isinstance(value, `dict) {
        return value;
    }
    dump: any = getattr(value, "model_dump", None);
    try {
        dumped: any = dump() if callable(dump) else None;
        return dumped if isinstance(dumped, `dict) else {};
    } except Exception {
        return {};
    }
}

def _first_choice(mapping: builtins.dict, key: builtins.str) -> builtins.dict {
    value: any = mapping.get(key);
    if isinstance(value, `list) and value {
        return _as_dict(value[0]);
    }
    return {};
}

def _empty_response_diagnostics(
    response: builtins.object, llm: builtins.object, *, stream: builtins.bool = False
) -> builtins.dict[builtins.str, builtins.object] {
    message: any = getattr(response, "message", None);
    raw: any = _as_dict(getattr(response, "raw", None));
    extra: any = _as_dict(getattr(response, "additional_kwargs", None));
    message_extra: any = _as_dict(getattr(message, "additional_kwargs", None));
    nested: any = _as_dict(raw.get("response"));
    sources = [
        raw,
        extra,
        message_extra,
        nested,
        _first_choice(raw, "choices"),
        _first_choice(raw, "candidates"),
        _first_choice(nested, "choices"),
        _first_choice(nested, "candidates"),
    ];

    types_default_: any = (str, int, float, bool);

    def scalar(*names_: builtins.str, types: any = types_default_) -> builtins.object | None {
        names: any = tuple(names_);
        for src in sources {
            for name in names {
                value: any = src.get(name);
                if isinstance(value, types)
                    and not (isinstance(value, `bool) and bool not in types)
                {
                    return value;
                }
            }
        }
        return None;
    }

    blocks: any = [`type(b).__name__ for b in getattr(message, "blocks", None) or []];
    content_blocks: any = message_extra.get("content_blocks");
    block_types: any = [
        b["type"]
        for b in (content_blocks if isinstance(content_blocks, `list) else [])
        if isinstance(b, `dict) and isinstance(b.get("type"), `str)
    ];
    tool_calls: any = `bool(
        getattr(message, "tool_calls", None)
            or extra.get("tool_calls")
            or message_extra.get("tool_calls")
            or "ToolCallBlock" in blocks
            or "tool_use" in block_types,
    );
    thinking: any = `bool(
        `any("think" in b.lower() for b in blocks)
            or message_extra.get("thinking")
            or "thinking" in block_types,
    );
    incomplete: any = _as_dict(raw.get("incomplete_details"))
        or _as_dict(nested.get("incomplete_details"));
    incomplete_reason: any = incomplete.get("reason");
    reason: any = `str(
        scalar("finish_reason", "finishReason", "stop_reason", "stopReason")
            or (incomplete_reason if isinstance(incomplete_reason, `str) else ""),
    ).lower();

    if response is None {
        category: any = "no_response";
    } elif message is None and not hasattr(response, "text") {
        category = "no_message";
    } elif reason in _BLOCKED {
        category = "provider_blocked";
    } elif reason in _TRUNCATED {
        category = "truncated";
    } elif tool_calls {
        category = "tool_calls_only";
    } elif thinking {
        category = "thinking_only";
    } elif `any(operator.ne(b, "TextBlock") for b in blocks) {
        category = "blocks_without_text";
    } else {
        category = "empty_stream" if stream else "empty_content";
    }

    return {
        "category": category,
        "stream": stream,
        "model": getattr(getattr(llm, "metadata", None), "model_name", None)
            or getattr(llm, "model", None),
        "response_type": `type(response).__name__ if response is not None else None,
        "finish_reason": reason or None,
        "block_types": blocks,
        "has_tool_calls": tool_calls,
        "provider_request_id": scalar("request_id", "requestId", "id"),
        "http_status": scalar("status_code", "statusCode", "status", types=(int,)),
        "raw_keys": sorted(map(str, raw)),
        "additional_kwargs_keys": sorted(map(str, extra)),
    };
}

def _log_empty_response(
    response: builtins.object,
    llm: builtins.object,
    attempt: builtins.int,
    *,
    stream: builtins.bool = False,
) -> None {
    try {
        logger.warning(
            "LLM response unusable: attempt=%s diagnostics=%s",
            attempt,
            _empty_response_diagnostics(response, llm, stream=stream),
        );
    } except Exception {
        logger.warning("LLM response unusable: diagnostics unavailable");
    }
}

def _is_permanent_http_client_error(error: any) -> builtins.bool {
    status_code: any = _http_status_code(error);
    return status_code is not None
        and (operator.le(400, status_code) and operator.lt(status_code, 500))
        and status_code not in _RETRYABLE_HTTP_CLIENT_STATUS_CODES;
}

async def _collect_stream(await_stream) -> builtins.tuple {
    content: any = "";
    last_chunk: any = None;
    async for chunk in await await_stream {
        delta: any = chunk.delta or "";
        if delta {
            logger.info(delta, extra={"stream": True});
        }
        content += delta;
        last_chunk = chunk;
    }
    logger.info("", extra={"stream_end": True});
    return (content, last_chunk);
}

async def acall_with_retries(
    llm,
    messages: builtins.list,
    retries: builtins.int = 3,
    timeout: builtins.float = 500,
    delay: builtins.float = 1.0,
    stream: builtins.bool = False,
    **chat_kwargs,
) -> ChatResponse {
    last_exception: any = None;

    for attempt in range(1, retries + 1) {
        try {
            if stream {
                response: any = await _stream_response(llm, messages, timeout, **chat_kwargs);
            } else {
                response = await asyncio.wait_for(
                    llm.achat(messages=messages, **chat_kwargs), timeout=timeout
                );
            }
            message: any = getattr(response, "message", None);
            if message is not None
                and (
                    getattr(message, "content", None)
                    or chat_kwargs.get("tools")
                        and `any(
                            isinstance(b, ToolCallBlock) for b in getattr(message, "blocks", [])
                        )
                )
            {
                if not stream and message.content {
                    logger.info(f"{message.content}");
                }
                return response;
            }
            _log_empty_response(response, llm, attempt, stream=stream);
            last_exception = ValueError("Empty response content");
        } except asyncio.TimeoutError {
            logger.warning(f"Attempt {attempt} timed out after {timeout} seconds");
            last_exception = TimeoutError("Timed out");
        } except Exception as e {
            logger.warning(
                f"Attempt {attempt} failed with error: {`type(e).__name__}: {describe_error(e)}"
            );
            if _is_permanent_http_client_error(e) {
                raise;
            }
            last_exception = e;
        }

        if attempt < retries {
            await asyncio.sleep(delay * attempt);
        }
    }

    if last_exception {
        raise last_exception;
    }
    raise ValueError("All attempts returned empty response content");
}

async def _stream_response(
    llm, messages: builtins.list, timeout: builtins.float, **chat_kwargs
) -> ChatResponse {
    (content, last_chunk) = await asyncio.wait_for(
        _collect_stream(await_stream=llm.astream_chat(messages=messages, **chat_kwargs)),
        timeout=timeout,
    ) as any;
    response: any = ChatResponse(
        message=last_chunk.message
            if last_chunk
            else ChatMessage(role="assistant", content=content),
        raw=last_chunk.raw if last_chunk else None,
        additional_kwargs=last_chunk.additional_kwargs if last_chunk else {},
    );

    return response;
}

async def acomplete_with_retries(
    llm,
    prompt: builtins.str,
    retries: builtins.int = 3,
    timeout: builtins.float = 500,
    delay: builtins.float = 1.0,
    stream: builtins.bool = False,
) -> CompletionResponse {
    last_exception: any = None;

    for attempt in range(1, retries + 1) {
        try {
            if stream {
                response: any = await _stream_complete_response(llm, prompt, timeout);
            } else {
                response = await asyncio.wait_for(llm.acomplete(prompt), timeout=timeout);
            }
            if response is not None and getattr(response, "text", None) {
                if not stream {
                    logger.info(f"{response.text}");
                }
                return response;
            }
            _log_empty_response(response, llm, attempt, stream=stream);
            last_exception = ValueError("Empty response content");
        } except asyncio.TimeoutError {
            logger.warning(f"Attempt {attempt} timed out after {timeout} seconds");
            last_exception = TimeoutError("Timed out");
        } except Exception as e {
            logger.warning(
                f"Attempt {attempt} failed with error: {`type(e).__name__}: {describe_error(e)}"
            );
            if _is_permanent_http_client_error(e) {
                raise;
            }
            last_exception = e;
        }

        if attempt < retries {
            await asyncio.sleep(delay * attempt);
        }
    }

    if last_exception {
        raise last_exception;
    }
    raise ValueError("All attempts returned empty response content");
}

async def _stream_complete_response(
    llm, prompt: builtins.str, timeout: builtins.float
) -> CompletionResponse {
    (content, last_chunk) = await asyncio.wait_for(
        _collect_stream(await_stream=llm.astream_complete(prompt)), timeout=timeout
    ) as any;
    response: any = CompletionResponse(
        text=content,
        raw=last_chunk.raw if last_chunk else None,
        additional_kwargs=last_chunk.additional_kwargs if last_chunk else {},
    );

    return response;
}

async def astructured_predict_with_retries(
    llm,
    output_cls: Type[T],
    prompt: PromptTemplate,
    retries: builtins.int = 3,
    timeout: builtins.float = 500,
    delay: builtins.float = 1.0,
    **prompt_args,
) -> T {
    last_exception: any = None;

    for attempt in range(1, retries + 1) {
        try {
            result: any = await asyncio.wait_for(
                llm.astructured_predict(output_cls, prompt, **prompt_args), timeout=timeout
            );
            if result is not None {
                logger.info(f"{result}");
                return result;
            }
            logger.warning(f"Attempt {attempt} returned None");
            _log_empty_response(None, llm, attempt);
            last_exception = ValueError("Empty response");
        } except asyncio.TimeoutError {
            logger.warning(f"Attempt {attempt} timed out after {timeout} seconds");
            last_exception = TimeoutError("Timed out");
        } except Exception as e {
            logger.warning(
                f"Attempt {attempt} failed with error: {`type(e).__name__}: {describe_error(e)}"
            );
            if _is_permanent_http_client_error(e) {
                raise;
            }
            last_exception = e;
        }

        if attempt < retries {
            await asyncio.sleep(delay * attempt);
        }
    }

    if last_exception {
        raise last_exception;
    }
    raise ValueError("All attempts returned empty response");
}
