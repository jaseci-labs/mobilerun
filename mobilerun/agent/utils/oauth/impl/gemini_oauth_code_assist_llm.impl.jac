impl _antigravity_user_agent -> builtins.str {
    os_name: any = {"win32": "windows"}.get(sys.platform, sys.platform);
    arch: any = platform.machine().lower();
    arch = {"x86_64": "amd64", "aarch64": "arm64"}.get(arch, arch);
    return f"antigravity/{ANTIGRAVITY_CLIENT_VERSION} {os_name}/{arch}";
}

impl _camel_case_keys(config: Mapping[builtins.str, Any]) -> Dict[builtins.str, Any] {
    converted: Dict[builtins.str, Any] = {};
    for (key, value) in config.items() {
        items_: any = list(`str(key).split("_") as any);
        if len(items_) < 1 {
            raise ValueError(
                f"not enough values to unpack (expected at least 1, got {len(items_)})"
            );
        }
        head: any = items_[0];
        rest: any = items_[1:len(items_) - 0];
        converted[head + "".join(part[:1].upper() + part[1:] for part in rest)] = value;
    }
    return converted;
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
        code_part: any;
        fragment: any;
        (code_part, fragment) = first_token.split("#", 1) as any;
        if fragment and fragment != expected_state {
            raise RuntimeError("OAuth manual code state mismatch.");
        }
        return code_part;
    }

    return first_token;
}

impl GeminiOAuthCodeAssistLLM.init(
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
) {
    selected_model: any = custom_model;
    if not selected_model {
        if model in self.MODEL_PRESETS {
            selected_model = self.MODEL_PRESETS[model];
        } elif model {
            selected_model = model;
        } elif model_preset in self.MODEL_PRESETS {
            selected_model = self.MODEL_PRESETS[model_preset];
        } else {
            selected_model = DEFAULT_MODEL;
        }
    }

    if selected_model in GEMINI_OAUTH_RETIRED_MODELS {
        raise ValueError(
            f"Gemini OAuth model '{selected_model}' is retired. Use '{GEMINI_OAUTH_DEFAULT_MODEL}' or re-run `mobilerun configure gemini` to choose an available model.",
        );
    }

    super.__init__(
        model=selected_model,
        model_preset=model_preset,
        custom_model=custom_model,
        credential_slot=credential_slot,
        max_tokens=max_tokens,
        temperature=temperature,
        timeout=timeout,
        access_token=access_token,
        refresh_token=refresh_token,
        client_id=client_id,
        client_secret=client_secret,
        authorize_url=authorize_url,
        token_url=token_url,
        refresh_buffer_seconds=refresh_buffer_seconds,
        code_assist_endpoint=code_assist_endpoint,
        code_assist_api_version=code_assist_api_version,
        scopes=`tuple(scopes) if scopes else DEFAULT_OAUTH_SCOPES,
        credential_path=credential_path,
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

impl GeminiOAuthCodeAssistLLM.available_model_presets -> Dict[builtins.str, builtins.str] {
    return `dict(cls.MODEL_PRESETS);
}

impl GeminiOAuthCodeAssistLLM.class_name -> builtins.str {
    return "gemini_oauth_code_assist";
}

impl GeminiOAuthCodeAssistLLM._load_credentials_from_file(credential_path: builtins.str) -> None {
    path: any = Path(credential_path).expanduser();
    if not path.exists() {
        return;
    }

    try {
        raw: any = json.loads(path.read_text(encoding="utf-8"));
    } except Exception {
        return;
    }
    payload: any = raw.get(self.credential_slot);
    if not isinstance(payload, `dict) {
        return;
    }

    file_access: any = payload.get("access_token");
    file_refresh: any = payload.get("refresh_token");
    expiry_ms: any = payload.get("expiry_date");

    if not self._cached_access_token and isinstance(file_access, `str) {
        self._cached_access_token = file_access;
    }
    if not self._cached_refresh_token and isinstance(file_refresh, `str) {
        self._cached_refresh_token = file_refresh;
    }
    if isinstance(expiry_ms, (`int, `float)) {
        self._access_token_expiry = `float(expiry_ms) / 1000.0;
    }
}

impl GeminiOAuthCodeAssistLLM._persist_credentials(
    *, deadline: OAuthLoginDeadline | None = None
) -> None {
    if not self.credential_path {
        return;
    }

    path: any = Path(self.credential_path).expanduser();
    AuthProfileStore(path).update_slot(
        self.credential_slot,
        {
            "access_token": self._cached_access_token,
            "refresh_token": self._cached_refresh_token,
            "token_type": "Bearer",
            "expiry_date": `int(self._access_token_expiry * 1000)
                if self._access_token_expiry
                else None,
        },
        lock_timeout=deadline.remaining() if deadline is not None else None,
        before_commit=deadline.check if deadline is not None else None,
    );
}

impl GeminiOAuthCodeAssistLLM._metadata_payload -> Dict[builtins.str, builtins.str] {
    return {
        "ideType": "IDE_UNSPECIFIED",
        "platform": "PLATFORM_UNSPECIFIED",
        "pluginType": "GEMINI",
    };
}

impl GeminiOAuthCodeAssistLLM._build_headers(
    token: builtins.str
) -> Dict[builtins.str, builtins.str] {
    return {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json",
        "User-Agent": _antigravity_user_agent(),
        "Client-Metadata": json.dumps(self._metadata_payload()),
    };
}

impl GeminiOAuthCodeAssistLLM.fetch_available_models(
    *, deadline: OAuthLoginDeadline | None = None, access_token: builtins.str | None = None
) -> builtins.list[Dict[builtins.str, Any]] {
    token: any = access_token or self._resolve_access_token();
    effective_timeout: any = self.timeout
        if deadline is None
        else deadline.remaining(cap=self.timeout);
    response: any = self._session.post(
        self._method_url(DEFAULT_CODE_ASSIST_MODELS_METHOD),
        headers=self._build_headers(token),
        json={},
        timeout=effective_timeout,
    );
    if deadline is not None {
        deadline.check();
    }
    response.raise_for_status();
    data: any = response.json();
    if deadline is not None {
        deadline.check();
    }
    models: any = data.get("models");
    if not isinstance(models, `dict) {
        return [];
    }
    excluded: any = `set((data.get("deprecatedModelIds") or {}).keys());
    excluded.update(GEMINI_OAUTH_RETIRED_MODELS);
    excluded.update(data.get("imageGenerationModelIds") or ());
    out: builtins.list[Dict[builtins.str, Any]] = [];
    for (model_id, meta) in models.items() {
        if not isinstance(meta, `dict) or model_id in excluded {
            continue;
        }
        if meta.get("isInternal") {
            continue;
        }
        if "GEMINI" not in `str(meta.get("apiProvider") or "") {
            continue;
        }
        display_name: any = meta.get("displayName");
        is_tiered_model: any = isinstance(model_id, `str)
            and model_id.startswith("gemini-")
            and model_id.endswith("-tiered");
        if not display_name and not is_tiered_model {
            continue;
        }
        friendly_name: any = model_display_name_for_variant("gemini", "oauth", model_id);
        if friendly_name == model_id {
            friendly_name = display_name or model_id;
        }
        out.append({
            "id": model_id,
            "display_name": friendly_name,
            "supports_images": `bool(meta.get("supportsImages")),
        });
    }
    if deadline is not None {
        deadline.check();
    }
    return out;
}

impl GeminiOAuthCodeAssistLLM._access_token_is_stale -> builtins.bool {
    if not self._access_token_expiry {
        return False;
    }
    return operator.ge(time.time(), self._access_token_expiry - self.refresh_buffer_seconds);
}

impl GeminiOAuthCodeAssistLLM._refresh_access_token -> builtins.str {
    refresh_token: any = self._cached_refresh_token or self.refresh_token;
    if not refresh_token {
        raise ValueError(
            "No refresh token available. Provide `refresh_token` or a credential file."
        );
    }

    response: any = self._session.post(
        self.token_url,
        data={
            "grant_type": "refresh_token",
            "refresh_token": refresh_token,
            "client_id": self.client_id,
            "client_secret": self.client_secret,
        },
        timeout=self.timeout,
    );
    response.raise_for_status();
    data: any = response.json();

    access_token: any = data.get("access_token");
    if not isinstance(access_token, `str) or not access_token {
        raise RuntimeError(f"Token refresh succeeded but no access_token returned: {data}");
    }

    expires_in: any = data.get("expires_in", 3600);
    try {
        expires_in_s: any = `int(expires_in);
    } except (TypeError, ValueError) {
        expires_in_s = 3600;
    }

    self._cached_access_token = access_token;
    self._cached_refresh_token = data.get("refresh_token") or refresh_token;
    self._access_token_expiry = time.time() + expires_in_s;
    self._persist_credentials();

    return access_token;
}

impl GeminiOAuthCodeAssistLLM._exchange_authorization_code(
    code: builtins.str,
    redirect_uri: builtins.str,
    code_verifier: Optional[builtins.str] = None,
    deadline: OAuthLoginDeadline | None = None,
    persist_credentials: builtins.bool = True,
) -> builtins.str {
    payload: any = {
        "grant_type": "authorization_code",
        "code": code,
        "redirect_uri": redirect_uri,
        "client_id": self.client_id,
        "client_secret": self.client_secret,
    };
    if code_verifier {
        payload["code_verifier"] = code_verifier;
    }

    request_timeout: any = self.timeout
        if deadline is None
        else deadline.remaining(cap=self.timeout);
    response: any = self._session.post(self.token_url, data=payload, timeout=request_timeout);
    if deadline is not None {
        deadline.check();
    }
    response.raise_for_status();
    data: any = response.json();
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

    expires_in: any = data.get("expires_in", 3600);
    try {
        expires_in_s: any = `int(expires_in);
    } except (TypeError, ValueError) {
        expires_in_s = 3600;
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
        if persist_credentials {
            self._persist_credentials(deadline=deadline);
        }
    } except BaseException {
        items__: any = list(previous as any);
        if len(items__) != 3 {
            raise ValueError(
                f"too many values to unpack (expected 3, got {len(items__)})"
                    if len(items__) > 3
                    else f"not enough values to unpack (expected 3, got {len(items__)})",
            );
        }
        self._cached_access_token = items__[0];
        self._cached_refresh_token = items__[1];
        self._access_token_expiry = items__[2];
        raise;
    }
    return access_token;
}

impl GeminiOAuthCodeAssistLLM._build_auth_url(
    redirect_uri: builtins.str,
    state: builtins.str,
    prompt_consent: builtins.bool,
    code_challenge: Optional[builtins.str] = None,
) -> builtins.str {
    scope: any = " ".join(self.scopes);
    query: any = {
        "client_id": self.client_id,
        "redirect_uri": redirect_uri,
        "response_type": "code",
        "scope": scope,
        "access_type": "offline",
        "state": state,
    };
    if prompt_consent {
        query["prompt"] = "consent";
    }
    if code_challenge {
        query["code_challenge"] = code_challenge;
        query["code_challenge_method"] = "S256";
    }
    return f"{self.authorize_url}?{urlencode(query)}";
}

impl GeminiOAuthCodeAssistLLM.login(
    *,
    open_browser: builtins.bool = True,
    timeout_seconds: builtins.float = 300.0,
    callback_host: builtins.str = "127.0.0.1",
    callback_port: builtins.int = 0,
    callback_path: builtins.str = "/oauth2callback",
    prompt_consent: builtins.bool = True,
    deadline: OAuthLoginDeadline | None = None,
    persist_credentials: builtins.bool = True,
) -> builtins.str {
    result: Dict[builtins.str, Optional[builtins.str]];
    done: any;
    callback_lock: any;
    active_deadline: any = deadline or OAuthLoginDeadline(timeout_seconds);
    active_deadline.check();
    use_authcode: any = _is_headless_environment()
        or (
            os.environ.get("MOBILERUN_OAUTH_MANUAL")
            or os.environ.get("DROIDRUN_OAUTH_MANUAL")
            or ""
        ).lower()
            in ("1", "true", "yes");
    if use_authcode {
        return self.login_headless(
            open_browser=open_browser,
            timeout_seconds=timeout_seconds,
            prompt_consent=prompt_consent,
            deadline=active_deadline,
            persist_credentials=persist_credentials,
        );
    }
    result = {"code": None, "state": None, "error": None};
    done = threading.Event();
    callback_lock = threading.Lock();
    expected_state: any = secrets.token_hex(32);
    code_verifier: any;
    code_challenge: any;
    (code_verifier, code_challenge) = _pkce_pair() as any;

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
        print(
            f"Could not bind callback server on {callback_host}:{callback_port} ({exc}). Falling back to headless code entry.",
        );
        return self.login_headless(
            open_browser=open_browser,
            timeout_seconds=timeout_seconds,
            prompt_consent=prompt_consent,
            deadline=active_deadline,
            persist_credentials=persist_credentials,
        );
    }

    active_deadline.check();
    actual_port: any = httpd.server_address[1];
    redirect_uri: any = f"http://127.0.0.1:{actual_port}{callback_path}";
    auth_url: any = self._build_auth_url(
        redirect_uri=redirect_uri,
        state=expected_state,
        prompt_consent=prompt_consent,
        code_challenge=code_challenge,
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
        if result["state"] != expected_state {
            raise RuntimeError("OAuth callback state mismatch.");
        }
        if not result["code"] {
            raise RuntimeError("OAuth callback did not include an authorization code.");
        }

        access_token: any = self._exchange_authorization_code(
            result["code"],
            redirect_uri,
            code_verifier=code_verifier,
            deadline=active_deadline,
            persist_credentials=persist_credentials,
        );
    } finally {
        httpd.shutdown();
        httpd.server_close();
    }
    return access_token;
}

impl GeminiOAuthCodeAssistLLM.login_headless(
    *,
    open_browser: builtins.bool = False,
    timeout_seconds: builtins.float = 300.0,
    input_fn: Any = input_fn_default_,
    prompt_consent: builtins.bool = True,
    deadline: OAuthLoginDeadline | None = None,
    persist_credentials: builtins.bool = True,
) -> builtins.str {
    input_queue: queue.Queue[Optional[builtins.str]];
    stop: any;
    need_more: any;
    active_deadline: any = deadline or OAuthLoginDeadline(timeout_seconds);
    active_deadline.check();

    code_verifier: any;
    code_challenge: any;
    (code_verifier, code_challenge) = _pkce_pair() as any;
    expected_state: any = secrets.token_hex(32);
    redirect_uri: any = "https://codeassist.google.com/authcode";

    auth_url: any = self._build_auth_url(
        redirect_uri=redirect_uri,
        state=expected_state,
        prompt_consent=prompt_consent,
        code_challenge=code_challenge,
    );

    print(
        f"\nSign in with your Google account:\n\n1. Open this link in your browser:\n   {auth_url}\n\n2. Complete sign-in, then paste the authorization code shown on the page.\n",
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
                code: any = _normalize_manual_code(raw, expected_state);
            } except Exception {
                if attempt == 0 {
                    print("Invalid code. Try again.");
                    continue;
                }
                raise RuntimeError("Login failed.") from None;
            }
            if code {
                return self._exchange_authorization_code(
                    code,
                    redirect_uri,
                    code_verifier=code_verifier,
                    deadline=active_deadline,
                    persist_credentials=persist_credentials,
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
}

impl GeminiOAuthCodeAssistLLM._resolve_access_token -> builtins.str {
    env_access_token: any = os.environ.get("GEMINI_OAUTH_ACCESS_TOKEN");
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

impl GeminiOAuthCodeAssistLLM._message_text(message: ChatMessage) -> builtins.str {
    if isinstance(message.content, `str) {
        return message.content;
    }
    return "";
}

impl GeminiOAuthCodeAssistLLM._image_mime_type(raw: builtins.bytes) -> builtins.str {
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

impl GeminiOAuthCodeAssistLLM._message_parts(
    message: ChatMessage
) -> builtins.list[Dict[builtins.str, Any]] {
    parts: builtins.list[Dict[builtins.str, Any]] = [];
    for block in message.blocks or [] {
        if isinstance(block, TextBlock) {
            if block.text {
                parts.append({"text": block.text});
            }
        } elif isinstance(block, ImageBlock) {
            raw: any = block.resolve_image(as_base64=False).read();
            parts.append({
                "inlineData": {
                    "mimeType": cls._image_mime_type(raw),
                    "data": base64.b64encode(raw).decode("ascii"),
                },
            });
        }
    }
    return parts;
}

impl GeminiOAuthCodeAssistLLM._to_code_assist_request(
    messages: Sequence[ChatMessage], **kwargs: Any
) -> Dict[builtins.str, Any] {
    contents: builtins.list[Dict[builtins.str, Any]] = [];
    system_chunks: builtins.list[builtins.str] = [];

    for msg in messages {
        parts: any = self._message_parts(msg);
        if msg.role == MessageRole.SYSTEM {
            system_chunks.extend(part["text"] for part in parts if part.get("text"));
            continue;
        }

        role: any = "model" if msg.role == MessageRole.ASSISTANT else "user";
        if `any("inlineData" in part for part in parts) {
            contents.append({"role": role, "parts": parts});
        } else {
            contents.append({"role": role, "parts": [{"text": self._message_text(msg)}]});
        }
    }

    if not contents {
        contents.append({"role": "user", "parts": [{"text": ""}]});
    }

    generation_config: Dict[builtins.str, Any] = {};
    if not gemini_model_omits_sampling_params(self.model) {
        generation_config["temperature"] = self.temperature;
    }
    if self.max_tokens is not None {
        generation_config["maxOutputTokens"] = self.max_tokens;
    }
    generation_config.update(_camel_case_keys(kwargs.pop("generation_config", {})));

    request_extra: any = `dict(self.additional_kwargs);
    call_extra: any = `dict(kwargs.pop("request_extra", {}));
    replacement: Any = _UNSET;
    for extra in (request_extra, call_extra) {
        for key in ("generation_config", "generationConfig") {
            if key not in extra {
                continue;
            }
            value: any = extra.pop(key);
            if isinstance(value, Mapping) {
                generation_config.update(_camel_case_keys(value));
                replacement = _UNSET;
            } else {
                replacement = value;
            }
        }
    }
    request_extra.update(call_extra);

    omit_sampling: any = gemini_model_omits_sampling_params(self.model);
    if omit_sampling {
        for param in _GEMINI_SAMPLING_CONFIG_KEYS {
            generation_config.pop(param, None);
        }
    }

    request: Dict[builtins.str, Any] = {
        "contents": contents,
        "generationConfig": generation_config if replacement is _UNSET else replacement,
    };

    if system_chunks {
        request["systemInstruction"] = {
            "role": "user",
            "parts": [{"text": "\n\n".join(system_chunks)}],
        };
    }

    for ignored in _IGNORED_REQUEST_KWARGS {
        request_extra.pop(ignored, None);
    }
    request.update(request_extra);

    payload: Dict[builtins.str, Any] = {
        "model": self.model,
        "request": request,
        "userAgent": "droidrun",
        "requestId": f"droidrun-{`int(time.time() * 1000)}-{secrets.token_hex(4)}",
    };
    safe_kwargs: any = {
        k: v
        for (k, v) in kwargs.items()
        if k not in _IGNORED_REQUEST_KWARGS
            and not (omit_sampling and k in _GEMINI_SAMPLING_CONFIG_KEYS)
    };
    payload.update(safe_kwargs);
    payload.pop("project", None);
    return payload;
}

impl GeminiOAuthCodeAssistLLM._method_url(method: builtins.str) -> builtins.str {
    base: any = self.code_assist_endpoint.rstrip("/");
    version: any = self.code_assist_api_version.strip("/");
    return f"{base}/{version}:{method}";
}

impl GeminiOAuthCodeAssistLLM._extract_text(chunk: Dict[builtins.str, Any]) -> builtins.str {
    response: any = chunk.get("response") or {};
    candidates: any = response.get("candidates") or [];
    if not candidates {
        return "";
    }

    first: any = candidates[0] or {};
    content: any = first.get("content") or {};
    parts: any = content.get("parts") or [];

    text_parts: builtins.list[builtins.str] = [];
    for part in parts {
        if isinstance(part, `dict) and isinstance(part.get("text"), `str) {
            text_parts.append(part["text"]);
        }
    }

    return "".join(text_parts);
}

impl GeminiOAuthCodeAssistLLM.chat(messages: Sequence[ChatMessage], **kwargs: Any) -> ChatResponse {
    token: any = self._resolve_access_token();
    payload: any = self._to_code_assist_request(messages, **kwargs);

    response: any = self._session.post(
        self._method_url("streamGenerateContent"),
        params={"alt": "sse"},
        headers={**self._build_headers(token), "Accept": "text/event-stream"},
        json=payload,
        timeout=self.timeout,
        stream=True,
    );
    if not response.ok {
        raise requests.HTTPError(
            f"Code Assist {response.status_code} error: {response.text}", response=response
        );
    }

    accumulated: any = "";
    last_raw: Dict[builtins.str, Any] = {};
    buffer: builtins.list[builtins.str] = [];

    def _flush(buffer: builtins.list[builtins.str]) -> Optional[Dict[builtins.str, Any]] {
        if not buffer {
            return None;
        }
        chunk_text: any = "\n".join(buffer);
        try {
            return json.loads(chunk_text);
        } except json.JSONDecodeError {
            return None;
        }
    }

    for line in response.iter_lines(decode_unicode=True) {
        if line is None {
            continue;
        }
        stripped: any = line.strip();
        if stripped.startswith("data:") {
            buffer.append(stripped[5:].strip());
            continue;
        }
        if stripped != "" or not buffer {
            continue;
        }
        raw_chunk: any = _flush(buffer);
        buffer = [];
        if raw_chunk is None {
            continue;
        }
        last_raw = raw_chunk;
        delta: any = self._extract_text(raw_chunk);
        if delta {
            accumulated += delta;
        }
    }

    raw_chunk = _flush(buffer);
    if raw_chunk is not None {
        last_raw = raw_chunk;
        delta = self._extract_text(raw_chunk);
        if delta {
            accumulated += delta;
        }
    }

    return ChatResponse(
        message=ChatMessage(role=MessageRole.ASSISTANT, content=accumulated),
        raw=last_raw,
        additional_kwargs={
            "trace_id": last_raw.get("traceId"),
            "usage": (last_raw.get("response") or {}).get("usageMetadata"),
            "model_version": (last_raw.get("response") or {}).get("modelVersion"),
        },
    );
}

impl GeminiOAuthCodeAssistLLM.complete(prompt: builtins.str, **kwargs: Any) -> CompletionResponse {
    chat_response: any = self.chat([ChatMessage(role=MessageRole.USER, content=prompt)], **kwargs);
    return CompletionResponse(
        text=chat_response.message.content or "",
        raw=chat_response.raw,
        additional_kwargs=chat_response.additional_kwargs,
    );
}

impl GeminiOAuthCodeAssistLLM.stream_chat(
    messages: Sequence[ChatMessage], **kwargs: Any
) -> ChatResponseGen {
    response: any;
    token: any = self._resolve_access_token();
    payload: any = self._to_code_assist_request(messages, **kwargs);

    response = self._session.post(
        self._method_url("streamGenerateContent"),
        params={"alt": "sse"},
        headers={**self._build_headers(token), "Accept": "text/event-stream"},
        json=payload,
        timeout=self.timeout,
        stream=True,
    );
    response.raise_for_status();

    def gen -> Generator[any, any, any] {
        accumulated: any = "";
        buffer: builtins.list[builtins.str] = [];

        for line in response.iter_lines(decode_unicode=True) {
            if line is None {
                continue;
            }

            stripped: any = line.strip();
            if stripped.startswith("data:") {
                buffer.append(stripped[5:].strip());
                continue;
            }

            if stripped != "" or not buffer {
                continue;
            }

            chunk_text: any = "\n".join(buffer);
            buffer = [];
            try {
                raw_chunk: any = json.loads(chunk_text);
            } except json.JSONDecodeError {
                continue;
            }

            delta: any = self._extract_text(raw_chunk);
            if not delta {
                continue;
            }

            accumulated += delta;
            yield ChatResponse(
                message=ChatMessage(role=MessageRole.ASSISTANT, content=accumulated),
                delta=delta,
                raw=raw_chunk,
                additional_kwargs={
                    "trace_id": raw_chunk.get("traceId"),
                    "usage": (raw_chunk.get("response") or {}).get("usageMetadata"),
                    "model_version": (raw_chunk.get("response") or {}).get("modelVersion"),
                },
            );
        }

        if buffer {
            chunk_text = "\n".join(buffer);
            try {
                raw_chunk = json.loads(chunk_text);
            } except json.JSONDecodeError {
                raw_chunk = None;
            }

            if raw_chunk {
                delta = self._extract_text(raw_chunk);
                if delta {
                    accumulated += delta;
                    yield ChatResponse(
                        message=ChatMessage(role=MessageRole.ASSISTANT, content=accumulated),
                        delta=delta,
                        raw=raw_chunk,
                        additional_kwargs={
                            "trace_id": raw_chunk.get("traceId"),
                            "usage": (raw_chunk.get("response") or {}).get("usageMetadata"),
                            "model_version": (raw_chunk.get("response") or {}).get("modelVersion"),
                        },
                    );
                }
            }
        }
    }

    return gen();
}

impl GeminiOAuthCodeAssistLLM.stream_complete(
    prompt: builtins.str, **kwargs: Any
) -> CompletionResponseGen {
    def gen -> Generator[any, any, any] {
        for chat_chunk in self.stream_chat(
            [ChatMessage(role=MessageRole.USER, content=prompt)], **kwargs
        ) {
            yield CompletionResponse(
                text=chat_chunk.message.content or "",
                delta=chat_chunk.delta,
                raw=chat_chunk.raw,
                additional_kwargs=chat_chunk.additional_kwargs,
            );
        }
    }

    return gen();
}
