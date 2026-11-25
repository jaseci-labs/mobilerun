import from __future__ { annotations }

import from pathlib { Path }

import platformdirs;

glob APP_NAME: any = "droidrun";

glob USER_CONFIG_DIR: any;

glob OAUTH_CREDENTIAL_DIR: any;

glob AUTH_PROFILES_PATH: any;

glob OPENAI_OAUTH_CREDENTIAL_PATH: any;

glob ANTHROPIC_OAUTH_CREDENTIAL_PATH: any;

glob GEMINI_OAUTH_CREDENTIAL_PATH: any;

glob GROK_OAUTH_CREDENTIAL_PATH: any;

with entry {
    USER_CONFIG_DIR = Path(platformdirs.user_config_dir(APP_NAME));
    OAUTH_CREDENTIAL_DIR = USER_CONFIG_DIR / "credentials";
    AUTH_PROFILES_PATH = OAUTH_CREDENTIAL_DIR / "auth-profiles.json";
    OPENAI_OAUTH_CREDENTIAL_PATH = AUTH_PROFILES_PATH;
    ANTHROPIC_OAUTH_CREDENTIAL_PATH = AUTH_PROFILES_PATH;
    GEMINI_OAUTH_CREDENTIAL_PATH = AUTH_PROFILES_PATH;
    GROK_OAUTH_CREDENTIAL_PATH = AUTH_PROFILES_PATH;
}
