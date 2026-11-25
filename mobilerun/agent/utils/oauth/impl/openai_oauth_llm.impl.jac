impl _aclose_events(events: Any) -> None {
    close: any = getattr(events, "aclose", None) or getattr(events, "close", None);
    if callable(close) {
        result: any = close();
        if inspect.isawaitable(result) {
            await result;
        }
    }
}

impl _is_headless_environment -> bool {
    if os.environ.get("SSH_CONNECTION") or os.environ.get("SSH_TTY") {
        return True;
    }
    if os.environ.get("WSL_DISTRO_NAME") {
        return True;
    }
    comptime if target_().os == "linux" {
        if not os.environ.get("DISPLAY") and not os.environ.get("WAYLAND_DISPLAY") {
            return True;
        }
    }
    return False;
}

impl _tls_preflight(
    issuer: str, timeout: float = 5.0, *, deadline: OAuthLoginDeadline | None = None
) -> None {
    probe_url: any = format(issuer.rstrip("/"), "") + "/oauth/authorize";
    try {
        request_timeout: any = deadline.remaining(cap=timeout) if deadline else timeout;
        httpx.head(probe_url, follow_redirects=False, timeout=request_timeout);
        if deadline {
            deadline.check();
        }
    } except httpx.ConnectError as exc {
        if deadline {
            deadline.check();
        }
        err_str = `str(exc).lower();
        tls_indicators: any = (
            "certificate",
            "ssl",
            "tls",
            "unable_to_get_issuer_cert",
            "cert_has_expired",
            "self_signed_cert",
            "verify_leaf_signature",
            "altname_invalid",
        );
        if `any(indicator in err_str for indicator in tls_indicators) {
            raise RuntimeError(
                f"TLS certificate error connecting to {probe_url}: {exc}\nPossible fixes:\n  - Update CA certificates (e.g. `sudo update-ca-certificates` on Linux, `brew postinstall ca-certificates` on macOS)\n  - Update OpenSSL (e.g. `brew postinstall openssl@3`)\n  - Check if a corporate proxy is intercepting HTTPS traffic",
            ) from exc;
        }
        print(
            f"Warning: Could not connect to {probe_url}: {exc}\nThe login flow may fail if there is a DNS or firewall issue.",
        );
    } except httpx.TimeoutException {
        if deadline {
            deadline.check();
        }
        print(
            f"Warning: Connection to {probe_url} timed out.\nThe login flow may fail if there is a network issue.",
        );
    } except Exception as exc {
        if deadline {
            deadline.check();
        }
        print(f"Warning: TLS preflight check encountered an error: {exc}");
    }
}

impl _request_device_code(
    issuer: str,
    client_id: str,
    http_client: Optional[httpx.Client] = None,
    request_timeout: float = 15.0,
    retries: int = 2,
    *,
    deadline: OAuthLoginDeadline | None = None,
) -> dict[str, any] {
    url: any = format(issuer.rstrip("/"), "") + "/api/accounts/deviceauth/usercode";
    post: any = http_client.post if http_client is not None else httpx.post;
    for attempt in range(1 + retries) {
        try {
            timeout: any = deadline.remaining(cap=request_timeout) if deadline else request_timeout;
            response: any = post(
                url,
                headers={"Content-Type": "application/json"},
                json={"client_id": client_id},
                timeout=timeout,
            );
            if deadline {
                deadline.check();
            }
        } except (httpx.ConnectError, httpx.TimeoutException) {
            if deadline {
                deadline.check();
            }
            if attempt < retries {
                if deadline {
                    deadline.sleep(2);
                } else {
                    time.sleep(2);
                }
                continue;
            }
            raise;
        }
        if response.status_code == 404 {
            raise RuntimeError("Device code login is not enabled for this server.");
        }
        if response.status_code >= 500 and attempt < retries {
            if deadline {
                deadline.sleep(2);
            } else {
                time.sleep(2);
            }
            continue;
        }
        response.raise_for_status();
        payload: any = response.json();
        if deadline {
            deadline.check();
        }
        return payload;
    }
    raise RuntimeError("Device code request failed after retries.");
}

impl _poll_device_code(
    issuer: str,
    device_auth_id: str,
    user_code: str,
    interval: int,
    http_client: Optional[httpx.Client] = None,
    request_timeout: float = 15.0,
    timeout_seconds: float = timeout_seconds_default_,
    *,
    deadline: OAuthLoginDeadline | None = None,
) -> dict[str, any] {
    url: any = format(issuer.rstrip("/"), "") + "/api/accounts/deviceauth/token";
    login_deadline: any = deadline
        or OAuthLoginDeadline(
            min(timeout_seconds, _DEVICE_CODE_TIMEOUT),
            timeout_message=_OPENAI_LOGIN_TIMEOUT_MESSAGE,
        );
    post: any = http_client.post if http_client is not None else httpx.post;

    last_error: Optional[str] = None;

    try {
        while True {
            try {
                response: any = post(
                    url,
                    headers={"Content-Type": "application/json"},
                    json={"device_auth_id": device_auth_id, "user_code": user_code},
                    timeout=login_deadline.remaining(cap=request_timeout),
                );
                login_deadline.check();
            } except (httpx.ConnectError, httpx.TimeoutException) as exc {
                login_deadline.check();
                last_error = `str(exc);
                login_deadline.sleep(interval);
                continue;
            }
            if response.status_code == 200 {
                payload: any = response.json();
                login_deadline.check();
                return payload;
            }
            if response.status_code in (403, 404) {
                login_deadline.sleep(interval);
                continue;
            }
            if response.status_code >= 500 {
                last_error = f"HTTP {response.status_code}";
                login_deadline.sleep(interval);
                continue;
            }
            response.raise_for_status();
        }
    } except TimeoutError {
        if last_error {
            raise TimeoutError(
                f"{_OPENAI_LOGIN_TIMEOUT_MESSAGE} Last response: {last_error}."
            ) from None;
        }
        raise;
    }
}

impl OpenAIOAuthCredentials.from_payload(payload: Dict[str, Any]) -> "OpenAIOAuthCredentials" {
    access_token: any = payload.get("access") or payload.get("access_token");
    if not access_token {
        raise ValueError("OpenAI OAuth payload missing access token.");
    }

    refresh_token: any = payload.get("refresh") or payload.get("refresh_token");
    account_id: any = payload.get("account_id");

    raw_expires: any = payload.get("expires");
    if raw_expires is None {
        expires_at_ms: Optional[int] = None;
    } else {
        try {
            expires_at_ms = `int(raw_expires);
        } except (TypeError, ValueError) {
            expires_at_ms = None;
        }
    }

    return cls(
        access_token=`str(access_token),
        refresh_token=`str(refresh_token) if refresh_token else None,
        expires_at_ms=expires_at_ms,
        account_id=`str(account_id) if account_id else None,
    );
}

impl OpenAIOAuthCredentials.to_dict -> Dict[str, Any] {
    return {
        "type": "oauth",
        "provider": "openai-chatgpt",
        "access": self.access_token,
        "refresh": self.refresh_token,
        "expires": self.expires_at_ms,
        "account_id": self.account_id,
    };
}

impl OpenAIOAuthCredentials.is_valid(skew_ms: int = 60000) -> bool {
    if not self.access_token {
        return False;
    }
    if self.expires_at_ms is None {
        return True;
    }
    return operator.lt(`int(time.time() * 1000) + skew_ms, self.expires_at_ms);
}

impl OpenAIOAuthCredentialStore.init(path: str | Path = path_default_) {
    self.path = Path(path).expanduser();
    self._store = AuthProfileStore(self.path);
}

impl OpenAIOAuthCredentialStore.load -> Optional[OpenAIOAuthCredentials] {
    if not self.path.exists() {
        return None;
    }

    raw: any = self._store.read_profile();
    nested: any = raw.get(self._NESTED_KEY);
    payload: any = nested if isinstance(nested, `dict) else raw;
    try {
        return OpenAIOAuthCredentials.from_payload(payload);
    } except ValueError {
        return None;
    }
}

impl OpenAIOAuthCredentialStore.save(
    credentials: OpenAIOAuthCredentials, *, deadline: OAuthLoginDeadline | None = None
) -> None {
    self._store.update_slot(
        self._NESTED_KEY,
        credentials.to_dict(),
        lock_timeout=deadline.remaining() if deadline is not None else None,
        before_commit=deadline.check if deadline is not None else None,
    );
}

impl OpenAIOAuthSessionManager.init(
    *,
    issuer: str = issuer_default_,
    client_id: str = client_id_default_,
    credential_store: Optional[OpenAIOAuthCredentialStore] = None,
    request_timeout: float = 15.0,
    http_client: Optional[httpx.Client] = None,
) {
    self.issuer = issuer.rstrip("/");
    self.client_id = client_id;
    self.request_timeout = request_timeout;
    self.credential_store = credential_store or OpenAIOAuthCredentialStore();
    self.http_client = http_client;
    self._lock = threading.Lock();
    self._credentials = None;
}

impl OpenAIOAuthSessionManager._jwt_claims(token: str) -> Dict[str, Any] {
    parts: any = token.split(".");
    if len(parts) != 3 {
        return {};
    }

    payload: any = parts[1];
    padding: any = "=" * (-len(payload) % 4);
    try {
        raw: any = base64.urlsafe_b64decode(payload + padding).decode("utf-8");
        claims: any = json.loads(raw);
        return claims if isinstance(claims, `dict) else {};
    } except Exception {
        return {};
    }
}

impl OpenAIOAuthSessionManager._extract_account_id(token: str) -> Optional[str] {
    claims: any = cls._jwt_claims(token);

    auth_claims: any = claims.get("https://api.openai.com/auth");
    if isinstance(auth_claims, `dict) {
        nested: any = auth_claims.get("chatgpt_account_id");
        if isinstance(nested, `str) and nested {
            return nested;
        }
    }

    direct: any = claims.get("chatgpt_account_id");
    if isinstance(direct, `str) and direct {
        return direct;
    }

    orgs: any = claims.get("organizations");
    if isinstance(orgs, `list) and orgs {
        first: any = orgs[0];
        if isinstance(first, `dict) {
            org_id: any = first.get("id");
            if isinstance(org_id, `str) and org_id {
                return org_id;
            }
        }
    }

    return None;
}

impl OpenAIOAuthSessionManager._compute_expiry_ms(
    token: str, expires_in: Optional[Any]
) -> Optional[int] {
    if expires_in is not None {
        try {
            return `int(time.time() * 1000) + `int(expires_in) * 1000;
        } except (TypeError, ValueError) {}
    }

    claims: any = cls._jwt_claims(token);
    exp: any = claims.get("exp");
    if isinstance(exp, (`int, `float)) {
        return `int(exp * 1000);
    }
    return None;
}

impl OpenAIOAuthSessionManager.set_initial_credentials(
    credentials: OpenAIOAuthCredentials, *, deadline: OAuthLoginDeadline | None = None
) -> None {
    if deadline is None {
        with self._lock {
            self._credentials = credentials;
            self.credential_store.save(credentials);
        }
        return;
    }

    deadline.check();
    if not self._lock.acquire(timeout=deadline.remaining()) {
        raise TimeoutError(_OPENAI_LOGIN_TIMEOUT_MESSAGE);
    }
    try {
        deadline.check();
        self.credential_store.save(credentials, deadline=deadline);
        self._credentials = credentials;
    } finally {
        self._lock.release();
    }
}

impl OpenAIOAuthSessionManager._load_cached_credentials -> Optional[OpenAIOAuthCredentials] {
    if self._credentials is not None {
        return self._credentials;
    }

    cached: any = self.credential_store.load();
    if cached is not None {
        self._credentials = cached;
    }
    return cached;
}

impl OpenAIOAuthSessionManager._refresh(refresh_token: str) -> OpenAIOAuthCredentials {
    data: any = {
        "grant_type": "refresh_token",
        "refresh_token": refresh_token,
        "client_id": self.client_id,
    };

    if self.http_client is not None {
        response: any = self.http_client.post(
            f"{self.issuer}/oauth/token",
            headers={"Content-Type": "application/json"},
            json=data,
            timeout=self.request_timeout,
        );
    } else {
        response = httpx.post(
            f"{self.issuer}/oauth/token",
            headers={"Content-Type": "application/json"},
            json=data,
            timeout=self.request_timeout,
        );
    }

    response.raise_for_status();
    payload: any = response.json();

    access: any = payload.get("access_token");
    if not isinstance(access, `str) or not access {
        raise RuntimeError("OpenAI OAuth refresh response missing access_token.");
    }

    new_refresh: any = payload.get("refresh_token");
    if not isinstance(new_refresh, `str) or not new_refresh {
        new_refresh = refresh_token;
    }

    expires_at_ms: any = self._compute_expiry_ms(access, payload.get("expires_in"));
    id_or_access: any = payload.get("id_token")
        if isinstance(payload.get("id_token"), `str)
        else access;
    account_id: any = self._extract_account_id(id_or_access);

    return OpenAIOAuthCredentials(
        access_token=access,
        refresh_token=new_refresh,
        expires_at_ms=expires_at_ms,
        account_id=account_id,
    );
}

impl OpenAIOAuthSessionManager.get_valid_credentials(
    skew_ms: int = 60000
) -> OpenAIOAuthCredentials {
    with self._lock {
        cached: any = self._load_cached_credentials();
        if cached is not None and cached.is_valid(skew_ms=skew_ms) {
            return cached;
        }

        if cached is None or not cached.refresh_token {
            raise ValueError(
                "No valid OpenAI OAuth credentials found. Provide a refresh token or a cached credential file.",
            );
        }

        refreshed: any = self._refresh(cached.refresh_token);
        self._credentials = refreshed;
        self.credential_store.save(refreshed);
        return refreshed;
    }
}

impl OpenAIOAuthSessionManager.exchange_authorization_code(
    *, code: str, redirect_uri: str, code_verifier: str, deadline: OAuthLoginDeadline | None = None
) -> OpenAIOAuthCredentials {
    data: any = {
        "grant_type": "authorization_code",
        "code": code,
        "redirect_uri": redirect_uri,
        "client_id": self.client_id,
        "code_verifier": code_verifier,
    };

    request_timeout: any = deadline.remaining(cap=self.request_timeout)
        if deadline
        else self.request_timeout;
    if self.http_client is not None {
        response: any = self.http_client.post(
            f"{self.issuer}/oauth/token",
            headers={"Content-Type": "application/x-www-form-urlencoded"},
            data=data,
            timeout=request_timeout,
        );
    } else {
        response = httpx.post(
            f"{self.issuer}/oauth/token",
            headers={"Content-Type": "application/x-www-form-urlencoded"},
            data=data,
            timeout=request_timeout,
        );
    }

    if deadline {
        deadline.check();
    }
    response.raise_for_status();
    payload: any = response.json();
    if deadline {
        deadline.check();
    }

    access: any = payload.get("access_token");
    if not isinstance(access, `str) or not access {
        raise RuntimeError("OpenAI OAuth code exchange response missing access_token.");
    }

    refresh: any = payload.get("refresh_token");
    credentials: any = OpenAIOAuthCredentials(
        access_token=access,
        refresh_token=refresh if isinstance(refresh, `str) and refresh else None,
        expires_at_ms=self._compute_expiry_ms(access, payload.get("expires_in")),
        account_id=self._extract_account_id(
            payload.get("id_token") if isinstance(payload.get("id_token"), `str) else access
        ),
    );
    self.set_initial_credentials(credentials, deadline=deadline);
    return credentials;
}

impl OpenAIOAuth.class_name -> str {
    return "OpenAIOAuth";
}

impl OpenAIOAuth._resolve_model_name(
    *, auth_model: str, custom_model: Optional[str], model: Optional[str]
) -> str {
    if custom_model and custom_model.strip() {
        selected_model: any = custom_model.strip();
    } elif model and model.strip() {
        selected_model = model.strip();
    } else {
        selected_model = auth_model.strip() or OPENAI_OAUTH_DEFAULT_MODEL;
    }

    normalized_model: any = normalize_model_id_for_variant("openai", "oauth", selected_model);
    if normalized_model != selected_model {
        return normalized_model;
    }
    if not (custom_model and custom_model.strip()) and not (model and model.strip()) {
        if "/" in selected_model {
            return selected_model.split("/", 1)[1].strip();
        }
    }

    return selected_model;
}

impl OpenAIOAuth._build_auth_url(
    *,
    issuer: str,
    client_id: str,
    redirect_uri: str,
    code_challenge: str,
    state: str,
    scope: str = scope_default_,
) -> str {
    query: any = {
        "response_type": "code",
        "client_id": client_id,
        "redirect_uri": redirect_uri,
        "scope": scope,
        "code_challenge": code_challenge,
        "code_challenge_method": "S256",
        "id_token_add_organizations": "true",
        "codex_cli_simplified_flow": "true",
        "state": state,
        "originator": "codex_cli_rs",
    };
    return format(issuer.rstrip("/"), "") + "/oauth/authorize?" + format(urlencode(query), "");
}

impl OpenAIOAuth.init(
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
) {
    resolved_model: any = self._resolve_model_name(
        auth_model=auth_model, custom_model=custom_model, model=model
    );
    if resolved_model in OPENAI_OAUTH_UNSUPPORTED_MODELS {
        raise ValueError(
            f"Model '{resolved_model}' is not supported with OpenAI OAuth ChatGPT-account credentials. Use '{OPENAI_OAUTH_DEFAULT_MODEL}' or re-run `mobilerun configure openai`.",
        );
    }

    seed_api_key: any = oauth_access_token or kwargs.pop("api_key", None) or "oauth";
    kwargs.setdefault("api_base", DEFAULT_OPENAI_API_BASE);
    kwargs.setdefault("pydantic_program_mode", PydanticProgramMode.LLM);
    super.__init__(model=resolved_model, api_key=seed_api_key, **kwargs);
    builtins.object.__setattr__(
        self, "_oauth_refresh_skew_ms", max(0, `int(oauth_refresh_skew_seconds)) * 1000
    );
    builtins.object.__setattr__(self, "_use_chatgpt_account_header", use_chatgpt_account_header);
    builtins.object.__setattr__(self, "_oauth_account_id", oauth_account_id);
    builtins.object.__setattr__(self, "_active_access_token", None);
    builtins.object.__setattr__(self, "_responses_api_base", DEFAULT_CODEX_API_BASE);

    store: any = OpenAIOAuthCredentialStore(
        oauth_credential_path or DEFAULT_OPENAI_OAUTH_CREDENTIAL_PATH
    );
    self._oauth_manager = OpenAIOAuthSessionManager(
        issuer=oauth_issuer,
        client_id=oauth_client_id,
        credential_store=store,
        request_timeout=self.timeout,
        http_client=self._http_client,
    );

    if oauth_access_token or oauth_refresh_token {
        self._oauth_manager.set_initial_credentials(
            OpenAIOAuthCredentials(
                access_token=oauth_access_token or seed_api_key,
                refresh_token=oauth_refresh_token,
                expires_at_ms=oauth_expires_at_ms,
                account_id=oauth_account_id,
            ),
        );
    }
}

impl OpenAIOAuth.login(
    *,
    open_browser: bool = True,
    timeout_seconds: float = 300.0,
    callback_host: str = callback_host_default_,
    callback_port: int = callback_port_default_,
    callback_path: str = callback_path_default_,
    redirect_host: str = redirect_host_default_,
    scope: str = scope_default__,
    deadline: OAuthLoginDeadline | None = None,
) -> OpenAIOAuthCredentials {
    login_deadline: any = deadline
        or OAuthLoginDeadline(timeout_seconds, timeout_message=_OPENAI_LOGIN_TIMEOUT_MESSAGE);
    login_deadline.check();
    _tls_preflight(self._oauth_manager.issuer, deadline=login_deadline);
    use_device_code: any = _is_headless_environment()
        or (
            os.environ.get("MOBILERUN_OAUTH_MANUAL")
            or os.environ.get("DROIDRUN_OAUTH_MANUAL")
            or ""
        ).lower()
            in ("1", "true", "yes");
    if use_device_code {
        return self._login_device_code(
            open_browser=open_browser, timeout_seconds=timeout_seconds, deadline=login_deadline
        );
    }
    (code_verifier, code_challenge) = _pkce_pair() as any;
    state: any = _b64_no_pad(secrets.token_bytes(32));

    try {
        callback: any = LoopbackCallback(callback_host, callback_port, callback_path, HTTPServer);
    } except OSError as exc {
        login_deadline.check();
        print(
            f"Could not bind callback server on {callback_host}:{callback_port} ({exc}). Falling back to device code login.",
        );
        return self._login_device_code(
            open_browser=open_browser, timeout_seconds=timeout_seconds, deadline=login_deadline
        );
    }
    login_deadline.check();

    redirect_uri: any = f"http://{redirect_host}:{callback.port()}{callback_path}";
    auth_url: any = self._build_auth_url(
        issuer=self._oauth_manager.issuer,
        client_id=self._oauth_manager.client_id,
        redirect_uri=redirect_uri,
        code_challenge=code_challenge,
        state=state,
        scope=scope,
    );

    callback.serve();

    try {
        print(f"Open this URL to login:\n{auth_url}\n");
        if open_browser {
            open_browser_async(auth_url, webbrowser.open);
        }

        code: any = callback.code(
            login_deadline, state, "OpenAI OAuth login timed out before callback was received."
        );

        creds: any = self._oauth_manager.exchange_authorization_code(
            code=code,
            redirect_uri=redirect_uri,
            code_verifier=code_verifier,
            deadline=login_deadline,
        );
        if creds.account_id {
            builtins.object.__setattr__(self, "_oauth_account_id", creds.account_id);
        }
        return creds;
    } finally {
        callback.close();
    }
}

impl OpenAIOAuth._login_device_code(
    *,
    open_browser: bool = False,
    timeout_seconds: float = timeout_seconds_default__,
    deadline: OAuthLoginDeadline | None = None,
) -> OpenAIOAuthCredentials {
    mgr: any = self._oauth_manager;
    http_client: any = mgr.http_client;
    login_deadline: any = deadline
        or OAuthLoginDeadline(timeout_seconds, timeout_message=_OPENAI_LOGIN_TIMEOUT_MESSAGE);
    login_deadline.check();

    device_resp: any = _request_device_code(
        mgr.issuer,
        mgr.client_id,
        http_client=http_client,
        request_timeout=mgr.request_timeout,
        deadline=login_deadline,
    );
    device_auth_id: any = device_resp.get("device_auth_id");
    if not device_auth_id {
        raise RuntimeError("Device code response missing 'device_auth_id'.");
    }

    user_code: any = device_resp.get("user_code") or device_resp.get("usercode");
    if not user_code {
        raise RuntimeError("Device code response missing 'user_code'.");
    }
    try {
        interval: any = max(1, `int(`str(device_resp.get("interval", "5")).strip()));
    } except (TypeError, ValueError) {
        interval = 5;
    }
    try {
        server_expires: any = `int(device_resp["expires_in"]);
    } except (KeyError, TypeError, ValueError) {
        server_expires = _DEVICE_CODE_TIMEOUT;
    }
    if server_expires <= 0 {
        raise TimeoutError("OpenAI OAuth device authorization expired.");
    }
    device_deadline: any = login_deadline.limited_to(min(_DEVICE_CODE_TIMEOUT, server_expires));
    effective_timeout: any = device_deadline.remaining();
    verification_url: any = device_resp.get("verification_uri")
        or device_resp.get("verification_url")
        or f"{mgr.issuer}/codex/device";

    if effective_timeout >= 60 {
        mins: any = `int(effective_timeout // 60);
        expires_str: any = format(mins, "") + " minute" + format("s" if mins != 1 else "", "");
    } else {
        secs: any = `int(effective_timeout);
        expires_str = format(secs, "") + " second" + format("s" if secs != 1 else "", "");
    }
    print(
        f"\nSign in with your ChatGPT account:\n\n1. Open this link in your browser:\n   {verification_url}\n\n2. Enter this code (expires in {expires_str}):\n   {user_code}\n\nDevice codes are a common phishing target. Never share this code.\n",
    );
    if open_browser {
        open_browser_async(`str(verification_url), webbrowser.open);
    }

    token_resp: any = _poll_device_code(
        mgr.issuer,
        device_auth_id,
        user_code,
        interval,
        http_client=http_client,
        request_timeout=mgr.request_timeout,
        deadline=device_deadline,
    );

    auth_code: any = token_resp.get("authorization_code");
    code_verifier: any = token_resp.get("code_verifier");
    if not auth_code or not code_verifier {
        raise RuntimeError(
            "Device code token response missing required fields ('authorization_code' / 'code_verifier').",
        );
    }

    redirect_uri: any = f"{mgr.issuer}/deviceauth/callback";
    creds: any = self._oauth_manager.exchange_authorization_code(
        code=auth_code,
        redirect_uri=redirect_uri,
        code_verifier=code_verifier,
        deadline=device_deadline,
    );
    if creds.account_id {
        builtins.object.__setattr__(self, "_oauth_account_id", creds.account_id);
    }
    return creds;
}

impl OpenAIOAuth._ensure_access_token -> OpenAIOAuthCredentials {
    creds: any = self._oauth_manager.get_valid_credentials(skew_ms=self._oauth_refresh_skew_ms);

    if self._active_access_token != creds.access_token {
        self._active_access_token = creds.access_token;
        self.api_key = creds.access_token;
        self._client = None;
        self._aclient = None;
    }

    if creds.account_id and not self._oauth_account_id {
        self._oauth_account_id = creds.account_id;
    }

    if self.api_base != self._responses_api_base {
        self.api_base = self._responses_api_base;
        self._client = None;
        self._aclient = None;
    }

    return creds;
}

impl OpenAIOAuth._get_client -> any {
    self._ensure_access_token();
    return super._get_client();
}

impl OpenAIOAuth._get_aclient -> any {
    self._ensure_access_token();
    return super._get_aclient();
}

impl OpenAIOAuth._get_credential_kwargs(is_async: bool = False) -> Dict[str, Any] {
    creds: any = self._ensure_access_token();
    kwargs: any = super._get_credential_kwargs(is_async=is_async);
    kwargs["api_key"] = creds.access_token;

    headers: any = `dict(self.default_headers or {});
    headers.setdefault("originator", "codex_cli_rs");
    headers.setdefault("Accept", "application/json");
    account_id: any = self._oauth_account_id or creds.account_id;
    if self._use_chatgpt_account_header and account_id {
        headers["ChatGPT-Account-Id"] = account_id;
    }
    kwargs["default_headers"] = headers or None;

    return kwargs;
}

impl OpenAIOAuth._resolve_codex_instructions(messages: list[ChatMessage]) -> str {
    system_parts: list[str] = [];
    for msg in messages {
        if msg.role != MessageRole.SYSTEM {
            continue;
        }
        content: any = msg.content;
        if isinstance(content, `str) and content.strip() {
            system_parts.append(content.strip());
        }
    }
    return "\n\n".join(system_parts) if system_parts else "You are a helpful coding assistant.";
}

impl OpenAIOAuth._build_responses_payload(messages: list[ChatMessage]) -> list[dict[str, Any]] {
    non_system_messages: any = [m for m in messages if m.role != MessageRole.SYSTEM];
    try {
        payload_raw: any = to_openai_message_dicts(
            non_system_messages, model=self.model, is_responses_api=True, store=False
        );
    } except TypeError {
        payload_raw = to_openai_message_dicts(
            non_system_messages, model=self.model, is_responses_api=True
        );
    }

    if isinstance(payload_raw, `str) {
        payload: list[dict[str, Any]] = [{"role": "user", "content": payload_raw}];
    } else {
        payload = payload_raw;
    }

    normalized: list[dict[str, Any]] = [];
    for item in payload {
        role: any = `str(item.get("role", "user"));
        content: any = item.get("content");

        if isinstance(content, `str) {
            text_type: any = "input_text" if role == "user" else "output_text";
            normalized.append({**item, "content": [{"type": text_type, "text": content}]});
            continue;
        }

        if isinstance(content, `list) {
            fixed: list[Any] = [];
            for `entry in content {
                if isinstance(`entry, `dict)
                    and `entry.get("type") == "text"
                    and isinstance(`entry.get("text"), `str)
                {
                    text_type = "input_text" if role == "user" else "output_text";
                    fixed.append({**`entry, "type": text_type});
                } else {
                    fixed.append(`entry);
                }
            }
            normalized.append({**item, "content": fixed});
            continue;
        }

        normalized.append(item);
    }

    return normalized;
}

impl OpenAIOAuth._sanitize_reasoning_kwargs(runtime_kwargs: dict[str, Any]) -> dict[str, Any] {
    merged: dict[str, Any] = {};
    if self.reasoning_effort is not None {
        merged["reasoning"] = {"effort": self.reasoning_effort};
    }
    merged.update((self.additional_kwargs or {}) as dict[str, Any]);
    merged.update(runtime_kwargs);

    if self.model in OPENAI_GPT6_MODELS {
        if self.model == _GPT_6_ASTRA_MODEL {
            merged.setdefault("reasoning", {"effort": OPENAI_ASTRA_DEFAULT_REASONING_EFFORT});
        }
        for key in _GPT_6_UNSUPPORTED_PARAMS {
            merged.pop(key, None);
        }
        `include: any = merged.get("include");
        if isinstance(`include, (`list, `tuple)) {
            filtered_include: any = [
                value
                for value in `include
                if value != _GPT_6_UNSUPPORTED_INCLUDE
            ];
            merged["include"] = filtered_include or None;
        }
    }

    supported_efforts: any = OPENAI_REASONING_EFFORTS.get(self.model);
    if supported_efforts is None {
        return merged;
    }
    reasoning: any = merged.get("reasoning");
    if reasoning is not None and not isinstance(reasoning, `dict) {
        raise ValueError(
            f"{self.model} reasoning must be a mapping with an optional 'effort' value."
        );
    }
    effort: any = reasoning.get("effort") if isinstance(reasoning, `dict) else None;
    if effort is not None and effort not in supported_efforts {
        supported: any = ", ".join(sorted(supported_efforts));
        raise ValueError(
            f"{self.model} does not support reasoning effort {effort!r}; use one of: {supported}."
        );
    }
    return merged;
}

impl OpenAIOAuth._collect_stream_text_sync(events: Any) -> tuple[str, Any, list[ToolCallBlock]] {
    text_parts: list[str] = [];
    final_response: Any = None;
    tool_calls: list[ToolCallBlock] = [];
    try {
        for event in events {
            tool_calls.extend(self._done_function_calls(event));
            event_type: any = getattr(event, "type", "");
            if event_type == "response.output_text.delta" {
                delta: any = getattr(event, "delta", None);
                if isinstance(delta, `str) and delta {
                    text_parts.append(delta);
                }
            } elif event_type == "response.completed" {
                final_response = getattr(event, "response", None);
            }
        }
    } finally {
        close: any = getattr(events, "close", None);
        if callable(close) {
            close();
        }
    }

    collected: any = "".join(text_parts);
    if collected {
        return (collected, final_response, tool_calls);
    }

    if final_response is not None {
        final_text: any = getattr(final_response, "output_text", None);
        if isinstance(final_text, `str) and final_text {
            return (final_text, final_response, tool_calls);
        }
    }

    return (collected, final_response, tool_calls);
}

impl OpenAIOAuth._collect_stream_text_async(events: Any) -> tuple[str, Any, list[ToolCallBlock]] {
    text_parts: list[str] = [];
    final_response: Any = None;
    tool_calls: list[ToolCallBlock] = [];
    try {
        async for event in (events) {
            tool_calls.extend(self._done_function_calls(event));
            event_type: any = getattr(event, "type", "");
            if event_type == "response.output_text.delta" {
                delta: any = getattr(event, "delta", None);
                if isinstance(delta, `str) and delta {
                    text_parts.append(delta);
                }
            } elif event_type == "response.completed" {
                final_response = getattr(event, "response", None);
            }
        }
    } finally {
        (await _aclose_events(events));
    }

    collected: any = "".join(text_parts);
    if collected {
        return (collected, final_response, tool_calls);
    }

    if final_response is not None {
        final_text: any = getattr(final_response, "output_text", None);
        if isinstance(final_text, `str) and final_text {
            return (final_text, final_response, tool_calls);
        }
    }

    return (collected, final_response, tool_calls);
}

impl OpenAIOAuth._is_not_found_error(exc: Exception) -> bool {
    status_code: any = getattr(exc, "status_code", None);
    if status_code == 404 {
        return True;
    }
    response: any = getattr(exc, "response", None);
    if response is not None and getattr(response, "status_code", None) == 404 {
        return True;
    }
    return "404" in `str(exc) and "not found" in `str(exc).lower();
}

impl OpenAIOAuth._codex_request_kwargs(
    messages: list[ChatMessage], kwargs: dict[str, Any]
) -> dict[str, Any] {
    kwargs = self._sanitize_reasoning_kwargs(kwargs);
    request_kwargs: dict[str, Any] = {
        "model": self.model,
        "instructions": self._resolve_codex_instructions(messages),
        "tools": [],
        "tool_choice": "auto",
        "parallel_tool_calls": True,
        "store": False,
        "stream": True,
    };
    for key in (
        "reasoning",
        "include",
        "service_tier",
        "text",
        "tools",
        "tool_choice",
        "parallel_tool_calls",
    ) {
        if key in kwargs and kwargs[key] is not None {
            request_kwargs[key] = kwargs[key];
        }
    }
    return request_kwargs;
}

impl OpenAIOAuth._function_call_blocks(items: Any) -> list[ToolCallBlock] {
    return [
        ToolCallBlock(tool_name=item.name, tool_call_id=item.call_id, tool_kwargs=item.arguments)
        for item in items or []
        if getattr(item, "type", None) == "function_call"
    ];
}

impl OpenAIOAuth._response_message(
    text: str, response: Any, tool_calls: list[ToolCallBlock]
) -> ChatMessage {
    tool_calls = tool_calls or cls._function_call_blocks(getattr(response, "output", None));
    if not tool_calls {
        return ChatMessage(role=MessageRole.ASSISTANT, content=text);
    }
    blocks: any = [TextBlock(text=text)] if text else [];
    return ChatMessage(role=MessageRole.ASSISTANT, blocks=[*blocks, *tool_calls]);
}

impl OpenAIOAuth._done_function_calls(event: Any) -> list[ToolCallBlock] {
    if getattr(event, "type", "") != "response.output_item.done" {
        return [];
    }
    return cls._function_call_blocks([getattr(event, "item", None)]);
}

impl OpenAIOAuth._should_fall_back_to_backend_api(exc: Exception) -> bool {
    return operator.eq(self._responses_api_base, DEFAULT_CODEX_API_BASE)
        and self._is_not_found_error(exc);
}

impl OpenAIOAuth._use_backend_api_base -> None {
    self._responses_api_base = DEFAULT_BACKEND_API_BASE;
    self.api_base = self._responses_api_base;
    self._client = None;
    self._aclient = None;
}

impl OpenAIOAuth._stream_chunk(text: str, delta: str, raw: Any = None) -> ChatResponse {
    return ChatResponse(
        message=ChatMessage(role=MessageRole.ASSISTANT, content=text),
        delta=delta,
        raw=raw,
        additional_kwargs={},
    );
}

impl OpenAIOAuth._stream_event_chunk(event: Any, text: str) -> ChatResponse | None {
    event_type: any = getattr(event, "type", "");
    if event_type == "response.output_text.delta" {
        delta: any = getattr(event, "delta", None);
        if isinstance(delta, `str) and delta {
            return cls._stream_chunk(text + delta, delta);
        }
    } elif event_type == "response.completed" {
        response: any = getattr(event, "response", None);
        final_text: any = getattr(response, "output_text", None);
        if not text and isinstance(final_text, `str) and final_text {
            return cls._stream_chunk(final_text, final_text, raw=response);
        }
        return cls._stream_chunk(text, "", raw=response);
    }
    return None;
}

impl OpenAIOAuth._chat(messages: list[ChatMessage], **kwargs: Any) -> ChatResponse {
    request_kwargs: any = self._codex_request_kwargs(messages, kwargs);
    self._ensure_access_token();
    client: any = self._get_client();
    payload: any = self._build_responses_payload(messages);

    try {
        events: any = client.responses.create(input=payload, **request_kwargs);
        (text, response, tool_calls) = self._collect_stream_text_sync(events) as any;
    } except Exception as exc {
        if self._should_fall_back_to_backend_api(exc) {
            self._use_backend_api_base();
            client = self._get_client();
            events = client.responses.create(input=payload, **request_kwargs);
            (text, response, tool_calls) = self._collect_stream_text_sync(events) as any;
        } else {
            raise;
        }
    }

    return ChatResponse(
        message=self._response_message(text, response, tool_calls),
        raw=response,
        additional_kwargs={},
    );
}

impl OpenAIOAuth._achat(messages: list[ChatMessage], **kwargs: Any) -> ChatResponse {
    request_kwargs: any = self._codex_request_kwargs(messages, kwargs);
    self._ensure_access_token();
    aclient: any = self._get_aclient();
    payload: any = self._build_responses_payload(messages);

    try {
        events: any = (await aclient.responses.create(input=payload, **request_kwargs));
        (text, response, tool_calls) = (await self._collect_stream_text_async(events)) as any;
    } except Exception as exc {
        if self._should_fall_back_to_backend_api(exc) {
            self._use_backend_api_base();
            aclient = self._get_aclient();
            events = (await aclient.responses.create(input=payload, **request_kwargs));
            (text, response, tool_calls) = (await self._collect_stream_text_async(events)) as any;
        } else {
            raise;
        }
    }

    return ChatResponse(
        message=self._response_message(text, response, tool_calls),
        raw=response,
        additional_kwargs={},
    );
}

impl OpenAIOAuth._stream_chat(messages: list[ChatMessage], **kwargs: Any) -> ChatResponseGen {
    request_kwargs: any = self._codex_request_kwargs(messages, kwargs);
    self._ensure_access_token();
    payload: any = self._build_responses_payload(messages);
    try {
        events = self._get_client().responses.create(input=payload, **request_kwargs);
    } except Exception as exc {
        if not self._should_fall_back_to_backend_api(exc) {
            raise;
        }
        self._use_backend_api_base();
        events = self._get_client().responses.create(input=payload, **request_kwargs);
    }

    def gen -> Generator[any, any, any] {
        text: any = "";
        tool_calls: list[ToolCallBlock] = [];
        try {
            for event in events {
                tool_calls.extend(self._done_function_calls(event));
                chunk: any = self._stream_event_chunk(event, text);
                if chunk is not None {
                    text = chunk.message.content or "";
                    if getattr(event, "type", "") == "response.completed" {
                        chunk.message = self._response_message(text, chunk.raw, tool_calls);
                    }
                    yield chunk;
                }
            }
        } finally {
            close: any = getattr(events, "close", None);
            if callable(close) {
                close();
            }
        }
    }

    return gen();
}

impl OpenAIOAuth._astream_chat(messages: list[ChatMessage], **kwargs: Any) -> ChatResponseAsyncGen {
    request_kwargs: any = self._codex_request_kwargs(messages, kwargs);
    self._ensure_access_token();
    payload: any = self._build_responses_payload(messages);
    try {
        events: any = (await self._get_aclient().responses.create(input=payload, **request_kwargs));
    } except Exception as exc {
        if not self._should_fall_back_to_backend_api(exc) {
            raise;
        }
        self._use_backend_api_base();
        events = (await self._get_aclient().responses.create(input=payload, **request_kwargs));
    }

    return self._astream_chunks(events);
}

impl OpenAIOAuth._astream_chunks(events: Any) -> AsyncIterator[any] {
    text: any = "";
    tool_calls: list[ToolCallBlock] = [];
    try {
        async for event in (events) {
            tool_calls.extend(self._done_function_calls(event));
            chunk: any = self._stream_event_chunk(event, text);
            if chunk is not None {
                text = chunk.message.content or "";
                if getattr(event, "type", "") == "response.completed" {
                    chunk.message = self._response_message(text, chunk.raw, tool_calls);
                }
                yield chunk;
            }
        }
    } finally {
        (await _aclose_events(events));
    }
}
