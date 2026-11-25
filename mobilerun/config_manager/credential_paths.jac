import from __future__ { annotations }

import from pathlib { Path }

import platformdirs;

glob APP_NAME: any = "droidrun";

glob USER_CONFIG_DIR: any = Path(platformdirs.user_config_dir(APP_NAME));

glob OAUTH_CREDENTIAL_DIR: any = USER_CONFIG_DIR / "credentials";

glob AUTH_PROFILES_PATH: any = OAUTH_CREDENTIAL_DIR / "auth-profiles.json";

glob OPENAI_OAUTH_CREDENTIAL_PATH: any = AUTH_PROFILES_PATH;

glob ANTHROPIC_OAUTH_CREDENTIAL_PATH: any = AUTH_PROFILES_PATH;

glob GEMINI_OAUTH_CREDENTIAL_PATH: any = AUTH_PROFILES_PATH;

glob GROK_OAUTH_CREDENTIAL_PATH: any = AUTH_PROFILES_PATH;
