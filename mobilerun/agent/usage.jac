import builtins;

import contextlib;

import logging;

import from typing { Any, Dict, List, Optional }

import from uuid { uuid4 }

import from llama_index.core.callbacks.base_handler { BaseCallbackHandler }

import from llama_index.core.callbacks.schema { CBEventType, EventPayload }

import from llama_index.core.llms { LLM, ChatResponse }

import from pydantic { BaseModel }

glob logger: any = logging.getLogger("mobilerun");

glob SUPPORTED_PROVIDERS: any = [
    "Gemini",
    "GoogleGenAI",
    "GenAI",
    "GeminiOAuthCodeAssistLLM",
    "gemini_oauth_code_assist",
    "OpenAIResponses",
    "OpenAILike",
    "OpenAIOAuth",
    "Anthropic",
    "Anthropic_LLM",
    "AnthropicOAuthLLM",
    "Ollama",
];

glob PROVIDER_ALIASES: any = {
    "MobilerunAnthropic": "Anthropic",
    "MobilerunDeepSeek": "OpenAILike",
    "MobilerunGoogleGenAI": "GoogleGenAI",
    "MobilerunOpenAIResponses": "OpenAIResponses",
    "openai_responses_llm": "OpenAIResponses",
    "GrokOAuth": "OpenAIResponses",
    "xai_oauth": "OpenAIResponses",
    "Ollama_llm": "Ollama",
};

class UsageResult(BaseModel) {
    has request_tokens: builtins.int;

    has response_tokens: builtins.int;

    has total_tokens: builtins.int;

    has requests: builtins.int;
}

def _usage_field(usage: Any, *names_: builtins.str) -> builtins.int {
    names: any = tuple(names_);
    for name in names {
        if isinstance(usage, `dict) and name in usage {
            value: any = usage[name];
        } else {
            value = getattr(usage, name, None);
        }

        if value is None {
            continue;
        }

        try {
            return `int(value);
        } except (TypeError, ValueError) {
            continue;
        }
    }

    return 0;
}

def _response_field(response: Any, name: builtins.str) -> Any {
    if isinstance(response, `dict) {
        return response.get(name);
    }
    return getattr(response, name, None);
}

def _detail_field(usage: Any, container: builtins.str, *names__: builtins.str) -> builtins.int {
    names: any = tuple(names__);
    details: any = _response_field(usage, container);
    return 0 if details is None else _usage_field(details, *names);
}

def _excluded_reasoning_tokens(
    request_tokens: builtins.int,
    response_tokens: builtins.int,
    reasoning_tokens: builtins.int,
    total: builtins.int,
) -> builtins.int {
    if reasoning_tokens and total == request_tokens + response_tokens + reasoning_tokens {
        return reasoning_tokens;
    }
    return 0;
}

def _gemini_usage(usage: Any) -> UsageResult {
    request_tokens: any = _usage_field(usage, "promptTokenCount", "prompt_token_count");
    response_tokens: any = _usage_field(usage, "candidatesTokenCount", "candidates_token_count")
        + _usage_field(usage, "thoughtsTokenCount", "thoughts_token_count");
    total_tokens: any = _usage_field(usage, "totalTokenCount", "total_token_count");
    return UsageResult(
        request_tokens=request_tokens,
        response_tokens=response_tokens,
        total_tokens=total_tokens or request_tokens + response_tokens,
        requests=1,
    );
}

def _normalize_provider_name(provider: builtins.str) -> builtins.str {
    return PROVIDER_ALIASES.get(provider, provider);
}

def get_usage_from_response(provider: builtins.str, chat_rsp: ChatResponse) -> UsageResult {
    provider = _normalize_provider_name(provider);
    rsp: any = chat_rsp.raw;
    if not rsp and provider not in ("OpenAIResponses", "OpenAIOAuth") {
        raise ValueError("No raw response in chat response");
    }

    if provider in {
        "Gemini",
        "GoogleGenAI",
        "GenAI",
        "GeminiOAuthCodeAssistLLM",
        "gemini_oauth_code_assist",
    }
    {
        usage: any = rsp.get("response", {}).get("usageMetadata", {})
            if provider in ("GeminiOAuthCodeAssistLLM", "gemini_oauth_code_assist")
            else rsp["usage_metadata"];
        return _gemini_usage(usage);
    } elif provider == "OpenAILike" {
        import from openai.types { CompletionUsage as OpenAIUsage }

        usage = rsp.usage;
        reasoning_tokens: any = _detail_field(
            usage, "completion_tokens_details", "reasoning_tokens"
        );
        return UsageResult(
            request_tokens=usage.prompt_tokens,
            response_tokens=usage.completion_tokens
                + _excluded_reasoning_tokens(
                    usage.prompt_tokens,
                    usage.completion_tokens,
                    reasoning_tokens,
                    usage.total_tokens,
                ),
            total_tokens=usage.total_tokens,
            requests=1,
        );
    } elif provider in ("OpenAIResponses", "OpenAIOAuth") {
        usage = _response_field(rsp, "usage");
        if usage is None {
            usage = _response_field(_response_field(rsp, "response"), "usage");
        }
        if usage is None {
            usage = _response_field(chat_rsp.additional_kwargs, "usage");
        }
        if usage is None {
            return UsageResult(request_tokens=0, response_tokens=0, total_tokens=0, requests=1);
        }
        input_tokens: any = _usage_field(usage, "input_tokens");
        output_tokens: any = _usage_field(usage, "output_tokens");
        total_tokens: any = _usage_field(usage, "total_tokens");
        reasoning_tokens = _detail_field(usage, "output_tokens_details", "reasoning_tokens");
        return UsageResult(
            request_tokens=input_tokens,
            response_tokens=output_tokens
                + _excluded_reasoning_tokens(
                    input_tokens, output_tokens, reasoning_tokens, total_tokens
                ),
            total_tokens=total_tokens,
            requests=1,
        );
    } elif provider in {"Anthropic", "Anthropic_LLM", "AnthropicOAuthLLM"} {
        usage = rsp["usage"];
        input_tokens = _usage_field(usage, "input_tokens");
        output_tokens = _usage_field(usage, "output_tokens");
        return UsageResult(
            request_tokens=input_tokens,
            response_tokens=output_tokens,
            total_tokens=input_tokens + output_tokens,
            requests=1,
        );
    } elif provider == "Ollama" {
        prompt_eval_count: any = rsp.get("prompt_eval_count", 0);
        eval_count: any = rsp.get("eval_count", 0);
        return UsageResult(
            request_tokens=prompt_eval_count,
            response_tokens=eval_count,
            total_tokens=prompt_eval_count + eval_count,
            requests=1,
        );
    }
    raise ValueError(f"Unsupported provider: {provider}");
}

"""Token counting handler for LLamaIndex LLM calls."""
class TokenCountingHandler(BaseCallbackHandler) {
    def init(provider: builtins.str) {
        super.__init__(event_starts_to_ignore=[], event_ends_to_ignore=[]);
        self.provider = provider;
        self.request_tokens = 0;
        self.response_tokens = 0;
        self.total_tokens = 0;
        self.requests = 0;
    }

    class def class_name -> builtins.str {
        return "TokenCountingHandler";
    }

    has usage: UsageResult {
        getter {
            return UsageResult(
                request_tokens=self.request_tokens,
                response_tokens=self.response_tokens,
                total_tokens=self.total_tokens,
                requests=self.requests,
            );
        }
    }

    def _get_event_usage(payload: Dict[builtins.str, Any]) -> UsageResult {
        if EventPayload.RESPONSE not in payload {
            raise ValueError("No response in payload");
        }

        chat_rsp: ChatResponse = payload.get(EventPayload.RESPONSE);
        return get_usage_from_response(self.provider, chat_rsp);
    }

    def on_event_start(
        event_type: CBEventType,
        payload: Optional[Dict[builtins.str, Any]] = None,
        event_id: builtins.str = "",
        parent_id: builtins.str = "",
        **kwargs: Any,
    ) -> builtins.str {
        return event_id or `str(uuid4());
    }

    def on_event_end(
        event_type: CBEventType,
        payload: Optional[Dict[builtins.str, Any]] = None,
        event_id: builtins.str = "",
        **kwargs: Any,
    ) -> None {
        try {
            usage: any = self._get_event_usage(payload);

            self.request_tokens += usage.request_tokens;
            self.response_tokens += usage.response_tokens;
            self.total_tokens += usage.total_tokens;
            self.requests += usage.requests;
        } except Exception as e {
            self.requests += 1;
            logger.warning(
                f"Error tracking usage for provider {self.provider}: {e}",
                extra={"provider": self.provider},
            );
        }
    }

    def start_trace(trace_id: Optional[builtins.str] = None) -> None {}

    def end_trace(
        trace_id: Optional[builtins.str] = None,
        trace_map: Optional[Dict[builtins.str, List[builtins.str]]] = None,
    ) -> None {}
}

@contextlib.contextmanager
def llm_callback(llm: LLM, *args_: List[BaseCallbackHandler]) -> Generator[any, any, any] {
    args: any = tuple(args_);
    for arg in args {
        llm.callback_manager.add_handler(arg);
    }
    yield;
    for arg in args {
        llm.callback_manager.remove_handler(arg);
    }
}

def create_tracker(llm: LLM) -> TokenCountingHandler {
    provider: any = _normalize_provider_name(llm.__class__.__name__);
    if provider not in SUPPORTED_PROVIDERS {
        raise ValueError(f"Tracking not yet supported for provider: {provider}");
    }

    return TokenCountingHandler(provider);
}

def track_usage(llm: LLM) -> TokenCountingHandler {
    provider: any = _normalize_provider_name(llm.__class__.__name__);
    if provider not in SUPPORTED_PROVIDERS {
        raise ValueError(f"Tracking not yet supported for provider: {provider}");
    }

    tracker: any = TokenCountingHandler(provider);
    llm.callback_manager.add_handler(tracker);
    return tracker;
}
