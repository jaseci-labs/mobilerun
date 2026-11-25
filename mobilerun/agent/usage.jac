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

def _response_field(response: Any, name: builtins.str) -> Any;

def _detail_field(usage: Any, container: builtins.str, *names__: builtins.str) -> builtins.int;

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

    def on_event_start(
        event_type: CBEventType,
        payload: Optional[Dict[builtins.str, Any]] = None,
        event_id: builtins.str = "",
        parent_id: builtins.str = "",
        **kwargs: Any,
    ) -> builtins.str;

    def on_event_end(
        event_type: CBEventType,
        payload: Optional[Dict[builtins.str, Any]] = None,
        event_id: builtins.str = "",
        **kwargs: Any,
    ) -> None;

    def start_trace(trace_id: Optional[builtins.str] = None) -> None;

    def end_trace(
        trace_id: Optional[builtins.str] = None,
        trace_map: Optional[Dict[builtins.str, List[builtins.str]]] = None,
    ) -> None;
}

@contextlib.contextmanager
def llm_callback(llm: LLM, *args_: List[BaseCallbackHandler]) -> Generator[any, any, any];

def create_tracker(llm: LLM) -> TokenCountingHandler;

def track_usage(llm: LLM) -> TokenCountingHandler;
