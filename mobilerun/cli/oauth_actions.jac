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
) -> None;

def run_gemini_oauth_login(
    credential_path: str,
    model: str | None,
    timeout: float = 300.0,
    callback_host: str = "127.0.0.1",
    callback_port: int = 0,
    callback_path: str = "/oauth2callback",
    open_browser: bool = True,
) -> None;

def run_grok_oauth_login(
    credential_path: str,
    model: str | None,
    timeout: float = 300.0,
    open_browser: bool = True,
    device_code: bool = False,
    no_browser: bool | None = None,
) -> None;

def run_anthropic_setup_token_oauth(
    *,
    credential_path: str | None = None,
    timeout: float = 300.0,
    callback_host: str = "127.0.0.1",
    callback_port: int = 0,
    callback_path: str = "/callback",
    open_browser: bool = True,
) -> str;

def save_anthropic_setup_token(
    credential_path: str, token: str, *, deadline: OAuthLoginDeadline | None = None
) -> None;

def run_anthropic_oauth_setup(credential_path: str) -> None;

def get_default_openai_credential_path -> str;
