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

def _load_saved_api_keys -> dict[str, str] {
    if not AUTH_PROFILES_PATH.exists() {
        return {};
    }
    try {
        data: any = AuthProfileStore(AUTH_PROFILES_PATH).read_profile();
        section: any = data.get(_API_KEYS_SECTION);
        if isinstance(section, `dict) {
            return {k: `str(v) for (k, v) in section.items() if v};
        }
        return {};
    } except Exception {
        return {};
    }
}

def load_env_key_sources -> dict[str, ApiKeySources] {
    saved_keys: any = _load_saved_api_keys();
    result: dict[str, ApiKeySources] = {};

    for (slot, env_var) in API_KEY_ENV_VARS.items() {
        result[slot] = ApiKeySources(
            shell=os.environ.get(env_var, "") or "", saved=saved_keys.get(slot, "")
        );
    }

    return result;
}

def load_env_keys -> dict[str, str] {
    result: dict[str, str] = {};
    for (slot, sources) in load_env_key_sources().items() {
        result[slot] = sources.saved or sources.shell;
    }
    return result;
}

def resolve_env_key(slot: str, source: str = "auto") -> str {
    sources: any = load_env_key_sources().get(slot, ApiKeySources());
    if source == "env" {
        return sources.shell;
    }
    if source == "file" {
        return sources.saved;
    }
    return sources.saved or sources.shell;
}

def save_env_keys(keys: dict[str, str]) -> None {
    known_keys = {slot: val for (slot, val) in keys.items() if slot in API_KEY_ENV_VARS};

    def _update(existing: dict) -> None {
        api_keys: any = existing.get(_API_KEYS_SECTION, {});
        if not isinstance(api_keys, `dict) {
            api_keys = {};
        }
        for (slot, val) in known_keys.items() {
            if val {
                api_keys[slot] = val;
            } else {
                api_keys.pop(slot, None);
            }
        }
        existing[_API_KEYS_SECTION] = api_keys;
    }
    AuthProfileStore(AUTH_PROFILES_PATH).update_profile(_update);
    for (slot, val) in known_keys.items() {
        env_var: any = API_KEY_ENV_VARS[slot];
        if val {
            os.environ[env_var] = val;
        } else {
            os.environ.pop(env_var, None);
        }
    }
}
