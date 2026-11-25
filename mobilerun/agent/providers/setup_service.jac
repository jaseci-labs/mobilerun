import from __future__ { annotations }

import from dataclasses { dataclass }

import from typing { Iterable }

import httpx;

glob DEFAULT_KWARGS_BY_VARIANT: dict[str, dict[str, int]];

glob HIDDEN_ROLE_FALLBACKS: tuple[str, ...];

glob _MINIMAX_DETERMINISTIC_TEMPERATURE: any;

glob _ZAI_GLOBAL_BASE_URL: any;

glob _ZAI_CODING_GLOBAL_BASE_URL: any;

with entry {
    DEFAULT_KWARGS_BY_VARIANT = {
        "anthropic_oauth": {"max_tokens": 4096},
        "gemini_oauth_code_assist": {"max_tokens": 4096},
        "Ollama": {"context_window": 32768},
        "XAI": {"context_window": 500000},
    };

    HIDDEN_ROLE_FALLBACKS = ("app_opener", "structured_output");
    _MINIMAX_DETERMINISTIC_TEMPERATURE = 0.1;
    _ZAI_GLOBAL_BASE_URL = "https://api.z.ai/api/paas/v4";
    _ZAI_CODING_GLOBAL_BASE_URL = "https://api.z.ai/api/coding/paas/v4";
}

@dataclass(frozen=True)
class SetupSelection {
    has family_id: str;

    has variant_id: str;

    has auth_mode: str;

    has model: str;

    has api_key: str | None = None;

    has api_key_source: str = "auto";

    has base_url: str | None = None;

    has credential_path: str | None = None;
}

def family_choices -> tuple[ProviderFamilySpec, ...];

def auth_mode_choices(family_id: str) -> tuple[str, ...];

def variant_models(family_id: str, auth_mode: str) -> tuple[str, ...];

def _normalize_generated_temperature(family_id: str, temperature: float) -> float;

def _probe_zai_chat_completions(
    *, base_url: str, api_key: str, model_id: str, timeout_seconds: float = 5.0
) -> bool;

"""Resolve the effective ZAI base URL and model.

    We only support the two user-facing modes:
    - api_key -> global endpoint
    - coding_api -> coding-global endpoint

    For coding_api, probe glm-5 first and fall back to glm-4.7 when the
    provided token/plan does not expose glm-5 on the coding endpoint.
    """
def _resolve_zai_selection(selection: SetupSelection, base_url: str | None) -> tuple[str
    | None, str];

def create_profile_for_variant(
    variant: ProviderVariantSpec, selection: SetupSelection, *, temperature: float = 0.2
) -> LLMProfile;

def apply_selection_to_roles(
    config: MobileConfig, selection: SetupSelection, roles: Iterable[str]
) -> MobileConfig;
