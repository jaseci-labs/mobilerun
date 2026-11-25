import builtins;

import operator;

import asyncio;

import base64;

import hashlib;

import os;

import re;

import secrets;

import sys;

import threading;

import time;

import webbrowser;

import from dataclasses { dataclass }

import from http.server { BaseHTTPRequestHandler }

import from http.server { ThreadingHTTPServer as HTTPServer }

import from pathlib { Path }

import from typing { Any, Callable, ClassVar }

import from urllib.parse { parse_qs, urlencode, urlparse }

import httpx;

import jwt;

import from llama_index.core.base.llms.types { LLMMetadata }

import from llama_index.llms.openai.responses { OpenAIResponses }

import from llama_index.llms.openai.utils { to_openai_message_dicts }

glob DEFAULT_GROK_MODEL: any = GROK_OAUTH_DEFAULT_MODEL;

glob DEFAULT_GROK_CONTEXT_WINDOW: any = 500000;

glob DEFAULT_GROK_OAUTH_ISSUER: any = "https://auth.x.ai";

glob DEFAULT_GROK_OAUTH_AUTHORIZE_URL: any;

glob DEFAULT_GROK_OAUTH_DEVICE_URL: any;

glob DEFAULT_GROK_OAUTH_TOKEN_URL: any;

glob DEFAULT_GROK_OAUTH_JWKS_URL: any;

glob DEFAULT_GROK_OAUTH_CLIENT_ID: any;

glob DEFAULT_GROK_OAUTH_PROXY: any;

glob GROK_CLI_COMPAT_VERSION_HEADER: any;

glob GROK_CLI_COMPAT_VERSION: any;

glob DEFAULT_GROK_OAUTH_CREDENTIAL_PATH: any;

glob DEFAULT_GROK_OAUTH_SLOT: any;

glob DEFAULT_GROK_OAUTH_CALLBACK_HOST: any;

glob DEFAULT_GROK_OAUTH_CALLBACK_PORT: any;

glob DEFAULT_GROK_OAUTH_CALLBACK_PATH: any;

glob DEFAULT_GROK_OAUTH_SCOPES: any;

glob DEFAULT_REFRESH_SKEW_SECONDS: any;

glob DEFAULT_TOKEN_RETRY_BACKOFF_SECONDS: any;

glob _DEVICE_GRANT: any;

glob _DEVICE_SURFACE_HEADER: any;

glob _DEVICE_SURFACE: any;

glob _OAUTH_ERROR_CODE: any;

glob _TOKEN_ERROR_CODES: any;

glob GrokOAuthLLM: any;

with entry {
    DEFAULT_GROK_OAUTH_AUTHORIZE_URL = f"{DEFAULT_GROK_OAUTH_ISSUER}/oauth2/authorize";
    DEFAULT_GROK_OAUTH_DEVICE_URL = f"{DEFAULT_GROK_OAUTH_ISSUER}/oauth2/device/code";
    DEFAULT_GROK_OAUTH_TOKEN_URL = f"{DEFAULT_GROK_OAUTH_ISSUER}/oauth2/token";
    DEFAULT_GROK_OAUTH_JWKS_URL = f"{DEFAULT_GROK_OAUTH_ISSUER}/.well-known/jwks.json";
    DEFAULT_GROK_OAUTH_CLIENT_ID = "b1a00492-073a-47ea-816f-4c329264a828";
    DEFAULT_GROK_OAUTH_PROXY = "https://cli-chat-proxy.grok.com/v1";
    GROK_CLI_COMPAT_VERSION_HEADER = "x-grok-client-version";
    GROK_CLI_COMPAT_VERSION = "1.0.41";
    DEFAULT_GROK_OAUTH_CREDENTIAL_PATH = GROK_OAUTH_CREDENTIAL_PATH;
    DEFAULT_GROK_OAUTH_SLOT = "grokOauth";
    DEFAULT_GROK_OAUTH_CALLBACK_HOST = "127.0.0.1";
    DEFAULT_GROK_OAUTH_CALLBACK_PORT = 0;
    DEFAULT_GROK_OAUTH_CALLBACK_PATH = "/callback";
    DEFAULT_GROK_OAUTH_SCOPES = (
        "openid",
        "profile",
        "email",
        "offline_access",
        "grok-cli:access",
        "api:access",
        "conversations:read",
        "conversations:write",
        "workspaces:read",
        "workspaces:write",
    );
    DEFAULT_REFRESH_SKEW_SECONDS = 300;
    DEFAULT_TOKEN_RETRY_BACKOFF_SECONDS = (0.25, 0.5);
    _DEVICE_GRANT = "urn:ietf:params:oauth:grant-type:device_code";
    _DEVICE_SURFACE_HEADER = "x-grok-client-surface";
    _DEVICE_SURFACE = "grok-build";
    _OAUTH_ERROR_CODE = re.compile("^[A-Za-z0-9_.-]{1,64}$");
    _TOKEN_ERROR_CODES = frozenset({
        "access_denied",
        "authorization_pending",
        "expired_token",
        "invalid_client",
        "invalid_grant",
        "invalid_request",
        "invalid_scope",
        "slow_down",
        "unauthorized_client",
        "unsupported_grant_type",
    });
}

def _b64_no_pad(raw: bytes) -> str;

def _pkce_pair -> tuple[str, str];

def _is_headless_environment -> bool;

def _parse_callback_query(query: str) -> dict[str, str | None];

"""A safe OAuth failure that never includes a token response body."""
class GrokOAuthError(RuntimeError) {}

"""The refresh grant is permanently invalid and login must be repeated."""
class GrokOAuthReloginRequired(GrokOAuthError) {}

def _safe_error_code(value: object) -> str | None;

def _safe_token_error_code(value: object) -> str | None;

def _safe_json_object(response: httpx.Response, *, context: str) -> dict[str, Any];

glob skew_ms_default_: any;

with entry {
    skew_ms_default_ = DEFAULT_REFRESH_SKEW_SECONDS * 1000;
}

@dataclass(frozen=True)
class GrokOAuthCredentials {
    has access_token: str;

    has refresh_token: str | None;

    has expires_at_ms: int | None;

    has token_type: str = "Bearer";

    has scopes: tuple[str, ...] = DEFAULT_GROK_OAUTH_SCOPES;

    has issuer: str = DEFAULT_GROK_OAUTH_ISSUER;

    has client_id: str = DEFAULT_GROK_OAUTH_CLIENT_ID;

    class def from_payload(payload: dict[str, Any]) -> "GrokOAuthCredentials";

    def to_payload -> dict[str, Any];

    def is_valid(*, skew_ms: int = skew_ms_default_) -> bool;
}

glob path_default_: any;

with entry {
    path_default_ = DEFAULT_GROK_OAUTH_CREDENTIAL_PATH;
}

class GrokOAuthCredentialStore {
    has path: any,
        profile_store: any;

    def init(path: str | Path = path_default_);

    def load -> GrokOAuthCredentials | None;

    def save(
        credentials: GrokOAuthCredentials, *, deadline: OAuthLoginDeadline | None = None
    ) -> None;
}

"""Validate xAI ID tokens using its pinned ES256 JWKS endpoint."""
class GrokIDTokenValidator {
    has _jwks_client: any,
        _jwks_lock: any;

    def init(jwks_client: Any | None = None);

    def validate(
        token: str, *, nonce: str | None, deadline: OAuthLoginDeadline | None = None
    ) -> dict[str, Any];
}

glob refresh_skew_seconds_default_: any;

glob retry_backoff_seconds_default_: any;

glob prior_scopes_default_: any;

with entry {
    refresh_skew_seconds_default_ = DEFAULT_REFRESH_SKEW_SECONDS;
    retry_backoff_seconds_default_ = DEFAULT_TOKEN_RETRY_BACKOFF_SECONDS;
    prior_scopes_default_ = DEFAULT_GROK_OAUTH_SCOPES;
}

"""Load, exchange, and cross-process-refresh Mobilerun's xAI session."""
class GrokOAuthSessionManager {
    has credential_store: any,
        http_client: any,
        id_token_validator: any,
        request_timeout: any,
        refresh_skew_ms: any,
        retry_backoff_seconds: any,
        sleep: any,
        _thread_lock: any,
        _credentials: any;

    def init(
        *,
        credential_store: GrokOAuthCredentialStore | None = None,
        http_client: httpx.Client | None = None,
        id_token_validator: GrokIDTokenValidator | None = None,
        request_timeout: float = 20.0,
        refresh_skew_seconds: int = refresh_skew_seconds_default_,
        retry_backoff_seconds: tuple[float, ...] = retry_backoff_seconds_default_,
        sleep: Callable[[float], None] | None = None,
    );

    static def _expiry_ms(payload: dict[str, Any]) -> int | None;

    static def _scopes(payload: dict[str, Any], fallback: tuple[str, ...]) -> tuple[str, ...];

    def _credentials_from_token_response(
        payload: dict[str, Any],
        *,
        prior_refresh_token: str | None = None,
        prior_scopes: tuple[str, ...] = prior_scopes_default_,
        nonce: str | None = None,
        deadline: OAuthLoginDeadline | None = None,
    ) -> GrokOAuthCredentials;

    def _post_form(
        url: str,
        *,
        data: dict[str, str],
        headers: dict[str, str],
        context: str,
        retry_transient: bool,
        deadline: OAuthLoginDeadline | None = None,
    ) -> httpx.Response;

    def _post_token(
        data: dict[str, str],
        *,
        retry_transient: bool = False,
        refresh_request: bool = False,
        deadline: OAuthLoginDeadline | None = None,
    ) -> dict[str, Any];

    def set_initial_credentials(
        credentials: GrokOAuthCredentials, *, deadline: OAuthLoginDeadline | None = None
    ) -> None;

    def exchange_authorization_code(
        *,
        code: str,
        redirect_uri: str,
        code_verifier: str,
        nonce: str,
        deadline: OAuthLoginDeadline | None = None,
    ) -> GrokOAuthCredentials;

    def _refresh(credentials: GrokOAuthCredentials) -> GrokOAuthCredentials;

    def get_valid_credentials(
        *, force_refresh: bool = False, rejected_access_token: str | None = None
    ) -> GrokOAuthCredentials;
}

"""Inject a fresh bearer token and retry one rejected request once."""
class GrokOAuthAuth(httpx.Auth) {
    static has requires_request_body: any = True;

    def init(manager: GrokOAuthSessionManager, *, model: str);

    def _authorize(request: httpx.Request, credentials: GrokOAuthCredentials) -> None;

    def sync_auth_flow(request: httpx.Request) -> Generator[any, any, any];

    async def async_auth_flow(request: httpx.Request) -> AsyncGenerator[any, any];
}

glob model_default_: any;

glob oauth_refresh_skew_seconds_default_: any;

glob callback_host_default_: any;

glob callback_port_default_: any;

glob callback_path_default_: any;

with entry {
    model_default_ = DEFAULT_GROK_MODEL;
    oauth_refresh_skew_seconds_default_ = DEFAULT_REFRESH_SKEW_SECONDS;
    callback_host_default_ = DEFAULT_GROK_OAUTH_CALLBACK_HOST;
    callback_port_default_ = DEFAULT_GROK_OAUTH_CALLBACK_PORT;
    callback_path_default_ = DEFAULT_GROK_OAUTH_CALLBACK_PATH;
}

"""LlamaIndex Responses adapter backed only by Mobilerun's xAI OAuth slot."""
class GrokOAuth(OpenAIResponses) {
    has supports_native_tool_calls: ClassVar[bool] = True;

    class def class_name -> str;

    def init(
        model: str = model_default_,
        oauth_credential_path: str | None = None,
        credential_path: str | None = None,
        oauth_access_token: str | None = None,
        oauth_refresh_token: str | None = None,
        oauth_expires_at_ms: int | None = None,
        oauth_refresh_skew_seconds: int = oauth_refresh_skew_seconds_default_,
        oauth_session_manager: GrokOAuthSessionManager | None = None,
        http_client: httpx.Client | None = None,
        async_http_client: httpx.AsyncClient | None = None,
        **kwargs: Any,
    );

    has metadata: LLMMetadata {
        getter {
            return LLMMetadata(
                context_window=DEFAULT_GROK_CONTEXT_WINDOW,
                num_output=self.max_output_tokens or -1,
                is_chat_model=True,
                is_function_calling_model=True,
                model_name=self.model,
            );
        }
    }

    has _tokenizer: any {
        getter {
            return None;
        }
    }

    def _get_model_kwargs(**kwargs: Any) -> dict[str, Any];

    def _sanitize_request_kwargs(
        model_kwargs: dict[str, Any], *, omit_tool_choice: bool = False
    ) -> dict[str, Any];

    def structured_predict(
        output_cls: Any, prompt: Any, llm_kwargs: dict[str, Any] | None = None, **prompt_args: Any
    ) -> Any;

    async def astructured_predict(
        output_cls: Any, prompt: Any, llm_kwargs: dict[str, Any] | None = None, **prompt_args: Any
    ) -> Any;

    static def _build_auth_url(
        *, redirect_uri: str, code_challenge: str, state: str, nonce: str
    ) -> str;

    def login(
        *,
        open_browser: bool = True,
        timeout_seconds: float = 300.0,
        callback_host: str = callback_host_default_,
        callback_port: int = callback_port_default_,
        callback_path: str = callback_path_default_,
        device_code: bool = False,
        deadline: OAuthLoginDeadline | None = None,
    ) -> GrokOAuthCredentials;

    def _login_device_code(
        *, deadline: OAuthLoginDeadline, open_browser: bool
    ) -> GrokOAuthCredentials;
}

with entry {
    GrokOAuthLLM = GrokOAuth;
}
