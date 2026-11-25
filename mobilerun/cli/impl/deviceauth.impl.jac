impl DeviceAuthError.init(code: str, description: str = "") {
    self.code = code;
    self.description = description;
    super.init(f"{code}: {description}" if description else code);
}

impl DeviceAuthError.__repr__ -> str {
    return (getattr(builtins.super(DeviceAuthError, self), "__repr__") as any)();
}

impl DeviceAuthError.__eq__(other: any) -> bool {
    return self is other;
}

impl DeviceAuthError.__hash__ -> int {
    return id(self);
}

impl _endpoint(auth_url: str, path: str) -> str {
    return auth_url.rstrip("/") + path;
}

impl request_code(auth_url: str, client_id: str) -> CodeResponse {
    resp: any = httpx.post(
        _endpoint(auth_url, "/device/code"),
        json={"client_id": client_id, "scope": "openid profile email"},
        headers={"Accept": "application/json"},
        timeout=_REQUEST_TIMEOUT,
    );
    if not 200 <= resp.status_code < 300 {
        raise RuntimeError(
            f"device-code endpoint returned {resp.status_code}: {resp.text.strip()}"
        );
    }
    d: any = resp.json();
    return CodeResponse(
        device_code=d["device_code"],
        user_code=d["user_code"],
        verification_uri=d.get("verification_uri", ""),
        verification_uri_complete=d.get("verification_uri_complete", ""),
        expires_in=`int(d.get("expires_in", 0)),
        interval=`int(d.get("interval", 5)),
    );
}

impl _exchange(auth_url: str, client_id: str, device_code: str) -> str {
    resp: any = httpx.post(
        _endpoint(auth_url, "/device/token"),
        json={
            "grant_type": GRANT_TYPE_DEVICE_CODE,
            "device_code": device_code,
            "client_id": client_id,
        },
        headers={"Accept": "application/json"},
        timeout=_REQUEST_TIMEOUT,
    );
    if 200 <= resp.status_code < 300 {
        token: any = resp.json().get("access_token");
        if not token {
            raise RuntimeError("token response missing access_token");
        }
        return token;
    }
    try {
        err: any = resp.json();
        code: any = err.get("error");
    } except Exception {
        code = None;
    }
    if not code {
        raise RuntimeError(f"token endpoint returned {resp.status_code}");
    }
    raise DeviceAuthError(code, err.get("error_description", ""));
}

impl poll_token(auth_url: str, client_id: str, code: CodeResponse) -> str {
    interval: any = max(`float(code.interval), _MIN_POLL_INTERVAL);
    deadline: any = time.monotonic() + code.expires_in;

    while True {
        time.sleep(interval);
        try {
            return _exchange(auth_url, client_id, code.device_code);
        } except DeviceAuthError as e {
            if e.code == "authorization_pending" {} elif e.code == "slow_down" {
                interval += _SLOW_DOWN_BUMP;
            } else {
                raise;
            }
        }
        if time.monotonic() > deadline {
            raise DeviceAuthError("expired_token", "device code expired");
        }
    }
}

impl fetch_session(auth_url: str, token: str) -> Optional[dict] {
    resp: any = httpx.get(
        _endpoint(auth_url, "/get-session"),
        headers={"Accept": "application/json", "Authorization": f"Bearer {token}"},
        timeout=_REQUEST_TIMEOUT,
    );
    if not 200 <= resp.status_code < 300 {
        raise RuntimeError(f"get-session endpoint returned {resp.status_code}");
    }
    return resp.json();
}

impl credential_path -> Path {
    import from mobilerun.config_manager.credential_paths { OAUTH_CREDENTIAL_DIR }

    return OAUTH_CREDENTIAL_DIR / "mobilerun-cloud.json";
}

impl _chmod_private(path: Path, mode: int) -> None {
    comptime if target().os != "windows" {
        os.chmod(path, mode);
    }
}

impl save_token(token: str, auth_url: str) -> Path {
    path: any = credential_path();
    path.parent.mkdir(parents=True, exist_ok=True);
    _chmod_private(path.parent, 448);

    payload: any = json.dumps({"access_token": token, "auth_url": auth_url});
    fd: any;
    tmp_name: any;
    (fd, tmp_name) = tempfile.mkstemp(prefix=f".{path.name}.", dir=path.parent) as any;
    tmp_path: any = Path(tmp_name);
    try {
        handle: any;
        with os.fdopen(fd, "w") as handle {
            handle.write(payload);
        }
        _chmod_private(tmp_path, 384);
        os.replace(tmp_path, path);
        _chmod_private(path, 384);
    } except Exception {
        try {
            tmp_path.unlink();
        } except FileNotFoundError {}
        raise;
    }
    return path;
}

impl load_credentials -> Optional[dict] {
    path: any = credential_path();
    if not path.exists() {
        return None;
    }
    try {
        return json.loads(path.read_text());
    } except Exception {
        return None;
    }
}

impl clear_credentials -> bool {
    path: any = credential_path();
    if path.exists() {
        path.unlink();
        return True;
    }
    return False;
}
