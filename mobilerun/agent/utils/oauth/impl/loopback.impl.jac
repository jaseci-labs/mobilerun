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
