import builtins;

import contextlib;

import logging;

import from typing { Any, Dict, List, Optional }

import from uuid { uuid4 }

import from llama_index.core.callbacks.base_handler { BaseCallbackHandler }

import from llama_index.core.callbacks.schema { CBEventType, EventPayload }

import from llama_index.core.llms { LLM, ChatResponse }

import from pydantic { BaseModel }

glob logger: any;

glob SUPPORTED_PROVIDERS: any;

glob PROVIDER_ALIASES: any;

with entry {
    logger = logging.getLogger("mobilerun");
    SUPPORTED_PROVIDERS = [
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

    PROVIDER_ALIASES = {
        "MobilerunAnthropic": "Anthropic",
        "MobilerunDeepSeek": "OpenAILike",
        "MobilerunGoogleGenAI": "GoogleGenAI",
        "MobilerunOpenAIResponses": "OpenAIResponses",
        "openai_responses_llm": "OpenAIResponses",
        "GrokOAuth": "OpenAIResponses",
        "xai_oauth": "OpenAIResponses",
        "Ollama_llm": "Ollama",
    };
}

class UsageResult(BaseModel) {
    has request_tokens: builtins.int;

    has response_tokens: builtins.int;

    has total_tokens: builtins.int;

    has requests: builtins.int;
}

def _usage_field(usage: Any, *names_: builtins.str) -> builtins.int;

"""Read a response field from either an SDK object or decoded JSON."""
def _response_field(response: Any, name: builtins.str) -> Any;

def _detail_field(usage: Any, container: builtins.str, *names__: builtins.str) -> builtins.int;

"""Reasoning tokens counted in the total but left out of the output count."""
def _excluded_reasoning_tokens(
    request_tokens: builtins.int,
    response_tokens: builtins.int,
    reasoning_tokens: builtins.int,
    total: builtins.int,
) -> builtins.int;

def _gemini_usage(usage: Any) -> UsageResult;

def _normalize_provider_name(provider: builtins.str) -> builtins.str;

def get_usage_from_response(provider: builtins.str, chat_rsp: ChatResponse) -> UsageResult;

"""Token counting handler for LLamaIndex LLM calls."""
class TokenCountingHandler(BaseCallbackHandler) {
    def init(provider: builtins.str);

    """Class name."""
    class def class_name -> builtins.str;

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

    def _get_event_usage(payload: Dict[builtins.str, Any]) -> UsageResult;

    """Run when an event starts and return id of event."""
    def on_event_start(
        event_type: CBEventType,
        payload: Optional[Dict[builtins.str, Any]] = None,
        event_id: builtins.str = "",
        parent_id: builtins.str = "",
        **kwargs: Any,
    ) -> builtins.str;

    """Run when an event ends."""
    def on_event_end(
        event_type: CBEventType,
        payload: Optional[Dict[builtins.str, Any]] = None,
        event_id: builtins.str = "",
        **kwargs: Any,
    ) -> None;

    """Run when an overall trace is launched."""
    def start_trace(trace_id: Optional[builtins.str] = None) -> None;

    """Run when an overall trace is exited."""
    def end_trace(
        trace_id: Optional[builtins.str] = None,
        trace_map: Optional[Dict[builtins.str, List[builtins.str]]] = None,
    ) -> None;
}

@contextlib.contextmanager
def llm_callback(llm: LLM, *args_: List[BaseCallbackHandler]) -> Generator[any, any, any];

def create_tracker(llm: LLM) -> TokenCountingHandler;

"""Track token usage for an LLM instance across all requests.

    This function:
    - Creates a new TokenCountingHandler for the LLM provider
    - Registers that handler as an LLM callback to monitor all requests
    - Returns the handler for accessing cumulative usage statistics

    The handler counts tokens for total LLM usage across all requests. For fine-grained
    per-request counting, use either:
    - `create_tracker()` with `llm_callback()` context manager for temporary tracking
    - `get_usage_from_response()` to extract usage from individual responses

    Args:
        llm: The LLamaIndex LLM instance to track usage for

    Returns:
        TokenCountingHandler: The registered handler that accumulates usage statistics

    Raises:
        ValueError: If the LLM provider is not supported for tracking

    Example:
        >>> llm = OpenAI()
        >>> tracker = track_usage(llm)
        >>> # ... make LLM calls ...
        >>> print(f"Total tokens used: {tracker.usage.total_tokens}")
    """
def track_usage(llm: LLM) -> TokenCountingHandler;
