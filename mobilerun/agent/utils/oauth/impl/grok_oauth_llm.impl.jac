impl _b64_no_pad(raw: bytes) -> str {
    return base64.urlsafe_b64encode(raw).decode("ascii").rstrip("=");
}

impl _pkce_pair -> tuple[str, str] {
    verifier: any = _b64_no_pad(secrets.token_bytes(64));
    challenge: any = _b64_no_pad(hashlib.sha256(verifier.encode("ascii")).digest());
    return (verifier, challenge);
}

impl _is_headless_environment -> bool {
    if os.environ.get("SSH_CONNECTION") or os.environ.get("SSH_TTY") {
        return True;
    }
    if os.environ.get("WSL_DISTRO_NAME") {
        return True;
    }
    return sys.platform.startswith("linux")
        and not (os.environ.get("DISPLAY") or os.environ.get("WAYLAND_DISPLAY"));
}

impl _parse_callback_query(query: str) -> dict[str, str | None] {
    params: any = parse_qs(query, keep_blank_values=True);
    code_values: any = params.get("code", []);
    state_values: any = params.get("state", []);
    error_values: any = params.get("error", []);
    valid_cardinality: any = operator.le(len(code_values), 1)
        and operator.le(len(state_values), 1)
        and operator.le(len(error_values), 1);
    return {
        "code": code_values[0] if len(code_values) == 1 else None,
        "state": state_values[0] if len(state_values) == 1 else None,
        "error": error_values[0]
            if len(error_values) == 1
            else "invalid_callback" if not valid_cardinality else None,
    };
}

impl GrokOAuthError.__repr__ -> str {
    return (getattr(builtins.super(GrokOAuthError, self), "__repr__") as any)();
}

impl GrokOAuthError.__eq__(other: any) -> bool {
    return self is other;
}

impl GrokOAuthError.__hash__ -> int {
    return id(self);
}

impl GrokOAuthReloginRequired.__repr__ -> str {
    return (getattr(builtins.super(GrokOAuthReloginRequired, self), "__repr__") as any)();
}

impl GrokOAuthReloginRequired.__eq__(other: any) -> bool {
    return self is other;
}

impl GrokOAuthReloginRequired.__hash__ -> int {
    return id(self);
}

impl _safe_error_code(value: object) -> str | None {
    return value if isinstance(value, `str) and _OAUTH_ERROR_CODE.fullmatch(value) else None;
}

impl _safe_token_error_code(value: object) -> str | None {
    return value if isinstance(value, `str) and value in _TOKEN_ERROR_CODES else None;
}

impl _safe_json_object(response: httpx.Response, *, context: str) -> dict[str, Any] {
    try {
        payload: any = response.json();
    } except Exception as exc {
        raise GrokOAuthError(f"{context} did not return valid JSON.") from exc;
    }
    if not isinstance(payload, `dict) {
        raise GrokOAuthError(f"{context} did not return a JSON object.");
    }
    return payload;
}

impl GrokOAuthCredentials.from_payload(payload: dict[str, Any]) -> "GrokOAuthCredentials" {
    if payload.get("type") != "oauth" or payload.get("provider") != "xai-grok" {
        raise ValueError("XAI OAuth profile has an unexpected credential type.");
    }
    access_token: any = payload.get("accessToken");
    if not isinstance(access_token, `str) or not access_token {
        raise ValueError("XAI OAuth profile is missing accessToken.");
    }
    issuer: any = payload.get("issuer");
    client_id: any = payload.get("clientId");
    if issuer != DEFAULT_GROK_OAUTH_ISSUER {
        raise ValueError("XAI OAuth profile has an unexpected issuer.");
    }
    if client_id != DEFAULT_GROK_OAUTH_CLIENT_ID {
        raise ValueError("XAI OAuth profile has an unexpected clientId.");
    }

    refresh: any = payload.get("refreshToken");
    raw_expiry: any = payload.get("expiresAt");
    try {
        expires_at_ms: any = `int(raw_expiry) if raw_expiry is not None else None;
    } except (TypeError, ValueError) {
        expires_at_ms = None;
    }
    raw_scopes: any = payload.get("scopes");
    scopes: any = `tuple(`str(value) for value in raw_scopes if isinstance(value, `str))
        if isinstance(raw_scopes, `list)
        else DEFAULT_GROK_OAUTH_SCOPES;
    token_type: any = `str(payload.get("tokenType") or "Bearer");
    if token_type.lower() != "bearer" {
        raise ValueError("XAI OAuth profile has an unsupported tokenType.");
    }
    return cls(
        access_token=access_token,
        refresh_token=refresh if isinstance(refresh, `str) and refresh else None,
        expires_at_ms=expires_at_ms,
        token_type="Bearer",
        scopes=scopes,
        issuer=issuer,
        client_id=client_id,
    );
}

impl GrokOAuthCredentials.to_payload -> dict[str, Any] {
    return {
        "type": "oauth",
        "provider": "xai-grok",
        "accessToken": self.access_token,
        "refreshToken": self.refresh_token,
        "expiresAt": self.expires_at_ms,
        "tokenType": self.token_type,
        "scopes": `list(self.scopes),
        "issuer": self.issuer,
        "clientId": self.client_id,
    };
}

impl GrokOAuthCredentials.is_valid(*, skew_ms: int = skew_ms_default_) -> bool {
    return self.expires_at_ms is None
        or operator.lt(`int(time.time() * 1000) + skew_ms, self.expires_at_ms);
}

impl GrokOAuthCredentialStore.init(path: str | Path = path_default_) {
    self.path = Path(path).expanduser();
    self.profile_store = AuthProfileStore(self.path);
}

impl GrokOAuthCredentialStore.load -> GrokOAuthCredentials | None {
    payload: any = self.profile_store.read_slot(DEFAULT_GROK_OAUTH_SLOT);
    if payload is None {
        return None;
    }
    return GrokOAuthCredentials.from_payload(payload);
}

impl GrokOAuthCredentialStore.save(
    credentials: GrokOAuthCredentials, *, deadline: OAuthLoginDeadline | None = None
) -> None {
    if deadline is not None {
        deadline.check();
    }
    self.profile_store.update_slot(
        DEFAULT_GROK_OAUTH_SLOT,
        credentials.to_payload(),
        lock_timeout=deadline.remaining() if deadline is not None else None,
        before_commit=deadline.check if deadline is not None else None,
    );
}

impl GrokOAuthCredentialStore.__repr__ -> str {
    return (getattr(builtins.object, "__repr__") as any)(self);
}

impl GrokOAuthCredentialStore.__eq__(other: any) -> bool {
    return self is other;
}

impl GrokOAuthCredentialStore.__hash__ -> int {
    return id(self);
}

impl GrokIDTokenValidator.init(jwks_client: Any | None = None) {
    self._jwks_client = jwks_client or jwt.PyJWKClient(DEFAULT_GROK_OAUTH_JWKS_URL);
    self._jwks_lock = threading.Lock();
}

impl GrokIDTokenValidator.validate(
    token: str, *, nonce: str | None, deadline: OAuthLoginDeadline | None = None
) -> dict[str, Any] {
    original_timeout: any;
    original_fetch: any;
    if deadline is None {
        self._jwks_lock.acquire();
    } elif not self._jwks_lock.acquire(timeout=deadline.remaining()) {
        raise TimeoutError("XAI OAuth login timed out.");
    }
    had_timeout: any = hasattr(self._jwks_client, "timeout");
    original_timeout = getattr(self._jwks_client, "timeout", None);
    timeout_changed: any = False;
    instance_attributes: any = getattr(self._jwks_client, "__dict__", {});
    had_fetch_override: any = "fetch_data" in instance_attributes;
    original_fetch_override: any = instance_attributes.get("fetch_data");
    fetch_changed: any = False;

    def _remaining_request_timeout -> float {
        if deadline is None {
            raise AssertionError("JWKS deadline wrapper requires a deadline");
        }
        try {
            return deadline.remaining(cap=`float(original_timeout));
        } except (TypeError, ValueError) {
            return deadline.remaining();
        }
    }

    try {
        if deadline is not None {
            deadline.check();
            if `type(self._jwks_client) is jwt.PyJWKClient {
                original_fetch = self._jwks_client.fetch_data;

                def _fetch_with_remaining_deadline -> Any {
                    self._jwks_client.timeout = _remaining_request_timeout();
                    return original_fetch();
                }

                self._jwks_client.fetch_data = _fetch_with_remaining_deadline;
                fetch_changed = True;
                timeout_changed = True;
            } else {
                try {
                    self._jwks_client.timeout = _remaining_request_timeout();
                    timeout_changed = True;
                } except (AttributeError, TypeError, ValueError) {}
            }
        }
        signing_key: any = self._jwks_client.get_signing_key_from_jwt(token).key;
        if deadline is not None {
            deadline.check();
        }
    } finally {
        if fetch_changed {
            if had_fetch_override {
                self._jwks_client.fetch_data = original_fetch_override;
            } else {
                delattr(self._jwks_client, "fetch_data");
            }
        }
        if timeout_changed {
            try {
                if had_timeout {
                    self._jwks_client.timeout = original_timeout;
                } else {
                    delattr(self._jwks_client, "timeout");
                }
            } except (AttributeError, TypeError) {}
        }
        self._jwks_lock.release();
    }
    claims: any = jwt.decode(
        token,
        signing_key,
        algorithms=["ES256"],
        issuer=DEFAULT_GROK_OAUTH_ISSUER,
        audience=DEFAULT_GROK_OAUTH_CLIENT_ID,
        options={"require": ["exp", "iat", "iss", "aud", "sub"]},
    );
    if nonce is not None and claims.get("nonce") != nonce {
        raise jwt.InvalidTokenError("ID token nonce mismatch.");
    }
    if deadline is not None {
        deadline.check();
    }
    return claims;
}

impl GrokIDTokenValidator.__repr__ -> str {
    return (getattr(builtins.object, "__repr__") as any)(self);
}

impl GrokIDTokenValidator.__eq__(other: any) -> bool {
    return self is other;
}

impl GrokIDTokenValidator.__hash__ -> int {
    return id(self);
}

impl GrokOAuthSessionManager.init(
    *,
    credential_store: GrokOAuthCredentialStore | None = None,
    http_client: httpx.Client | None = None,
    id_token_validator: GrokIDTokenValidator | None = None,
    request_timeout: float = 20.0,
    refresh_skew_seconds: int = refresh_skew_seconds_default_,
    retry_backoff_seconds: tuple[float, ...] = retry_backoff_seconds_default_,
    sleep: Callable[[float], None] | None = None,
) {
    self.credential_store = credential_store or GrokOAuthCredentialStore();
    self.http_client = http_client or httpx.Client();
    self.id_token_validator = id_token_validator or GrokIDTokenValidator();
    self.request_timeout = request_timeout;
    self.refresh_skew_ms = max(0, `int(refresh_skew_seconds)) * 1000;
    self.retry_backoff_seconds = `tuple(
        max(0.0, `float(delay)) for delay in retry_backoff_seconds[:2]
    );
    self.sleep = sleep or time.sleep;
    self._thread_lock = threading.RLock();
    self._credentials = None;
}

impl GrokOAuthSessionManager._expiry_ms(payload: dict[str, Any]) -> int | None {
    try {
        return `int(time.time() * 1000) + `int(payload["expires_in"]) * 1000;
    } except (KeyError, TypeError, ValueError) {}
    for key in ("id_token", "access_token") {
        token: any = payload.get(key);
        if not isinstance(token, `str) {
            continue;
        }
        try {
            claims: any = jwt.decode(
                token,
                options={"verify_signature": False, "verify_exp": False},
                algorithms=["ES256"],
            );
            return `int(claims["exp"]) * 1000;
        } except (jwt.PyJWTError, KeyError, TypeError, ValueError) {
            continue;
        }
    }
    return None;
}

impl GrokOAuthSessionManager._scopes(
    payload: dict[str, Any], fallback: tuple[str, ...]
) -> tuple[str, ...] {
    raw_scope: any = payload.get("scope");
    if isinstance(raw_scope, `str) and raw_scope.strip() {
        return `tuple(raw_scope.split());
    }
    return fallback;
}

impl GrokOAuthSessionManager._credentials_from_token_response(
    payload: dict[str, Any],
    *,
    prior_refresh_token: str | None = None,
    prior_scopes: tuple[str, ...] = prior_scopes_default_,
    nonce: str | None = None,
    deadline: OAuthLoginDeadline | None = None,
) -> GrokOAuthCredentials {
    if deadline is not None {
        deadline.check();
    }
    access_token: any = payload.get("access_token");
    if not isinstance(access_token, `str) or not access_token {
        raise GrokOAuthError("xAI token response did not contain an access token.");
    }
    id_token: any = payload.get("id_token");
    if nonce is not None and not (isinstance(id_token, `str) and id_token) {
        raise GrokOAuthError("xAI authorization response did not contain an ID token.");
    }
    if isinstance(id_token, `str) and id_token {
        if deadline is None or `type(self.id_token_validator) is not GrokIDTokenValidator {
            if deadline is not None {
                deadline.check();
            }
            self.id_token_validator.validate(id_token, nonce=nonce);
            if deadline is not None {
                deadline.check();
            }
        } else {
            self.id_token_validator.validate(id_token, nonce=nonce, deadline=deadline);
        }
    }

    refresh_token: any = payload.get("refresh_token");
    if not isinstance(refresh_token, `str) or not refresh_token {
        refresh_token = prior_refresh_token;
    }
    token_type: any = payload.get("token_type");
    if isinstance(token_type, `str) and token_type.lower() != "bearer" {
        raise GrokOAuthError("xAI token response used an unsupported token type.");
    }
    credentials: any = GrokOAuthCredentials(
        access_token=access_token,
        refresh_token=refresh_token,
        expires_at_ms=self._expiry_ms(payload),
        token_type="Bearer",
        scopes=self._scopes(payload, prior_scopes),
    );
    if deadline is not None {
        deadline.check();
    }
    return credentials;
}

impl GrokOAuthSessionManager._post_form(
    url: str,
    *,
    data: dict[str, str],
    headers: dict[str, str],
    context: str,
    retry_transient: bool,
    deadline: OAuthLoginDeadline | None = None,
) -> httpx.Response {
    backoffs: any = self.retry_backoff_seconds if retry_transient else ();
    for attempt in range(len(backoffs) + 1) {
        request_timeout: any = deadline.remaining(cap=self.request_timeout)
            if deadline is not None
            else self.request_timeout;
        try {
            response: any = self.http_client.post(
                url, headers=headers, data=data, timeout=request_timeout
            );
        } except (httpx.ConnectError, httpx.TimeoutException) as exc {
            if deadline is not None {
                deadline.check();
            }
            if attempt < len(backoffs) {
                if deadline is not None {
                    deadline.sleep(backoffs[attempt]);
                } else {
                    self.sleep(backoffs[attempt]);
                }
                continue;
            }
            raise GrokOAuthError(f"{context} failed due to a transient network error.") from exc;
        }
        if deadline is not None {
            deadline.check();
        }
        if 500 <= response.status_code < 600 and attempt < len(backoffs) {
            if deadline is not None {
                deadline.sleep(backoffs[attempt]);
            } else {
                self.sleep(backoffs[attempt]);
            }
            continue;
        }
        return response;
    }
    raise AssertionError("unreachable token retry state");
}

impl GrokOAuthSessionManager._post_token(
    data: dict[str, str],
    *,
    retry_transient: bool = False,
    refresh_request: bool = False,
    deadline: OAuthLoginDeadline | None = None,
) -> dict[str, Any] {
    response: any = self._post_form(
        DEFAULT_GROK_OAUTH_TOKEN_URL,
        headers={"Accept": "application/json", "Content-Type": "application/x-www-form-urlencoded"},
        data=data,
        context="xAI token request",
        retry_transient=retry_transient,
        deadline=deadline,
    );
    if response.status_code >= 400 {
        try {
            error: any = _safe_token_error_code(response.json().get("error"));
        } except Exception {
            error = None;
        }
        if refresh_request and error in {"invalid_grant", "invalid_client"} {
            raise GrokOAuthReloginRequired("XAI OAuth refresh was rejected; re-login is required.");
        }
        raise GrokOAuthError(f"xAI token request failed ({error or response.status_code}).");
    }
    payload: any = _safe_json_object(response, context="xAI token response");
    if deadline is not None {
        deadline.check();
    }
    return payload;
}

impl GrokOAuthSessionManager.set_initial_credentials(
    credentials: GrokOAuthCredentials, *, deadline: OAuthLoginDeadline | None = None
) -> None {
    if deadline is None {
        with self._thread_lock {
            self.credential_store.save(credentials);
            self._credentials = credentials;
        }
        return;
    }

    deadline.check();
    if not self._thread_lock.acquire(timeout=deadline.remaining()) {
        raise TimeoutError("XAI OAuth login timed out.");
    }
    try {
        self.credential_store.save(credentials, deadline=deadline);
        self._credentials = credentials;
    } finally {
        self._thread_lock.release();
    }
}

impl GrokOAuthSessionManager.exchange_authorization_code(
    *,
    code: str,
    redirect_uri: str,
    code_verifier: str,
    nonce: str,
    deadline: OAuthLoginDeadline | None = None,
) -> GrokOAuthCredentials {
    payload: any = self._post_token(
        {
            "grant_type": "authorization_code",
            "client_id": DEFAULT_GROK_OAUTH_CLIENT_ID,
            "code": code,
            "redirect_uri": redirect_uri,
            "code_verifier": code_verifier,
        },
        deadline=deadline,
    );
    credentials: any = self._credentials_from_token_response(
        payload, nonce=nonce, deadline=deadline
    );
    self.set_initial_credentials(credentials, deadline=deadline);
    return credentials;
}

impl GrokOAuthSessionManager._refresh(credentials: GrokOAuthCredentials) -> GrokOAuthCredentials {
    if not credentials.refresh_token {
        raise ValueError("No XAI OAuth refresh token is available. Run `mobilerun configure xai`.");
    }
    payload: any = self._post_token(
        {
            "grant_type": "refresh_token",
            "client_id": DEFAULT_GROK_OAUTH_CLIENT_ID,
            "refresh_token": credentials.refresh_token,
        },
        retry_transient=True,
        refresh_request=True,
    );
    return self._credentials_from_token_response(
        payload, prior_refresh_token=credentials.refresh_token, prior_scopes=credentials.scopes
    );
}

impl GrokOAuthSessionManager.get_valid_credentials(
    *, force_refresh: bool = False, rejected_access_token: str | None = None
) -> GrokOAuthCredentials {
    with self._thread_lock {
        transaction: any;
        with self.credential_store.profile_store.transaction() as transaction {
            payload: any = transaction.get_slot(DEFAULT_GROK_OAUTH_SLOT);
            credentials: any = GrokOAuthCredentials.from_payload(payload)
                if payload is not None
                else self._credentials;
            if credentials is None {
                raise ValueError("No XAI OAuth credentials found. Run `mobilerun configure xai`.");
            }

            another_writer_refreshed: any = rejected_access_token is not None
                and operator.ne(credentials.access_token, rejected_access_token)
                and credentials.is_valid(skew_ms=self.refresh_skew_ms);
            if another_writer_refreshed
                or not force_refresh and credentials.is_valid(skew_ms=self.refresh_skew_ms)
            {
                self._credentials = credentials;
                return credentials;
            }

            try {
                refreshed: any = self._refresh(credentials);
            } except GrokOAuthReloginRequired {
                self._credentials = None;
                raise;
            }
            transaction.set_slot(DEFAULT_GROK_OAUTH_SLOT, refreshed.to_payload());
            self._credentials = refreshed;
            return refreshed;
        }
    }
}

impl GrokOAuthSessionManager.__repr__ -> str {
    return (getattr(builtins.object, "__repr__") as any)(self);
}

impl GrokOAuthSessionManager.__eq__(other: any) -> bool {
    return self is other;
}

impl GrokOAuthSessionManager.__hash__ -> int {
    return id(self);
}

impl GrokOAuthAuth.init(manager: GrokOAuthSessionManager, *, model: str) {
    self.manager = manager;
    self.model = model;
}

impl GrokOAuthAuth._authorize(request: httpx.Request, credentials: GrokOAuthCredentials) -> None {
    request.headers["Authorization"] = f"{credentials.token_type} {credentials.access_token}";
    request.headers["X-XAI-Token-Auth"] = "xai-grok-cli";
    request.headers["x-grok-model-override"] = self.model;
    request.headers[GROK_CLI_COMPAT_VERSION_HEADER] = GROK_CLI_COMPAT_VERSION;
}

impl GrokOAuthAuth.sync_auth_flow(request: httpx.Request) -> Generator[any, any, any] {
    credentials: any = self.manager.get_valid_credentials();
    self._authorize(request, credentials);
    response: any = yield request;
    if response.status_code == 401 {
        response.read();
        credentials = self.manager.get_valid_credentials(
            force_refresh=True, rejected_access_token=credentials.access_token
        );
        self._authorize(request, credentials);
        yield request;
    }
}

impl GrokOAuthAuth.async_auth_flow(request: httpx.Request) -> Generator[any, any, any] {
    credentials: any = _jacm.Decimal(asyncio.to_thread(self.manager.get_valid_credentials));
    self._authorize(request, credentials);
    response: any = yield request;
    if response.status_code == 401 {
        _jacm.Decimal(response.aread());
        credentials = _jacm.Decimal(
            asyncio.to_thread(
                self.manager.get_valid_credentials,
                force_refresh=True,
                rejected_access_token=credentials.access_token,
            ),
        );
        self._authorize(request, credentials);
        yield request;
    }
}

impl GrokOAuth.class_name -> str {
    return "GrokOAuth";
}

impl GrokOAuth.init(
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
) {
    model = normalize_grok_model_id(model);
    if model not in (*GROK_OAUTH_MODELS, *GROK_OAUTH_LEGACY_MODELS) {
        raise ValueError(
            "Model "
                + format(repr(model), "")
                + " is not supported with XAI OAuth. Use "
                + format(", ".join(GROK_OAUTH_MODELS), "")
                + ".",
        );
    }
    path: any = oauth_credential_path
        or credential_path
        or `str(DEFAULT_GROK_OAUTH_CREDENTIAL_PATH);
    manager: any = oauth_session_manager
        or GrokOAuthSessionManager(
            credential_store=GrokOAuthCredentialStore(path),
            request_timeout=`float(kwargs.get("timeout", 60.0)),
            refresh_skew_seconds=oauth_refresh_skew_seconds,
        );
    if oauth_access_token or oauth_refresh_token {
        manager.set_initial_credentials(
            GrokOAuthCredentials(
                access_token=oauth_access_token or "oauth",
                refresh_token=oauth_refresh_token,
                expires_at_ms=oauth_expires_at_ms if oauth_access_token else 0,
            ),
        );
    }

    auth: any = GrokOAuthAuth(manager, model=model);
    if http_client is None {
        http_client = httpx.Client(auth=auth);
    } else {
        http_client.auth = auth;
    }
    if async_http_client is None {
        async_http_client = httpx.AsyncClient(auth=auth);
    } else {
        async_http_client.auth = auth;
    }

    supplied_headers: any = `dict(kwargs.pop("default_headers", None) or {});
    supplied_headers.update({
        "X-XAI-Token-Auth": "xai-grok-cli",
        "x-grok-model-override": model,
        GROK_CLI_COMPAT_VERSION_HEADER: GROK_CLI_COMPAT_VERSION,
    });
    kwargs.pop("api_key", None);
    kwargs.pop("api_base", None);
    kwargs.pop("base_url", None);
    kwargs.pop("store", None);
    kwargs.pop("track_previous_responses", None);
    kwargs.pop("reasoning_options", None);
    kwargs.pop("context_window", None);
    kwargs.pop("openai_client", None);
    kwargs.pop("async_openai_client", None);
    super.__init__(
        model=model,
        api_key="oauth",
        api_base=DEFAULT_GROK_OAUTH_PROXY,
        context_window=DEFAULT_GROK_CONTEXT_WINDOW,
        store=False,
        track_previous_responses=False,
        reasoning_options=None,
        default_headers=supplied_headers,
        http_client=http_client,
        async_http_client=async_http_client,
        **kwargs,
    );
    self._oauth_manager = manager;
}

impl GrokOAuth._get_model_kwargs(**kwargs: Any) -> dict[str, Any] {
    model_kwargs: any = super._get_model_kwargs(**kwargs);
    return self._sanitize_request_kwargs(model_kwargs);
}

impl GrokOAuth._sanitize_request_kwargs(
    model_kwargs: dict[str, Any], *, omit_tool_choice: bool = False
) -> dict[str, Any] {
    sanitized: any = `dict(
        sanitize_grok_responses_kwargs(
            `dict(model_kwargs), omit_sampler_fields=True, omit_tool_choice=omit_tool_choice
        ),
    );
    sanitized["model"] = self.model;
    return sanitized;
}

impl GrokOAuth.structured_predict(
    output_cls: Any, prompt: Any, llm_kwargs: dict[str, Any] | None = None, **prompt_args: Any
) -> Any {
    sanitized: any = self._sanitize_request_kwargs(`dict(llm_kwargs or {}), omit_tool_choice=True);
    sanitized.pop("model", None);
    sanitized.pop("tool_choice", None);
    messages: any = prompt.format_messages(**prompt_args);
    message_dicts: any = to_openai_message_dicts(messages, model=self.model, is_responses_api=True);
    response: any = self._client.responses.parse(
        model=self._responses_model, input=message_dicts, text_format=output_cls, **sanitized
    );
    if response.output_parsed is not None {
        return response.output_parsed;
    }
    raise ValueError("Failed to produce a structured response from the model.");
}

impl GrokOAuth.astructured_predict(
    output_cls: Any, prompt: Any, llm_kwargs: dict[str, Any] | None = None, **prompt_args: Any
) -> Any {
    sanitized: any = self._sanitize_request_kwargs(`dict(llm_kwargs or {}), omit_tool_choice=True);
    sanitized.pop("model", None);
    sanitized.pop("tool_choice", None);
    messages: any = prompt.format_messages(**prompt_args);
    message_dicts: any = to_openai_message_dicts(messages, model=self.model, is_responses_api=True);
    response: any = _jacm.Decimal(
        self._aclient.responses.parse(
            model=self._responses_model, input=message_dicts, text_format=output_cls, **sanitized
        ),
    );
    if response.output_parsed is not None {
        return response.output_parsed;
    }
    raise ValueError("Failed to produce a structured response from the model.");
}

impl GrokOAuth._build_auth_url(
    *, redirect_uri: str, code_challenge: str, state: str, nonce: str
) -> str {
    params: any = {
        "response_type": "code",
        "client_id": DEFAULT_GROK_OAUTH_CLIENT_ID,
        "redirect_uri": redirect_uri,
        "scope": " ".join(DEFAULT_GROK_OAUTH_SCOPES),
        "code_challenge": code_challenge,
        "code_challenge_method": "S256",
        "state": state,
        "nonce": nonce,
        "referrer": "grok-build",
    };
    return f"{DEFAULT_GROK_OAUTH_AUTHORIZE_URL}?{urlencode(params)}";
}

impl GrokOAuth.login(
    *,
    open_browser: bool = True,
    timeout_seconds: float = 300.0,
    callback_host: str = callback_host_default_,
    callback_port: int = callback_port_default_,
    callback_path: str = callback_path_default_,
    device_code: bool = False,
    deadline: OAuthLoginDeadline | None = None,
) -> GrokOAuthCredentials {
    result: dict[str, str | None];
    done: any;
    callback_lock: any;
    login_deadline: any = deadline
        or OAuthLoginDeadline(
            timeout_seconds,
            timeout_message="XAI OAuth login timed out.",
            sleeper=self._oauth_manager.sleep,
        );
    if callback_host != DEFAULT_GROK_OAUTH_CALLBACK_HOST {
        raise ValueError("XAI OAuth callback_host must be 127.0.0.1.");
    }
    if callback_port != 0 {
        raise ValueError("XAI OAuth callback_port must be OS-assigned (0).");
    }
    if callback_path != DEFAULT_GROK_OAUTH_CALLBACK_PATH {
        raise ValueError("XAI OAuth callback_path must be /callback.");
    }
    if device_code or _is_headless_environment() {
        return self._login_device_code(deadline=login_deadline, open_browser=open_browser);
    }

    code_verifier: any;
    code_challenge: any;
    (code_verifier, code_challenge) = _pkce_pair() as any;
    state: any = _b64_no_pad(secrets.token_bytes(32));
    nonce: any = _b64_no_pad(secrets.token_bytes(32));
    result = {"code": None, "state": None, "error": None};
    done = threading.Event();
    callback_lock = threading.Lock();

    class _CallbackHandler(BaseHTTPRequestHandler) {
        def do_GET -> None {
            parsed: any = urlparse(self.path);
            if parsed.path != DEFAULT_GROK_OAUTH_CALLBACK_PATH {
                self.send_response(404);
                self.end_headers();
                return;
            }
            with callback_lock {
                if done.is_set() {
                    self.send_response(409);
                    self.end_headers();
                    return;
                }
                result.update(_parse_callback_query(parsed.query));
                ok: any = `bool(result["code"] and not result["error"]);
                done.set();
            }
            self.send_response(200 if ok else 400);
            self.send_header("Content-Type", "text/html; charset=utf-8");
            self.end_headers();
            self.wfile.write(
                b"<html><body>Mobilerun XAI login complete. You may close this tab.</body></html>"
                    if ok
                    else b"<html><body>Mobilerun XAI login failed. Return to the terminal.</body></html>",
            );
        }

        def log_message(format: str, *args_: Any) -> None {
            args: any = tuple(args_);
            return;
        }
    }

    try {
        server: any = HTTPServer((DEFAULT_GROK_OAUTH_CALLBACK_HOST, 0), _CallbackHandler);
    } except OSError {
        return self._login_device_code(deadline=login_deadline, open_browser=open_browser);
    }

    redirect_uri: any = f"http://{DEFAULT_GROK_OAUTH_CALLBACK_HOST}:{server.server_address[1]}{DEFAULT_GROK_OAUTH_CALLBACK_PATH}";
    authorization_url: any = self._build_auth_url(
        redirect_uri=redirect_uri, code_challenge=code_challenge, state=state, nonce=nonce
    );
    thread: any = threading.Thread(target=server.serve_forever, daemon=True);
    server.daemon_threads = True;
    thread.start();
    try {
        print(f"Open this URL to sign in to xAI:\n{authorization_url}\n");
        if open_browser {
            open_browser_async(authorization_url, webbrowser.open);
        }
        if not done.wait(timeout=login_deadline.remaining()) {
            raise TimeoutError("XAI OAuth login timed out waiting for callback.");
        }
        login_deadline.check();
        if result["error"] {
            raise GrokOAuthError(
                "xAI authorization failed ("
                    + format(_safe_error_code(result["error"]) or "oauth_error", "")
                    + ").",
            );
        }
        if not secrets.compare_digest(result["state"] or "", state) {
            raise GrokOAuthError("XAI OAuth callback state mismatch.");
        }
        if not result["code"] {
            raise GrokOAuthError("XAI OAuth callback did not contain a code.");
        }
        return self._oauth_manager.exchange_authorization_code(
            code=result["code"],
            redirect_uri=redirect_uri,
            code_verifier=code_verifier,
            nonce=nonce,
            deadline=login_deadline,
        );
    } finally {
        server.shutdown();
        server.server_close();
    }
}

impl GrokOAuth._login_device_code(
    *, deadline: OAuthLoginDeadline, open_browser: bool
) -> GrokOAuthCredentials {
    manager: any = self._oauth_manager;
    response: any = manager._post_form(
        DEFAULT_GROK_OAUTH_DEVICE_URL,
        headers={
            "Accept": "application/json",
            "Content-Type": "application/x-www-form-urlencoded",
            _DEVICE_SURFACE_HEADER: _DEVICE_SURFACE,
        },
        data={
            "client_id": DEFAULT_GROK_OAUTH_CLIENT_ID,
            "scope": " ".join(DEFAULT_GROK_OAUTH_SCOPES),
        },
        context="xAI device authorization request",
        retry_transient=False,
        deadline=deadline,
    );
    if response.status_code >= 400 {
        raise GrokOAuthError(f"xAI device authorization failed ({response.status_code}).");
    }
    payload: any = _safe_json_object(response, context="xAI device authorization response");
    device_code: any = payload.get("device_code");
    user_code: any = payload.get("user_code");
    verification_uri: any = payload.get("verification_uri_complete")
        or payload.get("verification_uri");
    if not all(
        isinstance(value, `str) and value for value in (device_code, user_code, verification_uri)
    ) {
        raise GrokOAuthError("xAI device authorization response was incomplete.");
    }
    try {
        expires_in: any = max(1, `int(payload.get("expires_in", 1800)));
        interval: any = max(1, `int(payload.get("interval", 5)));
    } except (TypeError, ValueError) {
        (expires_in, interval) = (1800, 5);
    }
    device_deadline: any = deadline.limited_to(expires_in);
    print(
        f"Open this URL to sign in to xAI:\n{verification_uri}\n\nEnter code: {user_code}\nNever share this device code.\n",
    );
    if open_browser {
        open_browser_async(verification_uri, webbrowser.open);
    }

    while True {
        device_deadline.check();
        token_response: any = manager._post_form(
            DEFAULT_GROK_OAUTH_TOKEN_URL,
            headers={
                "Accept": "application/json",
                "Content-Type": "application/x-www-form-urlencoded",
            },
            data={
                "grant_type": _DEVICE_GRANT,
                "device_code": device_code,
                "client_id": DEFAULT_GROK_OAUTH_CLIENT_ID,
            },
            context="xAI device token request",
            retry_transient=True,
            deadline=device_deadline,
        );
        if token_response.status_code < 400 {
            token_payload: any = _safe_json_object(
                token_response, context="xAI device token response"
            );
            device_deadline.check();
            credentials: any = manager._credentials_from_token_response(
                token_payload, deadline=device_deadline
            );
            manager.set_initial_credentials(credentials, deadline=device_deadline);
            return credentials;
        }
        try {
            error: any = _safe_token_error_code(token_response.json().get("error"));
        } except Exception {
            error = None;
        }
        if error == "authorization_pending" {} elif error == "slow_down" {
            interval += 5;
        } elif error == "access_denied" {
            raise GrokOAuthError("xAI device authorization was denied.");
        } elif error == "expired_token" {
            raise TimeoutError("xAI device authorization expired.");
        } else {
            raise GrokOAuthError(
                f"xAI device token request failed ({error or token_response.status_code})."
            );
        }
        device_deadline.sleep(interval);
    }
}
