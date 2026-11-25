import from __future__ { annotations }

import os;

import from dataclasses { dataclass }

glob API_KEY_ENV_VARS: any = {
    "google": "GOOGLE_API_KEY",
    "gemini": "GEMINI_API_KEY",
    "openai": "OPENAI_API_KEY",
    "xai": "XAI_API_KEY",
    "anthropic": "ANTHROPIC_API_KEY",
    "zai": "ZAI_API_KEY",
    "minimax": "MINIMAX_API_KEY",
};

glob _API_KEYS_SECTION: any = "apiKeys";

glob AUTH_PROFILES_PATH: any = _DEFAULT_AUTH_PROFILES_PATH;

"""API key values from the shell and the saved env file."""
@dataclass(frozen=True)
class ApiKeySources {
    has shell: str = "";

    has saved: str = "";
}

def _load_saved_api_keys -> dict[str, str];

def load_env_key_sources -> dict[str, ApiKeySources];

def load_env_keys -> dict[str, str];

def resolve_env_key(slot: str, source: str = "auto") -> str;

def save_env_keys(keys: dict[str, str]) -> None;
