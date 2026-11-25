import operator;

import from __future__ { annotations }

import json;

import from dataclasses { dataclass }

import from pathlib { Path }

import from typing { Any, Callable }

import click;

import from rich.console { Console }

import from rich.panel { Panel }

glob _BACK: any = "__back__";

glob _CUSTOM_MINIMAX_BASE_URL: any = "__custom_minimax_base_url__";

glob _ALL_CONFIG_ROLES: any = (
    "manager",
    "executor",
    "fast_agent",
    "app_opener",
    "structured_output",
);

@dataclass
class ConfigureWizardCallbacks {
    has run_openai_oauth_login: Callable[..., None];

    has run_anthropic_oauth_login: Callable[..., None];

    has run_gemini_oauth_login: Callable[..., None];

    has run_grok_oauth_login: Callable[..., None] | None = None;
}

@dataclass
class ConfigureWizardState {
    has family_id: str | None = None;

    has selected_auth_mode: str | None = None;

    has selected_model: str | None = None;

    has selected_api_key: str | None = None;

    has selected_api_key_source: str | None = None;

    has selected_base_url: str | None = None;

    has last_variant_id: str | None = None;

    has prepared_auth_variant_id: str | None = None;

    has used_advanced_settings: bool = False;
}

def _with_back_choice(
    choices: list[SelectChoice], *, include_back: bool = True
) -> list[SelectChoice];

def _select_with_back(
    message: str,
    choices: list[SelectChoice],
    *,
    `default: str | None = None,
    include_back: bool = True,
) -> str;

def _print_configure_intro(console: Console) -> None;

def _print_configure_summary(
    console: Console,
    *,
    family_id: str,
    auth_mode: str,
    provider_label: str,
    variant_id: str,
    model: str,
    used_advanced_settings: bool,
) -> None;

def _prompt_int(console: Console, message: str, `default: int) -> int;

def _prompt_float(console: Console, message: str, `default: float) -> float;

def _prompt_model_choice(
    models: list[str],
    *,
    family_id: str,
    auth_mode: str,
    default_model: str,
    allow_back: bool = True,
) -> str;

def _prompt_api_key_source(variant: Any) -> str;

def _prompt_api_key_for_variant(variant: Any) -> tuple[str, str];

def _prompt_base_url_for_variant(variant: Any) -> str;

glob _OAUTH_CREDENTIAL_SLOTS: any = {
    "gemini_oauth_code_assist": "geminiAntigravityOauth",
    "openai_oauth": "openaiOauth",
    "anthropic_oauth": "claudeAiOauth",
    "xai_oauth": "grokOauth",
};

def _oauth_credentials_present(credential_path: str, variant_id: str) -> bool;

def _prompt_oauth_credential_action(credential_path: str) -> str;

def _apply_model_selection(
    config,
    *,
    family_id: str,
    variant: Any,
    selected_auth_mode: str,
    selected_model: str,
    selected_api_key: str | None,
    selected_api_key_source: str | None,
    selected_base_url: str | None,
    credential_path: str | None,
) -> None;

def _prepare_variant_auth(
    *,
    callbacks: ConfigureWizardCallbacks,
    variant: Any,
    credential_path: str | None,
    selected_model: str,
) -> None;

def _set_profile_max_tokens(profile: Any, value: int) -> None;

def _set_profile_context_window(profile: Any, value: int) -> None;

def _any_ollama_profile(config) -> bool;

def _any_minimax_profile(config) -> bool;

def _toggle_label(enabled: bool) -> str;

def _is_vision_enabled(config) -> bool;

def _set_vision_all(config, enabled: bool) -> None;

def _configure_advanced_settings(console: Console, config) -> None;

def _configure_provider_model(
    console: Console,
    config,
    callbacks: ConfigureWizardCallbacks,
    state: ConfigureWizardState,
    families,
    family_labels: dict[str, str],
    *,
    provider_is_fixed: bool,
    auth_mode_is_fixed: bool,
    model_is_fixed: bool,
    api_key: str | None,
    base_url: str | None,
) -> bool;

def run_configure_wizard(
    console: Console,
    callbacks: ConfigureWizardCallbacks,
    *,
    provider: str | None,
    auth_mode: str | None,
    model: str | None,
    api_key: str | None,
    base_url: str | None,
) -> None;
