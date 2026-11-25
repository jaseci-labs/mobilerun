impl b64_no_pad(raw: bytes) -> str {
    return base64.urlsafe_b64encode(raw).decode("utf-8").rstrip("=");
}

impl pkce_pair -> tuple[str, str] {
    verifier: any = b64_no_pad(secrets.token_bytes(64));
    challenge: any = b64_no_pad(hashlib.sha256(verifier.encode("utf-8")).digest());
    return (verifier, challenge);
}

impl normalize_manual_code(raw: str, expected_state: str) -> str {
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

impl LoopbackCallback.init(host: str, port: int, path: str, server_cls: Any) {
    self.path = path;
    self.result = {"code": None, "state": None, "error": None};
    self.done = threading.Event();
    self.lock = threading.Lock();
    self.httpd = server_cls((host, port), _CallbackHandler);
    self.httpd.mobilerun_callback = self;
}

impl LoopbackCallback.port -> int {
    return self.httpd.server_address[1];
}

impl LoopbackCallback.serve -> None {
    server_thread: Any = threading.Thread(target=self.httpd.serve_forever, daemon=True);
    self.httpd.daemon_threads = True;
    server_thread.start();
}

impl LoopbackCallback.receive(request: Any) -> None {
    parsed: Any = urlparse(request.path);
    if parsed.path != self.path {
        request.send_response(404);
        request.end_headers();
        return;
    }
    with self.lock {
        if self.done.is_set() {
            request.send_response(409);
            request.end_headers();
            return;
        }
        params: Any = parse_qs(parsed.query);
        for key in ("code", "state", "error") {
            self.result[key] = params.get(key, [None])[0];
        }
        ok: Any = self.result["code"] is not None and self.result["error"] is None;
        self.done.set();
    }
    request.send_response(200 if ok else 400);
    request.send_header("Content-Type", "text/html; charset=utf-8");
    request.end_headers();
    request.wfile.write(
        b"<html><body><h3>Login complete. You can close this tab.</h3></body></html>"
            if ok
            else b"<html><body><h3>Login failed. Return to your terminal.</h3></body></html>",
    );
}

impl LoopbackCallback.code(deadline: Any, state: str, timeout_message: str) -> str {
    if not self.done.wait(timeout=deadline.remaining()) {
        raise TimeoutError(timeout_message);
    }
    deadline.check();
    if self.result["error"] {
        raise RuntimeError("OAuth callback returned error: " + format(self.result["error"], ""));
    }
    if self.result["state"] != state {
        raise RuntimeError("OAuth callback state mismatch.");
    }
    if not self.result["code"] {
        raise RuntimeError("OAuth callback did not include an authorization code.");
    }
    return self.result["code"];
}

impl LoopbackCallback.close -> None {
    self.httpd.shutdown();
    self.httpd.server_close();
}

impl _CallbackHandler.do_GET -> None {
    self.server.mobilerun_callback.receive(self);
}

impl _CallbackHandler.log_message(format: builtins.str, *args: Any) -> None {}

impl read_manual_code(input_fn: Any, state: str, deadline: Any, max_attempts: int) -> str {
    input_queue: Any = queue.Queue();
    stop = threading.Event();
    need_more = threading.Event();

    def _reader -> None {
        for _ in range(max_attempts) {
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
        for attempt in range(max_attempts) {
            need_more.set();

            try {
                raw: any = input_queue.get(timeout=deadline.remaining());
            } except queue.Empty {
                raise TimeoutError("OAuth login timed out.") from None;
            }
            deadline.check();

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
                code: any = normalize_manual_code(raw, state);
            } except Exception {
                if attempt == 0 {
                    print("Invalid code. Try again.");
                    continue;
                }
                raise RuntimeError("Login failed.") from None;
            }
            if code {
                return code;
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
