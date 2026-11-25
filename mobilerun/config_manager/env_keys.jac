"""API key lookup and persistence helpers."""

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

"""API key values from the shell and the saved env file."""
@dataclass(frozen=True)
class ApiKeySources {
    has shell: str = "";

    has saved: str = "";
}

"""Read the apiKeys section from the shared auth-profiles.json."""
def _load_saved_api_keys -> dict[str, str];

"""Load API keys from shell env vars and the shared auth-profiles file.

    The returned mapping keeps the two sources separate so callers can decide
    whether to prefer the live shell environment or the persisted file.
    """
def load_env_key_sources -> dict[str, ApiKeySources];

"""Load API keys. The saved file takes precedence over shell env vars.

    Returns:
        Dict mapping slot name (e.g. "google") to key value.
    """
def load_env_keys -> dict[str, str];

"""Resolve an API key for a provider slot from a specific source.

    Args:
        slot: Provider slot name, e.g. "openai" or "anthropic".
        source: "auto" (saved file first, then shell), "env" (shell only), or
            "file" (saved env file only).
    """
def resolve_env_key(slot: str, source: str = "auto") -> str;

"""Persist API keys to the apiKeys section of auth-profiles.json.

    Also sets them as env vars in the current process.

    Args:
        keys: Dict mapping slot name (e.g. "google") to key value.
    """
def save_env_keys(keys: dict[str, str]) -> None;
