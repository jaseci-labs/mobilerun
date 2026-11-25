import from __future__ { annotations }

glob SETUP_TOKEN_EXPIRES_IN_SECONDS: any = 365 * 24 * 60 * 60;

glob callback_host_default_: any = DEFAULT_OPENAI_OAUTH_CALLBACK_HOST;

glob callback_port_default_: any = DEFAULT_OPENAI_OAUTH_CALLBACK_PORT;

glob callback_path_default_: any = DEFAULT_OPENAI_OAUTH_CALLBACK_PATH;

def run_openai_oauth_login(
    credential_path: str,
    model: str | None,
    timeout: float = 300.0,
    callback_host: str = callback_host_default_,
    callback_port: int = callback_port_default_,
    callback_path: str = callback_path_default_,
    open_browser: bool = True,
) -> None {
    deadline: any = OAuthLoginDeadline(timeout, timeout_message="OpenAI OAuth login timed out.");
    llm: any = OpenAIOAuth(model=model, oauth_credential_path=credential_path, timeout=timeout);
    llm.login(
        open_browser=open_browser,
        timeout_seconds=deadline.remaining(),
        callback_host=callback_host,
        callback_port=callback_port,
        callback_path=callback_path,
        redirect_host=callback_host,
        deadline=deadline,
    );
}

def run_gemini_oauth_login(
    credential_path: str,
    model: str | None,
    timeout: float = 300.0,
    callback_host: str = "127.0.0.1",
    callback_port: int = 0,
    callback_path: str = "/oauth2callback",
    open_browser: bool = True,
) -> None {
    deadline: any = OAuthLoginDeadline(timeout, timeout_message="Gemini OAuth login timed out.");
    llm: any = GeminiOAuthCodeAssistLLM(
        model=model or GEMINI_OAUTH_DEFAULT_MODEL, credential_path=credential_path, timeout=timeout
    );
    access_token: any = llm.login(
        open_browser=open_browser,
        timeout_seconds=deadline.remaining(),
        callback_host=callback_host,
        callback_port=callback_port,
        callback_path=callback_path,
        deadline=deadline,
        persist_credentials=False,
    );
    try {
        models: any = llm.fetch_available_models(deadline=deadline, access_token=access_token);
    } except TimeoutError {
        raise;
    } except Exception as exc {
        raise RuntimeError(
            f"Gemini OAuth login received a token, but the Antigravity entitlement check (fetchAvailableModels) failed: {exc}. The login is not usable; verify your Google One / AI access and retry.",
        ) from exc;
    }
    if not models {
        raise RuntimeError(
            "Gemini OAuth login returned no usable models; credentials were not saved."
        );
    }
    llm._persist_credentials(deadline=deadline);
    print(f"✓ Gemini (Antigravity) login OK — {len(models)} models available.");
}

def run_grok_oauth_login(
    credential_path: str,
    model: str | None,
    timeout: float = 300.0,
    open_browser: bool = True,
    device_code: bool = False,
    no_browser: bool | None = None,
) -> None {
    deadline: any = OAuthLoginDeadline(timeout, timeout_message="XAI OAuth login timed out.");
    llm: any = GrokOAuth(
        model=model or DEFAULT_GROK_MODEL, oauth_credential_path=credential_path, timeout=timeout
    );
    llm.login(
        open_browser=open_browser if no_browser is None else open_browser and not no_browser,
        timeout_seconds=deadline.remaining(),
        device_code=device_code,
        deadline=deadline,
    );
}

def run_anthropic_setup_token_oauth(
    *,
    credential_path: str | None = None,
    timeout: float = 300.0,
    callback_host: str = "127.0.0.1",
    callback_port: int = 0,
    callback_path: str = "/callback",
    open_browser: bool = True,
) -> str {
    deadline: any = OAuthLoginDeadline(timeout, timeout_message="Anthropic OAuth login timed out.");
    llm: any = AnthropicOAuthLLM(
        credential_path=None,
        authorize_url="https://claude.com/cai/oauth/authorize",
        login_scope=DEFAULT_SETUP_TOKEN_SCOPE,
        timeout=timeout,
    );
    token: any = llm.login(
        open_browser=open_browser,
        timeout_seconds=deadline.remaining(),
        callback_host=callback_host,
        callback_port=callback_port,
        callback_path=callback_path,
        expires_in=SETUP_TOKEN_EXPIRES_IN_SECONDS,
        deadline=deadline,
    );
    if credential_path is not None {
        save_anthropic_setup_token(credential_path, token, deadline=deadline);
    }
    return token;
}

def save_anthropic_setup_token(
    credential_path: str, token: str, *, deadline: OAuthLoginDeadline | None = None
) -> None {
    AuthProfileStore(credential_path).update_slot(
        "claudeAiOauth",
        {"accessToken": token, "refreshToken": None, "expiresAt": None, "scopes": []},
        lock_timeout=deadline.remaining() if deadline is not None else None,
        before_commit=deadline.check if deadline is not None else None,
    );
}

def run_anthropic_oauth_setup(credential_path: str) -> None {
    run_anthropic_setup_token_oauth(credential_path=credential_path);
}

def get_default_openai_credential_path -> str {
    return `str(DEFAULT_OPENAI_OAUTH_CREDENTIAL_PATH);
}
