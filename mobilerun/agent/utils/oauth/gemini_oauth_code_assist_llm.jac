import builtins;

import operator;

import from jaclang.comptime { target as target_ }

import base64;

import hashlib;

import json;

import os;

import platform;

import queue;

import secrets;

import sys;

import threading;

import time;

import webbrowser;

import from collections.abc { Mapping }

import from http.server { BaseHTTPRequestHandler }

import from http.server { ThreadingHTTPServer as HTTPServer }

import from pathlib { Path }

import from typing { Any, ClassVar, Dict, Optional, Sequence }

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

glob DEFAULT_MODEL: any;

glob DEFAULT_CODE_ASSIST_ENDPOINT: any;

glob DEFAULT_CODE_ASSIST_API_VERSION: any;

glob DEFAULT_CODE_ASSIST_MODELS_METHOD: any;

glob DEFAULT_TOKEN_URL: any;

glob DEFAULT_AUTHORIZE_URL: any;

glob DEFAULT_CREDENTIAL_PATH: any;

glob DEFAULT_CLIENT_ID: any;

glob DEFAULT_CLIENT_SECRET: any;

glob DEFAULT_OAUTH_SCOPES: any;

glob DEFAULT_CREDENTIAL_SLOT: any;

glob ANTIGRAVITY_CLIENT_VERSION: any;

glob DEFAULT_TIMEOUT_SECONDS: any;

glob _IGNORED_REQUEST_KWARGS: any;

glob _GEMINI_SAMPLING_CONFIG_KEYS: any;

glob _UNSET: any;

glob _MAX_CODE_ATTEMPTS: any;

with entry {
    DEFAULT_MODEL = GEMINI_OAUTH_DEFAULT_MODEL;
    DEFAULT_CODE_ASSIST_ENDPOINT = "https://daily-cloudcode-pa.googleapis.com";
    DEFAULT_CODE_ASSIST_API_VERSION = "v1internal";
    DEFAULT_CODE_ASSIST_MODELS_METHOD = "fetchAvailableModels";
    DEFAULT_TOKEN_URL = "https://oauth2.googleapis.com/token";
    DEFAULT_AUTHORIZE_URL = "https://accounts.google.com/o/oauth2/v2/auth";
    DEFAULT_CREDENTIAL_PATH = `str(GEMINI_OAUTH_CREDENTIAL_PATH);
    DEFAULT_CLIENT_ID = "1071006060591-tmhssin2h21lcre235vtolojh4g403ep.apps.googleusercontent.com";
    DEFAULT_CLIENT_SECRET = "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";

    DEFAULT_OAUTH_SCOPES = (
        "https://www.googleapis.com/auth/aicode",
        "https://www.googleapis.com/auth/cclog",
        "https://www.googleapis.com/auth/cloud-platform",
        "https://www.googleapis.com/auth/userinfo.email",
        "https://www.googleapis.com/auth/userinfo.profile",
    );
    DEFAULT_CREDENTIAL_SLOT = "geminiAntigravityOauth";
    ANTIGRAVITY_CLIENT_VERSION = "2.14.0";
    DEFAULT_TIMEOUT_SECONDS = 60.0;
}

def _antigravity_user_agent -> builtins.str;

with entry {
    _IGNORED_REQUEST_KWARGS = {"formatted", "project", "project_id"};
    _GEMINI_SAMPLING_CONFIG_KEYS = {"temperature", "topP", "topK", "top_p", "top_k"};
    _UNSET = object();
}

def _camel_case_keys(config: Mapping[builtins.str, Any]) -> Dict[builtins.str, Any];

def _b64_no_pad(raw: builtins.bytes) -> builtins.str;

def _pkce_pair -> builtins.tuple[builtins.str, builtins.str];

with entry {
    _MAX_CODE_ATTEMPTS = 2;
}

def _is_headless_environment -> builtins.bool;

def _normalize_manual_code(raw: builtins.str, expected_state: builtins.str) -> builtins.str;

glob credential_slot_default_: any;

glob temperature_default_: any;

glob timeout_default_: any;

glob client_id_default_: any;

glob client_secret_default_: any;

glob authorize_url_default_: any;

glob token_url_default_: any;

glob code_assist_endpoint_default_: any;

glob code_assist_api_version_default_: any;

glob credential_path_default_: any;

glob input_fn_default_: any;

with entry {
    credential_slot_default_ = DEFAULT_CREDENTIAL_SLOT;
    temperature_default_ = DEFAULT_TEMPERATURE;
    timeout_default_ = DEFAULT_TIMEOUT_SECONDS;
    client_id_default_ = DEFAULT_CLIENT_ID;
    client_secret_default_ = DEFAULT_CLIENT_SECRET;
    authorize_url_default_ = DEFAULT_AUTHORIZE_URL;
    token_url_default_ = DEFAULT_TOKEN_URL;
    code_assist_endpoint_default_ = DEFAULT_CODE_ASSIST_ENDPOINT;
    code_assist_api_version_default_ = DEFAULT_CODE_ASSIST_API_VERSION;
    credential_path_default_ = DEFAULT_CREDENTIAL_PATH;
    input_fn_default_ = builtins.input;
}

"""Gemini OAuth LLM that talks to Google Code Assist endpoints.

    This class expects at least one of:
    - `access_token`
    - `refresh_token`
    - `credential_path` file containing cached OAuth credentials.

    Cached credentials are stored in mobilerun's config dir.
    """
class GeminiOAuthCodeAssistLLM(CustomLLM) {
    has MODEL_PRESETS: ClassVar[Dict[builtins.str, builtins.str]] = {
        "flash": GEMINI_OAUTH_DEFAULT_MODEL,
        "pro": "gemini-pro-agent",
        "flash_lite": "gemini-3.5-flash-lite",
    };

    has model: builtins.str = Field(default=DEFAULT_MODEL, description="Gemini model id.");

    has model_preset: Optional[builtins.str] = Field(
        default=None, description="Quick model selector key from MODEL_PRESETS."
    );

    has custom_model: Optional[builtins.str] = Field(
        default=None, description="Optional custom model id; overrides model/model_preset."
    );

    has credential_slot: builtins.str = Field(
        default=DEFAULT_CREDENTIAL_SLOT,
        description="Nested key in the shared auth-profiles.json credential file.",
    );

    has max_tokens: Optional[builtins.int] = Field(default=None, gt=0);

    has temperature: builtins.float = Field(default=DEFAULT_TEMPERATURE, ge=0.0, le=2.0);

    has timeout: builtins.float = Field(default=DEFAULT_TIMEOUT_SECONDS, gt=0);

    has access_token: Optional[builtins.str] = Field(
        default=None, description="OAuth access token."
    );

    has refresh_token: Optional[builtins.str] = Field(
        default=None, description="OAuth refresh token."
    );

    has client_id: builtins.str = Field(default=DEFAULT_CLIENT_ID);

    has client_secret: builtins.str = Field(default=DEFAULT_CLIENT_SECRET);

    has authorize_url: builtins.str = Field(default=DEFAULT_AUTHORIZE_URL);

    has token_url: builtins.str = Field(default=DEFAULT_TOKEN_URL);

    has refresh_buffer_seconds: builtins.int = Field(default=300, ge=0);

    has code_assist_endpoint: builtins.str = Field(default=DEFAULT_CODE_ASSIST_ENDPOINT);

    has code_assist_api_version: builtins.str = Field(default=DEFAULT_CODE_ASSIST_API_VERSION);

    has scopes: builtins.tuple = Field(default=DEFAULT_OAUTH_SCOPES);

    has credential_path: Optional[builtins.str] = Field(
        default=DEFAULT_CREDENTIAL_PATH,
        description="Optional path to JSON OAuth credentials cache.",
    );

    has additional_kwargs: Dict[builtins.str, Any] = Field(default_factory=dict[any, any]);

    has _session: requests.Session = PrivateAttr();

    has _cached_access_token: Optional[builtins.str] = PrivateAttr(default=None);

    has _cached_refresh_token: Optional[builtins.str] = PrivateAttr(default=None);

    has _access_token_expiry: Optional[builtins.float] = PrivateAttr(default=None);

    def init(
        model: Optional[builtins.str] = None,
        *,
        model_preset: Optional[builtins.str] = None,
        custom_model: Optional[builtins.str] = None,
        credential_slot: builtins.str = credential_slot_default_,
        max_tokens: Optional[builtins.int] = None,
        temperature: builtins.float = temperature_default_,
        timeout: builtins.float = timeout_default_,
        access_token: Optional[builtins.str] = None,
        refresh_token: Optional[builtins.str] = None,
        client_id: builtins.str = client_id_default_,
        client_secret: builtins.str = client_secret_default_,
        authorize_url: builtins.str = authorize_url_default_,
        token_url: builtins.str = token_url_default_,
        refresh_buffer_seconds: builtins.int = 300,
        code_assist_endpoint: builtins.str = code_assist_endpoint_default_,
        code_assist_api_version: builtins.str = code_assist_api_version_default_,
        scopes: Optional[Sequence[builtins.str]] = None,
        credential_path: Optional[builtins.str] = credential_path_default_,
        additional_kwargs: Optional[Dict[builtins.str, Any]] = None,
        callback_manager: Optional[CallbackManager] = None,
    );

    class def available_model_presets -> Dict[builtins.str, builtins.str];

    class def class_name -> builtins.str;

    has metadata: LLMMetadata {
        getter {
            return LLMMetadata(
                context_window=1000000,
                num_output=self.max_tokens or -1,
                model_name=self.model,
                is_chat_model=True,
                is_function_calling_model=False,
            );
        }
    }

    def _load_credentials_from_file(credential_path: builtins.str) -> None;

    def _persist_credentials(*, deadline: OAuthLoginDeadline | None = None) -> None;

    def _metadata_payload -> Dict[builtins.str, builtins.str];

    def _build_headers(token: builtins.str) -> Dict[builtins.str, builtins.str];

    def fetch_available_models(
        *, deadline: OAuthLoginDeadline | None = None, access_token: builtins.str | None = None
    ) -> builtins.list[Dict[builtins.str, Any]];

    def _access_token_is_stale -> builtins.bool;

    def _refresh_access_token -> builtins.str;

    def _exchange_authorization_code(
        code: builtins.str,
        redirect_uri: builtins.str,
        code_verifier: Optional[builtins.str] = None,
        deadline: OAuthLoginDeadline | None = None,
        persist_credentials: builtins.bool = True,
    ) -> builtins.str;

    def _build_auth_url(
        redirect_uri: builtins.str,
        state: builtins.str,
        prompt_consent: builtins.bool,
        code_challenge: Optional[builtins.str] = None,
    ) -> builtins.str;

    def login(
        *,
        open_browser: builtins.bool = True,
        timeout_seconds: builtins.float = 300.0,
        callback_host: builtins.str = "127.0.0.1",
        callback_port: builtins.int = 0,
        callback_path: builtins.str = "/oauth2callback",
        prompt_consent: builtins.bool = True,
        deadline: OAuthLoginDeadline | None = None,
        persist_credentials: builtins.bool = True,
    ) -> builtins.str;

    def login_headless(
        *,
        open_browser: builtins.bool = False,
        timeout_seconds: builtins.float = 300.0,
        input_fn: Any = input_fn_default_,
        prompt_consent: builtins.bool = True,
        deadline: OAuthLoginDeadline | None = None,
        persist_credentials: builtins.bool = True,
    ) -> builtins.str;

    def _resolve_access_token -> builtins.str;

    static def _message_text(message: ChatMessage) -> builtins.str;

    static def _image_mime_type(raw: builtins.bytes) -> builtins.str;

    class def _message_parts(message: ChatMessage) -> builtins.list[Dict[builtins.str, Any]];

    def _to_code_assist_request(
        messages: Sequence[ChatMessage], **kwargs: Any
    ) -> Dict[builtins.str, Any];

    def _method_url(method: builtins.str) -> builtins.str;

    static def _extract_text(chunk: Dict[builtins.str, Any]) -> builtins.str;

    @llm_chat_callback()
    def chat(messages: Sequence[ChatMessage], **kwargs: Any) -> ChatResponse;

    @llm_completion_callback()
    def complete(prompt: builtins.str, **kwargs: Any) -> CompletionResponse;

    @llm_chat_callback()
    def stream_chat(messages: Sequence[ChatMessage], **kwargs: Any) -> ChatResponseGen;

    @llm_completion_callback()
    def stream_complete(prompt: builtins.str, **kwargs: Any) -> CompletionResponseGen;
}
