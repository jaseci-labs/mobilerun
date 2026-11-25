import builtins;

import operator;

import from jaclang.comptime { target as target_ }

import base64;

import contextlib;

import hashlib;

import json;

import os;

import queue;

import secrets;

import sys;

import threading;

import time;

import weakref;

import webbrowser;

import from http.server { ThreadingHTTPServer as HTTPServer }

import from pathlib { Path }

import from typing { Any, Dict, Iterator, Literal, Optional, Sequence }

import from urllib.parse { parse_qs, urlencode, urlparse }

import requests;

import from llama_index.core.base.llms.types {
    ChatMessage,
    ChatResponse,
    ChatResponseGen,
    CompletionResponse,
    CompletionResponseGen,
    ImageBlock,
    LLMMetadata,
    MessageRole,
    TextBlock,
}

import from llama_index.core.bridge.pydantic { Field, PrivateAttr }

import from llama_index.core.callbacks { CallbackManager }

import from llama_index.core.constants { DEFAULT_TEMPERATURE }

import from llama_index.core.llms.callbacks { llm_chat_callback, llm_completion_callback }

import from llama_index.core.llms.custom { CustomLLM }

glob DEFAULT_MODEL: any = ANTHROPIC_OAUTH_DEFAULT_MODEL;

glob DEFAULT_MAX_TOKENS: any = 8192;

glob DEFAULT_API_BASE: any = "https://api.anthropic.com";

glob DEFAULT_TOKEN_URL: any = "https://platform.claude.com/v1/oauth/token";

glob DEFAULT_AUTHORIZE_URL: any = "https://platform.claude.com/oauth/authorize";

glob DEFAULT_MODERN_AUTHORIZE_URL: any = "https://claude.com/cai/oauth/authorize";

glob DEFAULT_CLIENT_ID: any = "9d1c250a-e61b-44d9-88ed-5944d1962f5e";

glob DEFAULT_CREDENTIAL_PATH: any = `str(ANTHROPIC_OAUTH_CREDENTIAL_PATH);

glob DEFAULT_LOGIN_SCOPE: any = "org:create_api_key user:profile";

glob DEFAULT_MODERN_LOGIN_SCOPE: any = "org:create_api_key user:profile user:inference user:sessions:claude_code user:mcp_servers user:file_upload";

glob DEFAULT_SETUP_TOKEN_SCOPE: any = "user:inference";

glob DEFAULT_REFRESH_SCOPE: any = "user:inference user:profile user:file_upload user:mcp_servers user:sessions:claude_code";

glob DEFAULT_OAUTH_BETA: any = "oauth-2025-04-20";

glob DEFAULT_ANTHROPIC_VERSION: any = "2023-06-01";

glob DEFAULT_CLAUDE_CODE_VERSION: any = "2.1.281";

glob DEFAULT_USER_AGENT: any;

glob DEFAULT_CC_VERSION: any;

glob DEFAULT_CC_ENTRYPOINT: any;

glob DEFAULT_TIMEOUT_SECONDS: any;

glob _IGNORED_REQUEST_KWARGS: any;

glob _ERROR_TYPE_STATUS: any;

glob _MAX_CODE_ATTEMPTS: any;

with entry {
    DEFAULT_USER_AGENT = f"claude-cli/{DEFAULT_CLAUDE_CODE_VERSION}";
    DEFAULT_CC_VERSION = f"{DEFAULT_CLAUDE_CODE_VERSION}.000";
    DEFAULT_CC_ENTRYPOINT = "cli";
    DEFAULT_TIMEOUT_SECONDS = 60.0;
    _IGNORED_REQUEST_KWARGS = {"formatted"};
    _ERROR_TYPE_STATUS = {
        "invalid_request_error": 400,
        "authentication_error": 401,
        "billing_error": 402,
        "permission_error": 403,
        "not_found_error": 404,
        "request_too_large": 413,
        "rate_limit_error": 429,
        "api_error": 500,
        "timeout_error": 504,
        "overloaded_error": 529,
    };
}

"""Error event in, or early end of, a streamed Messages response."""
class AnthropicOAuthStreamError(requests.HTTPError, Exception) {
    def init(
        message: builtins.str, *, error_type: Optional[builtins.str] = None, request: Any = None
    );
}

def _iter_sse_events(response: Any) -> Generator[any, any, any];

def _b64_no_pad(raw: builtins.bytes) -> builtins.str;

def _pkce_pair -> builtins.tuple[builtins.str, builtins.str];

with entry {
    _MAX_CODE_ATTEMPTS = 2;
}

def _is_headless_environment -> builtins.bool;

def _normalize_manual_code(raw: builtins.str, expected_state: builtins.str) -> builtins.str;

glob model_default_: any;

glob max_tokens_default_: any;

glob temperature_default_: any;

glob timeout_default_: any;

glob client_id_default_: any;

glob authorize_url_default_: any;

glob token_url_default_: any;

glob login_scope_default_: any;

glob refresh_scope_default_: any;

glob credential_path_default_: any;

glob api_base_default_: any;

glob anthropic_version_default_: any;

glob oauth_beta_default_: any;

glob user_agent_default_: any;

glob cc_version_default_: any;

glob cc_entrypoint_default_: any;

glob input_fn_default_: any;

with entry {
    model_default_ = DEFAULT_MODEL;
    max_tokens_default_ = DEFAULT_MAX_TOKENS;
    temperature_default_ = DEFAULT_TEMPERATURE;
    timeout_default_ = DEFAULT_TIMEOUT_SECONDS;
    client_id_default_ = DEFAULT_CLIENT_ID;
    authorize_url_default_ = DEFAULT_AUTHORIZE_URL;
    token_url_default_ = DEFAULT_TOKEN_URL;
    login_scope_default_ = DEFAULT_LOGIN_SCOPE;
    refresh_scope_default_ = DEFAULT_REFRESH_SCOPE;
    credential_path_default_ = DEFAULT_CREDENTIAL_PATH;
    api_base_default_ = DEFAULT_API_BASE;
    anthropic_version_default_ = DEFAULT_ANTHROPIC_VERSION;
    oauth_beta_default_ = DEFAULT_OAUTH_BETA;
    user_agent_default_ = DEFAULT_USER_AGENT;
    cc_version_default_ = DEFAULT_CC_VERSION;
    cc_entrypoint_default_ = DEFAULT_CC_ENTRYPOINT;
    input_fn_default_ = builtins.input;
}

"""Anthropic OAuth-backed LLM using Claude subscription OAuth tokens."""
class AnthropicOAuthLLM(CustomLLM) {
    has model: builtins.str = Field(default=DEFAULT_MODEL, description="Anthropic model id.");

    has max_tokens: Optional[builtins.int] = Field(default=DEFAULT_MAX_TOKENS, gt=0);

    has temperature: builtins.float = Field(default=DEFAULT_TEMPERATURE, ge=0.0, le=2.0);

    has timeout: builtins.float = Field(default=DEFAULT_TIMEOUT_SECONDS, gt=0);

    has access_token: Optional[builtins.str] = Field(
        default=None, description="OAuth access token."
    );

    has refresh_token: Optional[builtins.str] = Field(
        default=None, description="OAuth refresh token."
    );

    has client_id: builtins.str = Field(default=DEFAULT_CLIENT_ID);

    has authorize_url: builtins.str = Field(default=DEFAULT_AUTHORIZE_URL);

    has token_url: builtins.str = Field(default=DEFAULT_TOKEN_URL);

    has login_scope: builtins.str = Field(default=DEFAULT_LOGIN_SCOPE);

    has refresh_scope: builtins.str = Field(default=DEFAULT_REFRESH_SCOPE);

    has refresh_buffer_seconds: builtins.int = Field(default=300, ge=0);

    has credential_path: Optional[builtins.str] = Field(default=DEFAULT_CREDENTIAL_PATH);

    has api_base: builtins.str = Field(default=DEFAULT_API_BASE);

    has anthropic_version: builtins.str = Field(default=DEFAULT_ANTHROPIC_VERSION);

    has oauth_beta: builtins.str = Field(default=DEFAULT_OAUTH_BETA);

    has user_agent: Optional[builtins.str] = Field(default=DEFAULT_USER_AGENT);

    has billing_header_mode: Literal["auto", "always", "never"] = Field(default="auto");

    has cc_version: builtins.str = Field(default=DEFAULT_CC_VERSION);

    has cc_entrypoint: builtins.str = Field(default=DEFAULT_CC_ENTRYPOINT);

    has cch_value: builtins.str = Field(default="00000");

    has inject_identifier: builtins.bool = Field(default=False);

    has identifier_text: builtins.str = Field(
        default="You are Claude Code, Anthropic's official CLI for Claude."
    );

    has additional_kwargs: Dict[builtins.str, Any] = Field(default_factory=dict[any, any]);

    has _session: requests.Session = PrivateAttr();

    has _cached_access_token: Optional[builtins.str] = PrivateAttr(default=None);

    has _cached_refresh_token: Optional[builtins.str] = PrivateAttr(default=None);

    has _access_token_expiry: Optional[builtins.float] = PrivateAttr(default=None);

    def init(
        model: builtins.str = model_default_,
        *,
        max_tokens: Optional[builtins.int] = max_tokens_default_,
        temperature: builtins.float = temperature_default_,
        timeout: builtins.float = timeout_default_,
        access_token: Optional[builtins.str] = None,
        refresh_token: Optional[builtins.str] = None,
        client_id: builtins.str = client_id_default_,
        authorize_url: builtins.str = authorize_url_default_,
        token_url: builtins.str = token_url_default_,
        login_scope: builtins.str = login_scope_default_,
        refresh_scope: builtins.str = refresh_scope_default_,
        refresh_buffer_seconds: builtins.int = 300,
        credential_path: Optional[builtins.str] = credential_path_default_,
        api_base: builtins.str = api_base_default_,
        anthropic_version: builtins.str = anthropic_version_default_,
        oauth_beta: builtins.str = oauth_beta_default_,
        user_agent: Optional[builtins.str] = user_agent_default_,
        billing_header_mode: Literal["auto", "always", "never"] = "auto",
        cc_version: builtins.str = cc_version_default_,
        cc_entrypoint: builtins.str = cc_entrypoint_default_,
        cch_value: builtins.str = "00000",
        inject_identifier: builtins.bool = False,
        identifier_text: builtins.str = "You are Claude Code, Anthropic's official CLI for Claude.",
        additional_kwargs: Optional[Dict[builtins.str, Any]] = None,
        callback_manager: Optional[CallbackManager] = None,
    );

    class def class_name -> builtins.str;

    has metadata: LLMMetadata {
        getter {
            return LLMMetadata(
                context_window=anthropic_model_context_window(self.model) or 200000,
                num_output=self.max_tokens or -1,
                model_name=self.model,
                is_chat_model=True,
                is_function_calling_model=False,
            );
        }
    }

    def _load_credentials_from_file(credential_path: builtins.str) -> None;

    def _persist_credentials(*, deadline: OAuthLoginDeadline | None = None) -> None;

    def _token_headers -> Dict[builtins.str, builtins.str];

    def _access_token_is_stale -> builtins.bool;

    def _refresh_access_token -> builtins.str;

    def _exchange_authorization_code(
        *,
        code: builtins.str,
        redirect_uri: builtins.str,
        code_verifier: builtins.str,
        state: builtins.str,
        expires_in: Optional[builtins.int] = None,
        deadline: OAuthLoginDeadline | None = None,
    ) -> builtins.str;

    def _build_auth_url(
        *, redirect_uri: builtins.str, code_challenge: builtins.str, state: builtins.str
    ) -> builtins.str;

    def login(
        *,
        open_browser: builtins.bool = True,
        timeout_seconds: builtins.float = 300.0,
        callback_host: builtins.str = "127.0.0.1",
        callback_port: builtins.int = 0,
        callback_path: builtins.str = "/callback",
        expires_in: Optional[builtins.int] = None,
        deadline: OAuthLoginDeadline | None = None,
    ) -> builtins.str;

    def login_headless(
        *,
        open_browser: builtins.bool = False,
        timeout_seconds: builtins.float = 300.0,
        input_fn: Any = input_fn_default_,
        expires_in: Optional[builtins.int] = None,
        deadline: OAuthLoginDeadline | None = None,
    ) -> builtins.str;

    def _resolve_access_token -> builtins.str;

    static def _extract_text(payload: Dict[builtins.str, Any]) -> builtins.str;

    static def _image_media_type(raw: builtins.bytes) -> builtins.str;

    class def _content_blocks(
        message: ChatMessage
    ) -> builtins.list[builtins.dict[builtins.str, Any]];

    def _to_provider_messages(
        messages: Sequence[ChatMessage]
    ) -> builtins.tuple[builtins.list[builtins.dict[builtins.str, Any]], builtins.list[builtins.str]];

    def _billing_header_text -> builtins.str;

    def _use_billing_header(model_id: builtins.str) -> builtins.bool;

    static def _supports_temperature(model_id: builtins.str) -> builtins.bool;

    def _system_blocks(
        user_system_lines: Sequence[builtins.str], model_id: builtins.str
    ) -> builtins.list[builtins.dict[builtins.str, builtins.str]];

    static def _sanitize_request_kwargs(kwargs: Dict[builtins.str, Any]) -> Dict[builtins.str, Any];

    def _messages_request(
        messages: Sequence[ChatMessage], kwargs: Dict[builtins.str, Any]
    ) -> builtins.tuple[builtins.str, Dict[builtins.str, builtins.str], Dict[builtins.str, Any]];

    class def _chat_response(
        data: Dict[builtins.str, Any], delta: Optional[builtins.str] = None
    ) -> ChatResponse;

    @llm_chat_callback()
    def chat(messages: Sequence[ChatMessage], **kwargs: Any) -> ChatResponse;

    @llm_completion_callback()
    def complete(
        prompt: builtins.str, formatted: builtins.bool = False, **kwargs: Any
    ) -> CompletionResponse;

    @llm_chat_callback()
    def stream_chat(messages: Sequence[ChatMessage], **kwargs: Any) -> ChatResponseGen;

    def _stream_responses(res: Any) -> Generator[any, any, any];

    @llm_completion_callback()
    def stream_complete(
        prompt: builtins.str, formatted: builtins.bool = False, **kwargs: Any
    ) -> CompletionResponseGen;
}
