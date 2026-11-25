import operator;

import from __future__ { annotations }

glob VARIANT_ENV_KEY_SLOT: dict[str, str] = {
    "GoogleGenAI": "google",
    "OpenAIResponses": "openai",
    "XAI": "xai",
    "Anthropic": "anthropic",
    "ZAI": "zai",
    "ZAI_Coding": "zai",
    "MiniMax": "minimax",
};

glob OPENAI_MODEL_ALIASES: dict[str, str] = {"gpt-5.6": "gpt-5.6-sol"};

glob OPENAI_API_DEFAULT_MODEL: any = "gpt-6-astra";

glob OPENAI_OAUTH_DEFAULT_MODEL: any = OPENAI_API_DEFAULT_MODEL;

glob OPENAI_ASTRA_DEFAULT_REASONING_EFFORT: any = "low";

glob OPENAI_OAUTH_UNSUPPORTED_MODELS: any = frozenset({
    "gpt-5.3-codex",
    "gpt-5.4",
    "gpt-5.4-mini",
    "gpt-5.4-nano",
});

glob OPENAI_LEGACY_MODELS: any = frozenset({
    "gpt-6-sol",
    "gpt-6-luna",
    "gpt-5.4",
    "gpt-5.4-mini",
    "gpt-5.4-nano",
});

glob OPENAI_GPT6_MODELS: any = frozenset({"gpt-6-astra", "gpt-6.1-sol", "gpt-6-sol", "gpt-6-luna"});

glob OPENAI_GPT6_CONTEXT_WINDOW: any = 1050000;

glob _OPENAI_LOW_TO_MAX_EFFORTS: any = frozenset({"low", "medium", "high", "xhigh", "max"});

glob _OPENAI_NONE_TO_MAX_EFFORTS: any = _OPENAI_LOW_TO_MAX_EFFORTS | {"none"};

glob OPENAI_REASONING_EFFORTS: dict[str, any] = {
    "gpt-6-astra": _OPENAI_LOW_TO_MAX_EFFORTS,
    "gpt-6.1-sol": _OPENAI_LOW_TO_MAX_EFFORTS,
    "gpt-6-sol": _OPENAI_NONE_TO_MAX_EFFORTS,
    "gpt-6-luna": _OPENAI_NONE_TO_MAX_EFFORTS,
    "gpt-5.6-sol": _OPENAI_NONE_TO_MAX_EFFORTS,
    "gpt-5.6-terra": _OPENAI_NONE_TO_MAX_EFFORTS,
    "gpt-5.6-luna": _OPENAI_NONE_TO_MAX_EFFORTS,
};

glob GEMINI_API_DEFAULT_MODEL: any = "gemini-3.8-flash";

glob GEMINI_OAUTH_DEFAULT_MODEL: any = "gemini-3.8-flash-tiered";

glob GEMINI_OAUTH_RETIRED_MODELS: any = frozenset({
    "gemini-3.5-flash-low",
    "gemini-3.5-flash-extra-low",
    "gemini-3-flash-agent",
});

glob GEMINI_API_MODELS: tuple[str, ...] = (
    GEMINI_API_DEFAULT_MODEL,
    "gemini-4-argon",
    "gemini-3.7-flash",
    "gemini-3.5-flash-lite",
    "gemini-3.1-pro-preview",
);

glob _GEMINI_OAUTH_MODEL_DISPLAY_NAMES: dict[str, str] = {
    "gemini-3.8-flash-tiered": "gemini-3.8-flash",
    "gemini-3.7-flash-tiered": "gemini-3.7-flash",
};

glob GEMINI_UNSUPPORTED_SAMPLING_PARAMS: any = frozenset({"temperature", "top_p", "top_k"});

glob PROVIDER_FAMILIES: tuple[ProviderFamilySpec, ...];

def gemini_model_omits_sampling_params(model: object) -> bool;

with entry {
    PROVIDER_FAMILIES = (
        ProviderFamilySpec(
            id="gemini",
            display_name="Gemini",
            variants=(
                ProviderVariantSpec(
                    id="GoogleGenAI",
                    runtime_provider_name="GoogleGenAI",
                    auth_mode="api_key",
                    default_model=GEMINI_API_DEFAULT_MODEL,
                    models=GEMINI_API_MODELS,
                    requires_api_key=True,
                ),
                ProviderVariantSpec(
                    id="gemini_oauth_code_assist",
                    runtime_provider_name="gemini_oauth_code_assist",
                    auth_mode="oauth",
                    default_model=GEMINI_OAUTH_DEFAULT_MODEL,
                    models=(
                        GEMINI_OAUTH_DEFAULT_MODEL,
                        "gemini-3.8-flash-low",
                        "gemini-3.8-flash-medium",
                        "gemini-3.8-flash-high",
                        "gemini-3.7-flash-tiered",
                        "gemini-3.5-flash-lite",
                        "gemini-pro-agent",
                        "gemini-3.1-pro-low",
                    ),
                    credential_path=`str(GEMINI_OAUTH_CREDENTIAL_PATH),
                ),
            ),
        ),
        ProviderFamilySpec(
            id="openai",
            display_name="OpenAI",
            variants=(
                ProviderVariantSpec(
                    id="OpenAIResponses",
                    runtime_provider_name="OpenAIResponses",
                    auth_mode="api_key",
                    default_model=OPENAI_API_DEFAULT_MODEL,
                    models=(
                        OPENAI_API_DEFAULT_MODEL,
                        "gpt-6.1-sol",
                        "gpt-5.6-sol",
                        "gpt-5.6-terra",
                        "gpt-5.6-luna",
                    ),
                    requires_api_key=True,
                ),
                ProviderVariantSpec(
                    id="openai_oauth",
                    runtime_provider_name="openai_oauth",
                    auth_mode="oauth",
                    default_model=OPENAI_OAUTH_DEFAULT_MODEL,
                    models=(
                        OPENAI_OAUTH_DEFAULT_MODEL,
                        "gpt-6.1-sol",
                        "gpt-5.6-sol",
                        "gpt-5.6-terra",
                        "gpt-5.6-luna",
                    ),
                    credential_path=`str(OPENAI_OAUTH_CREDENTIAL_PATH),
                ),
            ),
            notes=("OpenAI OAuth uses a restricted model catalog.",),
        ),
        ProviderFamilySpec(
            id="anthropic",
            display_name="Anthropic",
            variants=(
                ProviderVariantSpec(
                    id="Anthropic",
                    runtime_provider_name="Anthropic",
                    auth_mode="api_key",
                    default_model=ANTHROPIC_API_DEFAULT_MODEL,
                    models=ANTHROPIC_API_MODELS,
                    requires_api_key=True,
                ),
                ProviderVariantSpec(
                    id="anthropic_oauth",
                    runtime_provider_name="anthropic_oauth",
                    auth_mode="oauth",
                    default_model=ANTHROPIC_OAUTH_DEFAULT_MODEL,
                    models=ANTHROPIC_OAUTH_MODELS,
                    credential_path=`str(ANTHROPIC_OAUTH_CREDENTIAL_PATH),
                ),
            ),
        ),
        ProviderFamilySpec(
            id="xai",
            display_name="XAI",
            variants=(
                ProviderVariantSpec(
                    id="XAI",
                    runtime_provider_name="XAI",
                    auth_mode="api_key",
                    default_model=GROK_API_DEFAULT_MODEL,
                    models=GROK_API_MODELS,
                    requires_api_key=True,
                    base_url=XAI_API_BASE,
                ),
                ProviderVariantSpec(
                    id="xai_oauth",
                    runtime_provider_name="xai_oauth",
                    auth_mode="oauth",
                    default_model=GROK_OAUTH_DEFAULT_MODEL,
                    models=GROK_OAUTH_MODELS,
                    credential_path=`str(GROK_OAUTH_CREDENTIAL_PATH),
                ),
            ),
        ),
        ProviderFamilySpec(
            id="ollama",
            display_name="Ollama",
            variants=(
                ProviderVariantSpec(
                    id="Ollama",
                    runtime_provider_name="Ollama",
                    auth_mode="none",
                    default_model="llama3.2:3b",
                    models=(),
                    requires_base_url=True,
                    base_url="http://localhost:11434",
                ),
            ),
        ),
        ProviderFamilySpec(
            id="openai_like",
            display_name="OpenAI Compatible",
            variants=(
                ProviderVariantSpec(
                    id="OpenAILike",
                    runtime_provider_name="OpenAILike",
                    auth_mode="api_key",
                    default_model=None,
                    models=(),
                    requires_api_key=True,
                    requires_base_url=True,
                ),
            ),
            notes=("Use for OpenRouter, LM Studio, vLLM, and other OpenAI-compatible endpoints.",),
        ),
        ProviderFamilySpec(
            id="minimax",
            display_name="MiniMax",
            variants=(
                ProviderVariantSpec(
                    id="MiniMax",
                    runtime_provider_name="MiniMax",
                    runtime_transport_provider_name="OpenAILike",
                    auth_mode="api_key",
                    default_model=MINIMAX_DEFAULT_MODEL,
                    models=(MINIMAX_DEFAULT_MODEL, "MiniMax-M2.7", "MiniMax-M2.7-highspeed"),
                    requires_api_key=True,
                    requires_base_url=True,
                    base_url=MINIMAX_GLOBAL_BASE_URL,
                ),
            ),
        ),
        ProviderFamilySpec(
            id="zai",
            display_name="ZAI",
            variants=(
                ProviderVariantSpec(
                    id="ZAI",
                    runtime_provider_name="ZAI",
                    runtime_transport_provider_name="OpenAILike",
                    auth_mode="api_key",
                    default_model="glm-5",
                    models=("glm-5", "glm-5v-turbo", "glm-4.7"),
                    requires_api_key=True,
                    requires_base_url=True,
                    base_url="https://api.z.ai/api/paas/v4",
                ),
                ProviderVariantSpec(
                    id="ZAI_Coding",
                    runtime_provider_name="ZAI",
                    runtime_transport_provider_name="OpenAILike",
                    auth_mode="coding_api",
                    default_model="glm-4.7",
                    models=("glm-4.7",),
                    requires_api_key=True,
                    requires_base_url=True,
                    base_url="https://api.z.ai/api/coding/paas/v4",
                ),
            ),
            notes=(
                "ZAI is exposed as a first-class provider family while reusing the OpenAI-compatible transport.",
                "Use auth mode `coding_api` for the GLM Coding Plan endpoint.",
            ),
        ),
    );
}

def list_provider_families -> tuple[ProviderFamilySpec, ...];

def get_provider_family(family_id: str) -> ProviderFamilySpec;

def list_auth_modes(family_id: str) -> tuple[str, ...];

def resolve_provider_variant(family_id: str, auth_mode: str | None = None) -> ProviderVariantSpec;

def list_models_for_variant(family_id: str, auth_mode: str | None = None) -> tuple[str, ...];

def model_display_name_for_variant(family_id: str, auth_mode: str | None, model_id: str) -> str;

def normalize_model_id_for_variant(family_id: str, auth_mode: str | None, model_id: str) -> str;
