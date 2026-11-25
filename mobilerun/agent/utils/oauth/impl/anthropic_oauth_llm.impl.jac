impl AnthropicOAuthStreamError.init(
    message: builtins.str, *, error_type: Optional[builtins.str] = None, request: Any = None
) {
    super.__init__(message, request=request);
    self.error_type = error_type;
    self.status_code = _ERROR_TYPE_STATUS.get(error_type or "");
}

impl _iter_sse_events(response: Any) -> Generator[any, any, any] {
    event_name: Optional[builtins.str];
    data_lines: builtins.list[builtins.str];
    event_name = None;
    data_lines = [];

    def dispatch -> Optional[Dict[builtins.str, Any]] {
        if not data_lines {
            return None;
        }
        event: any = json.loads("\n".join(data_lines));
        if isinstance(event, `dict) and event_name and "type" not in event {
            event["type"] = event_name;
        }
        return event;
    }

    for raw_line in response.iter_lines() {
        line: any = raw_line.decode("utf-8") if isinstance(raw_line, `bytes) else raw_line;
        if not line {
            event: any = dispatch();
            if event is not None {
                yield event;
            }
            (event_name, data_lines) = (None, []);
            continue;
        }
        (field, _, value) = line.partition(":") as any;
        value = value[1:] if value.startswith(" ") else value;
        if field == "event" {
            event_name = value;
        } elif field == "data" {
            data_lines.append(value);
        }
    }
    event = dispatch();
    if event is not None {
        yield event;
    }
}

impl _b64_no_pad(raw: builtins.bytes) -> builtins.str {
    return base64.urlsafe_b64encode(raw).decode("utf-8").rstrip("=");
}

impl _pkce_pair -> builtins.tuple[builtins.str, builtins.str] {
    verifier: any = _b64_no_pad(secrets.token_bytes(64));
    challenge: any = _b64_no_pad(hashlib.sha256(verifier.encode("utf-8")).digest());
    return (verifier, challenge);
}

impl _is_headless_environment -> builtins.bool {
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

impl _normalize_manual_code(raw: builtins.str, expected_state: builtins.str) -> builtins.str {
    value: any = raw.strip();
    if not value {
        return value;
    }

    first_token: any = value.split()[0];

    if "error=" in first_token or "code=" in first_token {
        parsed: any = urlparse(first_token);
        params: any = parse_qs(parsed.query);
        error: any = params.get("error", [None])[0];
        if error {
            desc: any = params.get("error_description", [error])[0];
            raise RuntimeError(f"OAuth error: {desc}");
        }
        code: any = params.get("code", [None])[0];
        state_from_url: any = params.get("state", [None])[0];
        if state_from_url and state_from_url != expected_state {
            raise RuntimeError("OAuth manual code state mismatch.");
        }
        if isinstance(code, `str) and code {
            return code;
        }
    }

    if "#" in first_token {
        (code_part, fragment) = first_token.split("#", 1) as any;
        if fragment and fragment != expected_state {
            raise RuntimeError("OAuth manual code state mismatch.");
        }
        return code_part;
    }

    return first_token;
}

impl AnthropicOAuthLLM.init(
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
) {
    super.__init__(
        model=model,
        max_tokens=max_tokens,
        temperature=temperature,
        timeout=timeout,
        access_token=access_token,
        refresh_token=refresh_token,
        client_id=client_id,
        authorize_url=authorize_url,
        token_url=token_url,
        login_scope=login_scope,
        refresh_scope=refresh_scope,
        refresh_buffer_seconds=refresh_buffer_seconds,
        credential_path=credential_path,
        api_base=api_base,
        anthropic_version=anthropic_version,
        oauth_beta=oauth_beta,
        user_agent=user_agent,
        billing_header_mode=billing_header_mode,
        cc_version=cc_version,
        cc_entrypoint=cc_entrypoint,
        cch_value=cch_value,
        inject_identifier=inject_identifier,
        identifier_text=identifier_text,
        additional_kwargs=additional_kwargs or {},
        callback_manager=callback_manager or CallbackManager([]),
    );
    self._session = requests.Session();
    self._cached_access_token = access_token;
    self._cached_refresh_token = refresh_token;
    if credential_path {
        self._load_credentials_from_file(credential_path);
    }
}

impl AnthropicOAuthLLM.class_name -> builtins.str {
    return "AnthropicOAuthLLM";
}

impl AnthropicOAuthLLM._load_credentials_from_file(credential_path: builtins.str) -> None {
    path: any = Path(credential_path).expanduser();
    if not path.exists() {
        return;
    }
    try {
        payload: any = json.loads(path.read_text(encoding="utf-8"));
    } except Exception {
        return;
    }

    nested: any = payload.get("claudeAiOauth");
    if isinstance(nested, `dict) {
        file_access: any = nested.get("accessToken");
        file_refresh: any = nested.get("refreshToken");
        expires_at: any = nested.get("expiresAt");
    } else {
        file_access = payload.get("access_token");
        file_refresh = payload.get("refresh_token");
        expires_at = payload.get("expires_at");
    }

    if not self._cached_access_token and isinstance(file_access, `str) {
        self._cached_access_token = file_access;
    }
    if not self._cached_refresh_token and isinstance(file_refresh, `str) {
        self._cached_refresh_token = file_refresh;
    }
    if isinstance(expires_at, (`int, `float)) {
        self._access_token_expiry = `float(expires_at) / 1000.0;
    }
}

impl AnthropicOAuthLLM._persist_credentials(*, deadline: OAuthLoginDeadline | None = None) -> None {
    if not self.credential_path {
        return;
    }
    path: any = Path(self.credential_path).expanduser();
    AuthProfileStore(path).update_slot(
        "claudeAiOauth",
        {
            "accessToken": self._cached_access_token,
            "refreshToken": self._cached_refresh_token,
            "expiresAt": `int(self._access_token_expiry * 1000)
                if self._access_token_expiry
                else None,
            "scopes": self.refresh_scope.split(),
        },
        lock_timeout=deadline.remaining() if deadline is not None else None,
        before_commit=deadline.check if deadline is not None else None,
    );
}

impl AnthropicOAuthLLM._token_headers -> Dict[builtins.str, builtins.str] {
    headers: any = {
        "Content-Type": "application/json",
        "Accept": "application/json",
        "anthropic-beta": self.oauth_beta,
    };
    if self.user_agent {
        headers["User-Agent"] = self.user_agent;
    }
    return headers;
}

impl AnthropicOAuthLLM._access_token_is_stale -> builtins.bool {
    if not self._access_token_expiry {
        return False;
    }
    return operator.ge(time.time(), self._access_token_expiry - self.refresh_buffer_seconds);
}

impl AnthropicOAuthLLM._refresh_access_token -> builtins.str {
    refresh_token: any = self._cached_refresh_token or self.refresh_token;
    if not refresh_token {
        raise ValueError(
            "No refresh token available. Provide `refresh_token` or credentials file."
        );
    }

    res: any = self._session.post(
        self.token_url,
        headers=self._token_headers(),
        json={
            "grant_type": "refresh_token",
            "refresh_token": refresh_token,
            "client_id": self.client_id,
            "scope": self.refresh_scope,
        },
        timeout=self.timeout,
    );
    res.raise_for_status();
    data: any = res.json();

    access_token: any = data.get("access_token");
    if not isinstance(access_token, `str) or not access_token {
        raise RuntimeError(f"Token refresh succeeded but no access_token returned: {data}");
    }

    expires_in: any = data.get("expires_in", 28800);
    try {
        expires_in_s: any = `int(expires_in);
    } except (TypeError, ValueError) {
        expires_in_s = 28800;
    }

    self._cached_access_token = access_token;
    self._cached_refresh_token = data.get("refresh_token") or refresh_token;
    self._access_token_expiry = time.time() + expires_in_s;
    self._persist_credentials();
    return access_token;
}

impl AnthropicOAuthLLM._exchange_authorization_code(
    *,
    code: builtins.str,
    redirect_uri: builtins.str,
    code_verifier: builtins.str,
    state: builtins.str,
    expires_in: Optional[builtins.int] = None,
    deadline: OAuthLoginDeadline | None = None,
) -> builtins.str {
    request_body: Dict[builtins.str, Any] = {
        "grant_type": "authorization_code",
        "code": code,
        "redirect_uri": redirect_uri,
        "client_id": self.client_id,
        "code_verifier": code_verifier,
        "state": state,
    };
    if expires_in is not None {
        request_body["expires_in"] = expires_in;
    }

    request_timeout: any = self.timeout
        if deadline is None
        else deadline.remaining(cap=self.timeout);
    res: any = self._session.post(
        self.token_url, headers=self._token_headers(), json=request_body, timeout=request_timeout
    );
    if deadline is not None {
        deadline.check();
    }
    res.raise_for_status();
    data: any = res.json();
    if deadline is not None {
        deadline.check();
    }

    access_token: any = data.get("access_token");
    if not isinstance(access_token, `str) or not access_token {
        raise RuntimeError(f"OAuth code exchange succeeded but no access_token returned: {data}");
    }

    refresh_token: any = data.get("refresh_token");
    cached_refresh_token: any = refresh_token
        if isinstance(refresh_token, `str) and refresh_token
        else self._cached_refresh_token;

    expires_in = data.get("expires_in", 28800);
    try {
        expires_in_s: any = `int(expires_in);
    } except (TypeError, ValueError) {
        expires_in_s = 28800;
    }

    if deadline is not None {
        deadline.check();
    }
    previous: any = (
        self._cached_access_token,
        self._cached_refresh_token,
        self._access_token_expiry,
    );
    self._cached_refresh_token = cached_refresh_token;
    self._cached_access_token = access_token;
    self._access_token_expiry = time.time() + expires_in_s;
    try {
        self._persist_credentials(deadline=deadline);
    } except BaseException {
        items_: any = list(previous as any);
        if len(items_) != 3 {
            raise ValueError(
                f"too many values to unpack (expected 3, got {len(items_)})"
                    if len(items_) > 3
                    else f"not enough values to unpack (expected 3, got {len(items_)})",
            );
        }
        self._cached_access_token = items_[0];
        self._cached_refresh_token = items_[1];
        self._access_token_expiry = items_[2];
        raise;
    }
    return access_token;
}

impl AnthropicOAuthLLM._build_auth_url(
    *, redirect_uri: builtins.str, code_challenge: builtins.str, state: builtins.str
) -> builtins.str {
    query: any = {
        "client_id": self.client_id,
        "redirect_uri": redirect_uri,
        "response_type": "code",
        "scope": self.login_scope,
        "code_challenge": code_challenge,
        "code_challenge_method": "S256",
        "state": state,
    };
    if "/cai/oauth/authorize" in self.authorize_url {
        query["code"] = "true";
    }
    return f"{self.authorize_url}?{urlencode(query)}";
}

impl AnthropicOAuthLLM.login(
    *,
    open_browser: builtins.bool = True,
    timeout_seconds: builtins.float = 300.0,
    callback_host: builtins.str = "127.0.0.1",
    callback_port: builtins.int = 0,
    callback_path: builtins.str = "/callback",
    expires_in: Optional[builtins.int] = None,
    deadline: OAuthLoginDeadline | None = None,
) -> builtins.str {
    result: Dict[builtins.str, Optional[builtins.str]];
    active_deadline: any = deadline or OAuthLoginDeadline(timeout_seconds);
    active_deadline.check();
    use_headless: any = _is_headless_environment()
        or (
            os.environ.get("MOBILERUN_OAUTH_MANUAL")
            or os.environ.get("DROIDRUN_OAUTH_MANUAL")
            or ""
        ).lower()
            in ("1", "true", "yes");
    if use_headless {
        return self.login_headless(
            open_browser=open_browser,
            timeout_seconds=timeout_seconds,
            expires_in=expires_in,
            deadline=active_deadline,
        );
    }
    result = {"code": None, "state": None, "error": None};
    done = threading.Event();
    callback_lock = threading.Lock();

    (code_verifier, code_challenge) = _pkce_pair() as any;
    state: any = _b64_no_pad(secrets.token_bytes(32));
    original_authorize_url: any = self.authorize_url;

    if "/cai/oauth/authorize" not in self.authorize_url {
        self.authorize_url = DEFAULT_MODERN_AUTHORIZE_URL;
    }

    class _OAuthHandler(BaseHTTPRequestHandler) {
        def do_GET -> None {
            parsed: any = urlparse(self.path);
            if parsed.path != callback_path {
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
                params: any = parse_qs(parsed.query);
                result["code"] = params.get("code", [None])[0];
                result["state"] = params.get("state", [None])[0];
                result["error"] = params.get("error", [None])[0];
                ok: any = result["code"] is not None and result["error"] is None;
                done.set();
            }
            self.send_response(200 if ok else 400);
            self.send_header("Content-Type", "text/html; charset=utf-8");
            self.end_headers();
            if ok {
                self.wfile.write(
                    b"<html><body><h3>Login complete. You can close this tab.</h3></body></html>"
                );
            } else {
                self.wfile.write(
                    b"<html><body><h3>Login failed. Return to your terminal.</h3></body></html>"
                );
            }
        }

        def log_message(format: builtins.str, *args_: Any) -> None {
            args: any = tuple(args_);
            return;
        }
    }

    try {
        httpd: any = HTTPServer((callback_host, callback_port), _OAuthHandler);
    } except OSError as exc {
        self.authorize_url = original_authorize_url;
        print(
            f"Could not bind callback server on {callback_host}:{callback_port} ({exc}). Falling back to headless code entry.",
        );
        return self.login_headless(
            open_browser=open_browser,
            timeout_seconds=timeout_seconds,
            expires_in=expires_in,
            deadline=active_deadline,
        );
    }

    active_deadline.check();
    actual_port: any = httpd.server_address[1];
    redirect_uri: any = f"http://localhost:{actual_port}{callback_path}";
    auth_url: any = self._build_auth_url(
        redirect_uri=redirect_uri, code_challenge=code_challenge, state=state
    );

    server_thread: any = threading.Thread(target=httpd.serve_forever, daemon=True);
    httpd.daemon_threads = True;
    server_thread.start();

    try {
        print(f"Open this URL to login:\n{auth_url}\n");
        if open_browser {
            open_browser_async(auth_url, webbrowser.open);
        }

        if not done.wait(timeout=active_deadline.remaining()) {
            raise TimeoutError("OAuth login timed out before callback was received.");
        }
        active_deadline.check();

        if result["error"] {
            raise RuntimeError("OAuth callback returned error: " + format(result["error"], ""));
        }
        if result["state"] != state {
            raise RuntimeError("OAuth callback state mismatch.");
        }
        if not result["code"] {
            raise RuntimeError("OAuth callback did not include an authorization code.");
        }

        access_token: any = self._exchange_authorization_code(
            code=result["code"],
            redirect_uri=redirect_uri,
            code_verifier=code_verifier,
            state=state,
            expires_in=expires_in,
            deadline=active_deadline,
        );
    } finally {
        self.authorize_url = original_authorize_url;
        httpd.shutdown();
        httpd.server_close();
    }
    return access_token;
}

impl AnthropicOAuthLLM.login_headless(
    *,
    open_browser: builtins.bool = False,
    timeout_seconds: builtins.float = 300.0,
    input_fn: Any = input_fn_default_,
    expires_in: Optional[builtins.int] = None,
    deadline: OAuthLoginDeadline | None = None,
) -> builtins.str {
    input_queue: queue.Queue[Optional[builtins.str]];
    active_deadline: any = deadline or OAuthLoginDeadline(timeout_seconds);
    active_deadline.check();

    (code_verifier, code_challenge) = _pkce_pair() as any;
    state: any = _b64_no_pad(secrets.token_bytes(32));
    redirect_uri: any = "https://platform.claude.com/oauth/code/callback";
    original_authorize_url: any = self.authorize_url;

    if "/cai/oauth/authorize" not in self.authorize_url {
        self.authorize_url = DEFAULT_MODERN_AUTHORIZE_URL;
    }

    auth_url: any = self._build_auth_url(
        redirect_uri=redirect_uri, code_challenge=code_challenge, state=state
    );

    try {
        print(
            f"\nSign in with your Anthropic account:\n\n1. Open this link in your browser:\n   {auth_url}\n\n2. Complete sign-in, then paste the authorization code shown on the page.\n",
        );
        if open_browser {
            open_browser_async(auth_url, webbrowser.open);
        }

        input_queue = queue.Queue();
        stop = threading.Event();
        need_more = threading.Event();

        def _reader -> None {
            for _ in range(_MAX_CODE_ATTEMPTS) {
                need_more.wait();
                need_more.clear();
                if stop.is_set() {
                    return;
                }
                try {
                    input_queue.put(`str(input_fn("Enter the authorization code: ")));
                } except (EOFError, OSError) {
                    input_queue.put(None);
                    return;
                }
            }
        }

        threading.Thread(target=_reader, daemon=True).start();

        try {
            for attempt in range(_MAX_CODE_ATTEMPTS) {
                need_more.set();

                try {
                    raw: any = input_queue.get(timeout=active_deadline.remaining());
                } except queue.Empty {
                    raise TimeoutError("OAuth login timed out.") from None;
                }
                active_deadline.check();

                if raw is None {
                    raise RuntimeError("Login failed — stdin closed.");
                }
                if not raw.strip() {
                    if attempt == 0 {
                        print("No code entered. Try again.");
                        continue;
                    }
                    raise RuntimeError("Login failed.") from None;
                }
                try {
                    code: any = _normalize_manual_code(raw, state);
                } except Exception {
                    if attempt == 0 {
                        print("Invalid code. Try again.");
                        continue;
                    }
                    raise RuntimeError("Login failed.") from None;
                }
                if code {
                    return self._exchange_authorization_code(
                        code=code,
                        redirect_uri=redirect_uri,
                        code_verifier=code_verifier,
                        state=state,
                        expires_in=expires_in,
                        deadline=active_deadline,
                    );
                }
                if attempt == 0 {
                    print("Invalid code. Try again.");
                    continue;
                }
                raise RuntimeError("Login failed.");
            }
            raise RuntimeError("Login failed.");
        } finally {
            stop.set();
            need_more.set();
        }
    } finally {
        self.authorize_url = original_authorize_url;
    }
}

impl AnthropicOAuthLLM._resolve_access_token -> builtins.str {
    env_access_token: any = os.environ.get("ANTHROPIC_OAUTH_TOKEN");
    if env_access_token {
        return env_access_token;
    }

    if self._cached_access_token and not self._access_token_is_stale() {
        return self._cached_access_token;
    }

    if self._cached_access_token and not self._cached_refresh_token {
        return self._cached_access_token;
    }

    if self._cached_refresh_token or self.refresh_token {
        return self._refresh_access_token();
    }

    raise ValueError(
        "No OAuth token available. Provide `access_token`, `refresh_token`, or a valid credential_path.",
    );
}

impl AnthropicOAuthLLM._extract_text(payload: Dict[builtins.str, Any]) -> builtins.str {
    blocks: any = payload.get("content");
    if not isinstance(blocks, `list) {
        return "";
    }
    texts: builtins.list[builtins.str] = [];
    for block in blocks {
        if isinstance(block, `dict) and block.get("type") == "text" and block.get("text") {
            texts.append(`str(block["text"]));
        }
    }
    return "\n".join(texts);
}

impl AnthropicOAuthLLM._image_media_type(raw: builtins.bytes) -> builtins.str {
    if raw.startswith(b"\xff\xd8") {
        return "image/jpeg";
    }
    if raw.startswith(b"RIFF") and raw[8:12] == b"WEBP" {
        return "image/webp";
    }
    if raw.startswith(b"GIF8") {
        return "image/gif";
    }
    return "image/png";
}

impl AnthropicOAuthLLM._content_blocks(
    message: ChatMessage
) -> builtins.list[builtins.dict[builtins.str, Any]] {
    blocks: builtins.list[builtins.dict[builtins.str, Any]] = [];
    for block in message.blocks or [] {
        if isinstance(block, TextBlock) {
            if block.text {
                blocks.append({"type": "text", "text": block.text});
            }
        } elif isinstance(block, ImageBlock) {
            raw: any = block.resolve_image(as_base64=False).read();
            blocks.append({
                "type": "image",
                "source": {
                    "type": "base64",
                    "media_type": cls._image_media_type(raw),
                    "data": base64.b64encode(raw).decode("ascii"),
                },
            });
        }
    }
    return blocks;
}

impl AnthropicOAuthLLM._to_provider_messages(
    messages: Sequence[ChatMessage]
) -> builtins.tuple[builtins.list[builtins.dict[builtins.str, Any]], builtins.list[builtins.str]] {
    provider_messages: builtins.list[builtins.dict[builtins.str, Any]] = [];
    system_lines: builtins.list[builtins.str] = [];

    for message in messages {
        role: any = message.role.value;
        blocks: any = self._content_blocks(message);
        if role == MessageRole.SYSTEM.value {
            system_lines.extend(block["text"] for block in blocks if block["type"] == "text");
            continue;
        }
        if role not in {MessageRole.USER.value, MessageRole.ASSISTANT.value} {
            role = MessageRole.USER.value;
        }
        if `any(operator.eq(block["type"], "image") for block in blocks) {
            provider_messages.append({"role": role, "content": blocks});
        } else {
            content: any = message.content if isinstance(message.content, `str) else "";
            provider_messages.append({"role": role, "content": content});
        }
    }

    if not provider_messages {
        provider_messages.append({"role": MessageRole.USER.value, "content": ""});
    }
    return (provider_messages, system_lines);
}

impl AnthropicOAuthLLM._billing_header_text -> builtins.str {
    return f"x-anthropic-billing-header: cc_version={self.cc_version}; cc_entrypoint={self.cc_entrypoint}; cch={self.cch_value};";
}

impl AnthropicOAuthLLM._use_billing_header(model_id: builtins.str) -> builtins.bool {
    if self.billing_header_mode == "always" {
        return True;
    }
    if self.billing_header_mode == "never" {
        return False;
    }
    return not model_id.startswith("claude-haiku");
}

impl AnthropicOAuthLLM._supports_temperature(model_id: builtins.str) -> builtins.bool {
    return not anthropic_model_omits_sampling_params(model_id);
}

impl AnthropicOAuthLLM._system_blocks(
    user_system_lines: Sequence[builtins.str], model_id: builtins.str
) -> builtins.list[builtins.dict[builtins.str, builtins.str]] {
    blocks: builtins.list[builtins.dict[builtins.str, builtins.str]] = [];
    if self._use_billing_header(model_id) {
        blocks.append({"type": "text", "text": self._billing_header_text()});
    }
    if self.inject_identifier and self.identifier_text {
        blocks.append({"type": "text", "text": self.identifier_text});
    }
    for line in user_system_lines {
        if line {
            blocks.append({"type": "text", "text": line});
        }
    }
    return blocks;
}

impl AnthropicOAuthLLM._sanitize_request_kwargs(
    kwargs: Dict[builtins.str, Any]
) -> Dict[builtins.str, Any] {
    return {
        key: value
        for (key, value) in kwargs.items()
        if key not in _IGNORED_REQUEST_KWARGS and value is not None
    };
}

impl AnthropicOAuthLLM._messages_request(
    messages: Sequence[ChatMessage], kwargs: Dict[builtins.str, Any]
) -> builtins.tuple[builtins.str, Dict[builtins.str, builtins.str], Dict[builtins.str, Any]] {
    (provider_messages, system_lines) = self._to_provider_messages(messages) as any;
    token: any = self._resolve_access_token();
    request_kwargs: any = self._sanitize_request_kwargs(kwargs);

    payload: Dict[builtins.str, Any] = {"model": self.model, "messages": provider_messages};
    if self._supports_temperature(self.model) {
        payload["temperature"] = self.temperature;
    }
    if self.max_tokens is not None {
        payload["max_tokens"] = self.max_tokens;
    }
    system_blocks: any = self._system_blocks(system_lines, self.model);
    if system_blocks {
        payload["system"] = system_blocks;
    }

    payload.update(self.additional_kwargs);
    payload.update(request_kwargs);
    strip_anthropic_sampling_params(payload);

    headers: any = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json",
        "anthropic-version": self.anthropic_version,
        "anthropic-beta": self.oauth_beta,
    };
    if self.user_agent {
        headers["User-Agent"] = self.user_agent;
    }

    return (format(self.api_base.rstrip("/"), "") + "/v1/messages", headers, payload);
}

impl AnthropicOAuthLLM._chat_response(
    data: Dict[builtins.str, Any], delta: Optional[builtins.str] = None
) -> ChatResponse {
    assistant: any = ChatMessage(
        role=MessageRole.ASSISTANT,
        content=cls._extract_text(data),
        additional_kwargs={"content_blocks": data.get("content", [])},
    );
    return ChatResponse(
        message=assistant,
        raw=data,
        delta=delta,
        additional_kwargs={
            "id": data.get("id"),
            "usage": data.get("usage"),
            "stop_reason": data.get("stop_reason"),
        },
    );
}

impl AnthropicOAuthLLM.chat(messages: Sequence[ChatMessage], **kwargs: Any) -> ChatResponse {
    (url, headers, payload) = self._messages_request(messages, kwargs) as any;
    res: any = self._session.post(url, headers=headers, json=payload, timeout=self.timeout);
    res.raise_for_status();
    return self._chat_response(res.json());
}

impl AnthropicOAuthLLM.complete(
    prompt: builtins.str, formatted: builtins.bool = False, **kwargs: Any
) -> CompletionResponse {
    del formatted;
    resp: any = self.chat(
        [ChatMessage(role=MessageRole.USER, content=prompt)],
        **self._sanitize_request_kwargs(kwargs),
    );
    return CompletionResponse(
        text=resp.message.content or "", raw=resp.raw, additional_kwargs=resp.additional_kwargs
    );
}

impl AnthropicOAuthLLM.stream_chat(
    messages: Sequence[ChatMessage], **kwargs: Any
) -> ChatResponseGen {
    (url, headers, payload) = self._messages_request(messages, kwargs) as any;
    payload["stream"] = True;
    res: any = self._session.post(
        url, headers=headers, json=payload, timeout=self.timeout, stream=True
    );
    try {
        res.raise_for_status();
    } except requests.HTTPError {
        with contextlib.suppress(requests.RequestException) {
            _: any = res.content;
        }
        res.close();
        raise;
    }
    stream: any = self._stream_responses(res);
    weakref.finalize(stream, res.close);
    return stream;
}

impl AnthropicOAuthLLM._stream_responses(res: Any) -> Generator[any, any, any] {
    message: Dict[builtins.str, Any] = {};
    blocks: Dict[builtins.int, Dict[builtins.str, Any]] = {};
    tool_input_json: Dict[builtins.int, builtins.str] = {};
    text: any = "";
    try {
        for event in _iter_sse_events(res) {
            kind: any = event.get("type");
            if kind == "message_start" {
                message = `dict(event.get("message") or {});
                message["usage"] = `dict(message.get("usage") or {});
            } elif kind == "content_block_start" {
                blocks[event["index"]] = `dict(event.get("content_block") or {});
            } elif kind == "content_block_delta" {
                index: any = event["index"];
                block: any = blocks[index];
                delta: any = event.get("delta") or {};
                delta_type: any = delta.get("type");
                if delta_type == "text_delta" and delta.get("text") {
                    piece: any = delta["text"];
                    if text and not block.get("text") {
                        piece = "\n" + piece;
                    }
                    block["text"] = block.get("text", "") + delta["text"];
                    text += piece;
                    yield ChatResponse(
                        message=ChatMessage(role=MessageRole.ASSISTANT, content=text),
                        delta=piece,
                        raw=event,
                    );
                } elif delta_type == "thinking_delta" {
                    block["thinking"] = block.get("thinking", "") + delta.get("thinking", "");
                } elif delta_type == "signature_delta" {
                    block["signature"] = delta.get("signature", "");
                } elif delta_type == "input_json_delta" {
                    tool_input_json[index] = tool_input_json.get(index, "")
                        + delta.get("partial_json", "");
                } elif delta_type == "citations_delta" {
                    block.setdefault("citations", []).append(delta.get("citation"));
                }
            } elif kind == "content_block_stop" {
                partial_json: any = tool_input_json.pop(event["index"], "");
                if partial_json {
                    blocks[event["index"]]["input"] = json.loads(partial_json);
                }
            } elif kind == "message_delta" {
                message.update(event.get("delta") or {});
                usage: any = message.setdefault("usage", {});
                for (key, value) in (event.get("usage") or {}).items() {
                    if value is not None {
                        usage[key] = value;
                    }
                }
            } elif kind == "message_stop" {
                message["content"] = [blocks[index] for index in sorted(blocks)];
                yield self._chat_response(message, delta="");
                return;
            } elif kind == "error" {
                error: any = event.get("error") or {};
                error_type: any = error.get("type");
                raise AnthropicOAuthStreamError(
                    "Anthropic stream error "
                        + format(error_type, "")
                        + ": "
                        + format(error.get("message"), ""),
                    error_type=error_type,
                    request=getattr(res, "request", None),
                );
            }
        }
        raise AnthropicOAuthStreamError(
            "Anthropic stream ended before message_stop.", request=getattr(res, "request", None)
        );
    } finally {
        res.close();
    }
}

impl AnthropicOAuthLLM.stream_complete(
    prompt: builtins.str, formatted: builtins.bool = False, **kwargs: Any
) -> CompletionResponseGen {
    del formatted;
    chat_stream = self.stream_chat(
        [ChatMessage(role=MessageRole.USER, content=prompt)],
        **self._sanitize_request_kwargs(kwargs),
    );

    def gen -> Generator[any, any, any] {
        for chunk in chat_stream {
            yield CompletionResponse(
                text=chunk.message.content or "",
                delta=chunk.delta,
                raw=chunk.raw,
                additional_kwargs=chunk.additional_kwargs,
            );
        }
    }

    return gen();
}
