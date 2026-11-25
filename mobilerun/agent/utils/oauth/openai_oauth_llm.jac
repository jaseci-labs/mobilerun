"""Standalone OpenAI OAuth subclass for LlamaIndex.

Usage:
    from openai_oauth_llm import OpenAIOAuth

    llm = OpenAIOAuth(
        auth_model="openai-codex/gpt-6-astra",
        custom_model="gpt-6.1-sol",  # optional override
        oauth_refresh_token="rt_...",
        oauth_access_token="eyJ...",  # optional if cached file already exists
        oauth_credential_path=str(OPENAI_OAUTH_CREDENTIAL_PATH),
    )
"""

import builtins;

import operator;

import from jaclang.comptime { target as target_ }

import base64;

import hashlib;

import inspect;

import json;

import os;

import secrets;

import sys;

import threading;

import time;

import webbrowser;

import from dataclasses { dataclass }

import from http.server { BaseHTTPRequestHandler }

import from http.server { ThreadingHTTPServer as HTTPServer }

import from pathlib { Path }

import from typing { Any, ClassVar, Dict, Literal, Optional }

import from urllib.parse { parse_qs, urlencode, urlparse }

import httpx;

import from llama_index.core.base.llms.types {
    ChatMessage,
    ChatResponse,
    ChatResponseAsyncGen,
    ChatResponseGen,
    LLMMetadata,
    MessageRole,
    TextBlock,
    ToolCallBlock,
}

import from llama_index.core.types { PydanticProgramMode }

import from llama_index.llms.openai { OpenAI }

import from llama_index.llms.openai.base { llm_retry_decorator }

import from llama_index.llms.openai.utils { to_openai_message_dicts }

glob DEFAULT_OPENAI_OAUTH_ISSUER: any = "https://auth.openai.com";

glob DEFAULT_OPENAI_OAUTH_CLIENT_ID: any = "app_EMoamEEZ73f0CkXaXp7hrann";

glob DEFAULT_OPENAI_OAUTH_CREDENTIAL_PATH: any;

glob DEFAULT_AUTH_MODEL: any;

glob DEFAULT_OPENAI_API_BASE: any;

glob DEFAULT_CODEX_API_BASE: any;

glob DEFAULT_BACKEND_API_BASE: any;

glob DEFAULT_OPENAI_OAUTH_CALLBACK_HOST: any;

glob DEFAULT_OPENAI_OAUTH_CALLBACK_PORT: any;

glob DEFAULT_OPENAI_OAUTH_CALLBACK_PATH: any;

glob DEFAULT_OPENAI_OAUTH_SCOPE: any;

glob _OPENAI_LOGIN_TIMEOUT_MESSAGE: any;

glob _GPT_6_ASTRA_MODEL: any;

glob _GPT_6_UNSUPPORTED_PARAMS: any;

glob _GPT_6_UNSUPPORTED_INCLUDE: any;

glob _CODEX_CONTEXT_WINDOW: any;

glob _DEVICE_CODE_TIMEOUT: any;

with entry {
    DEFAULT_OPENAI_OAUTH_CREDENTIAL_PATH = OPENAI_OAUTH_CREDENTIAL_PATH;
    DEFAULT_AUTH_MODEL = f"openai-codex/{OPENAI_OAUTH_DEFAULT_MODEL}";
    DEFAULT_OPENAI_API_BASE = "https://api.openai.com/v1";
    DEFAULT_CODEX_API_BASE = "https://chatgpt.com/backend-api/codex";
    DEFAULT_BACKEND_API_BASE = "https://chatgpt.com/backend-api";
    DEFAULT_OPENAI_OAUTH_CALLBACK_HOST = "localhost";
    DEFAULT_OPENAI_OAUTH_CALLBACK_PORT = 1455;
    DEFAULT_OPENAI_OAUTH_CALLBACK_PATH = "/auth/callback";
    DEFAULT_OPENAI_OAUTH_SCOPE = "openid profile email offline_access api.connectors.read api.connectors.invoke";
    _OPENAI_LOGIN_TIMEOUT_MESSAGE = "OpenAI OAuth login timed out.";
    _GPT_6_ASTRA_MODEL = "gpt-6-astra";
    _GPT_6_UNSUPPORTED_PARAMS = frozenset({"temperature", "top_p", "logprobs", "top_logprobs"});
    _GPT_6_UNSUPPORTED_INCLUDE = "message.output_text.logprobs";
    _CODEX_CONTEXT_WINDOW = 272000;
}

async def _aclose_events(events: Any) -> None;

def _b64_no_pad(raw: bytes) -> str;

def _pkce_pair -> tuple[str, str];

"""Detect SSH, WSL, or missing display where browser popups won't work."""
def _is_headless_environment -> bool;

"""Probe the OAuth issuer to detect TLS/certificate issues before login.

    Raises RuntimeError on TLS certificate errors (with fix suggestions).
    Prints warnings for non-TLS connection errors but does not block.
    """
def _tls_preflight(
    issuer: str, timeout: float = 5.0, *, deadline: OAuthLoginDeadline | None = None
) -> None;

with entry {
    _DEVICE_CODE_TIMEOUT = 15 * 60;
}

def _request_device_code(
    issuer: str,
    client_id: str,
    http_client: Optional[httpx.Client] = None,
    request_timeout: float = 15.0,
    retries: int = 2,
    *,
    deadline: OAuthLoginDeadline | None = None,
) -> dict[str, any];

glob timeout_seconds_default_: any;

with entry {
    timeout_seconds_default_ = _DEVICE_CODE_TIMEOUT;
}

def _poll_device_code(
    issuer: str,
    device_auth_id: str,
    user_code: str,
    interval: int,
    http_client: Optional[httpx.Client] = None,
    request_timeout: float = 15.0,
    timeout_seconds: float = timeout_seconds_default_,
    *,
    deadline: OAuthLoginDeadline | None = None,
) -> dict[str, any];

@dataclass
class OpenAIOAuthCredentials {
    has access_token: str;

    has refresh_token: Optional[str] = None;

    has expires_at_ms: Optional[int] = None;

    has account_id: Optional[str] = None;

    class def from_payload(payload: Dict[str, Any]) -> "OpenAIOAuthCredentials";

    def to_dict -> Dict[str, Any];

    def is_valid(skew_ms: int = 60000) -> bool;
}

glob path_default_: any;

with entry {
    path_default_ = DEFAULT_OPENAI_OAUTH_CREDENTIAL_PATH;
}

obj OpenAIOAuthCredentialStore {
    has path: any,
        _store: any;

    def init(path: str | Path = path_default_);

    static has _NESTED_KEY: any = "openaiOauth";

    def load -> Optional[OpenAIOAuthCredentials];

    def save(
        credentials: OpenAIOAuthCredentials, *, deadline: OAuthLoginDeadline | None = None
    ) -> None;

    def __repr__ -> str;

    def __eq__(other: any) -> bool;

    def __hash__ -> int;
}

glob issuer_default_: any;

glob client_id_default_: any;

with entry {
    issuer_default_ = DEFAULT_OPENAI_OAUTH_ISSUER;
    client_id_default_ = DEFAULT_OPENAI_OAUTH_CLIENT_ID;
}

obj OpenAIOAuthSessionManager {
    has issuer: any,
        client_id: any,
        request_timeout: any,
        credential_store: any,
        http_client: any,
        _lock: any,
        _credentials: any;

    def init(
        *,
        issuer: str = issuer_default_,
        client_id: str = client_id_default_,
        credential_store: Optional[OpenAIOAuthCredentialStore] = None,
        request_timeout: float = 15.0,
        http_client: Optional[httpx.Client] = None,
    );

    static def _jwt_claims(token: str) -> Dict[str, Any];

    class def _extract_account_id(token: str) -> Optional[str];

    class def _compute_expiry_ms(token: str, expires_in: Optional[Any]) -> Optional[int];

    def set_initial_credentials(
        credentials: OpenAIOAuthCredentials, *, deadline: OAuthLoginDeadline | None = None
    ) -> None;

    def _load_cached_credentials -> Optional[OpenAIOAuthCredentials];

    def _refresh(refresh_token: str) -> OpenAIOAuthCredentials;

    def get_valid_credentials(skew_ms: int = 60000) -> OpenAIOAuthCredentials;

    def exchange_authorization_code(
        *,
        code: str,
        redirect_uri: str,
        code_verifier: str,
        deadline: OAuthLoginDeadline | None = None,
    ) -> OpenAIOAuthCredentials;

    def __repr__ -> str;

    def __eq__(other: any) -> bool;

    def __hash__ -> int;
}

glob scope_default_: any;

glob auth_model_default_: any;

glob oauth_client_id_default_: any;

glob oauth_issuer_default_: any;

glob callback_host_default_: any;

glob callback_port_default_: any;

glob callback_path_default_: any;

glob redirect_host_default_: any;

glob scope_default__: any;

glob timeout_seconds_default__: any;

with entry {
    scope_default_ = DEFAULT_OPENAI_OAUTH_SCOPE;
    auth_model_default_ = DEFAULT_AUTH_MODEL;
    oauth_client_id_default_ = DEFAULT_OPENAI_OAUTH_CLIENT_ID;
    oauth_issuer_default_ = DEFAULT_OPENAI_OAUTH_ISSUER;
    callback_host_default_ = DEFAULT_OPENAI_OAUTH_CALLBACK_HOST;
    callback_port_default_ = DEFAULT_OPENAI_OAUTH_CALLBACK_PORT;
    callback_path_default_ = DEFAULT_OPENAI_OAUTH_CALLBACK_PATH;
    redirect_host_default_ = DEFAULT_OPENAI_OAUTH_CALLBACK_HOST;
    scope_default__ = DEFAULT_OPENAI_OAUTH_SCOPE;
    timeout_seconds_default__ = _DEVICE_CODE_TIMEOUT;
}

"""OpenAI LLM backed by ChatGPT OAuth refresh/access tokens."""
class OpenAIOAuth(OpenAI) {
    has supports_native_tool_calls: ClassVar[bool] = True;

    has reasoning_effort: Optional[Literal["none", "minimal", "low", "medium", "high", "xhigh", "max"]] = None;

    class def class_name -> str;

    has metadata: LLMMetadata {
        getter {
            return LLMMetadata(
                context_window=_CODEX_CONTEXT_WINDOW,
                num_output=self.max_tokens or -1,
                is_chat_model=True,
                is_function_calling_model=True,
                model_name=self.model,
                system_role=MessageRole.SYSTEM,
            );
        }
    }

    static def _resolve_model_name(
        *, auth_model: str, custom_model: Optional[str], model: Optional[str]
    ) -> str;

    static def _build_auth_url(
        *,
        issuer: str,
        client_id: str,
        redirect_uri: str,
        code_challenge: str,
        state: str,
        scope: str = scope_default_,
    ) -> str;

    def init(
        auth_model: str = auth_model_default_,
        custom_model: Optional[str] = None,
        model: Optional[str] = None,
        oauth_refresh_token: Optional[str] = None,
        oauth_access_token: Optional[str] = None,
        oauth_expires_at_ms: Optional[int] = None,
        oauth_account_id: Optional[str] = None,
        oauth_credential_path: Optional[str] = None,
        oauth_client_id: str = oauth_client_id_default_,
        oauth_issuer: str = oauth_issuer_default_,
        oauth_refresh_skew_seconds: int = 60,
        use_chatgpt_account_header: bool = False,
        **kwargs: Any,
    );

    def login(
        *,
        open_browser: bool = True,
        timeout_seconds: float = 300.0,
        callback_host: str = callback_host_default_,
        callback_port: int = callback_port_default_,
        callback_path: str = callback_path_default_,
        redirect_host: str = redirect_host_default_,
        scope: str = scope_default__,
        deadline: OAuthLoginDeadline | None = None,
    ) -> OpenAIOAuthCredentials;

    """Device Code login for headless/SSH environments.

        timeout_seconds is capped at 15 min (device code expiry).
        """
    def _login_device_code(
        *,
        open_browser: bool = False,
        timeout_seconds: float = timeout_seconds_default__,
        deadline: OAuthLoginDeadline | None = None,
    ) -> OpenAIOAuthCredentials;

    def _ensure_access_token -> OpenAIOAuthCredentials;

    def _get_client -> any;

    def _get_aclient -> any;

    def _get_credential_kwargs(is_async: bool = False) -> Dict[str, Any];

    def _resolve_codex_instructions(messages: list[ChatMessage]) -> str;

    def _build_responses_payload(messages: list[ChatMessage]) -> list[dict[str, Any]];

    def _sanitize_reasoning_kwargs(runtime_kwargs: dict[str, Any]) -> dict[str, Any];

    def _collect_stream_text_sync(events: Any) -> tuple[str, Any, list[ToolCallBlock]];

    async def _collect_stream_text_async(events: Any) -> tuple[str, Any, list[ToolCallBlock]];

    static def _is_not_found_error(exc: Exception) -> bool;

    def _codex_request_kwargs(
        messages: list[ChatMessage], kwargs: dict[str, Any]
    ) -> dict[str, Any];

    static def _function_call_blocks(items: Any) -> list[ToolCallBlock];

    class def _response_message(
        text: str, response: Any, tool_calls: list[ToolCallBlock]
    ) -> ChatMessage;

    class def _done_function_calls(event: Any) -> list[ToolCallBlock];

    def _should_fall_back_to_backend_api(exc: Exception) -> bool;

    def _use_backend_api_base -> None;

    static def _stream_chunk(text: str, delta: str, raw: Any = None) -> ChatResponse;

    class def _stream_event_chunk(event: Any, text: str) -> ChatResponse | None;

    @llm_retry_decorator
    def _chat(messages: list[ChatMessage], **kwargs: Any) -> ChatResponse;

    @llm_retry_decorator
    async def _achat(messages: list[ChatMessage], **kwargs: Any) -> ChatResponse;
    @llm_retry_decorator
    def _stream_chat(messages: list[ChatMessage], **kwargs: Any) -> ChatResponseGen;

    @llm_retry_decorator
    async def _astream_chat(messages: list[ChatMessage], **kwargs: Any) -> ChatResponseAsyncGen;

    async def _astream_chunks(events: Any) -> AsyncIterator[any];
}
