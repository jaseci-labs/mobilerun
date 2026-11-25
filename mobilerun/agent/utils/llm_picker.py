import builtins
import inspect
import logging
from functools import wraps
from typing import TYPE_CHECKING, Any, ClassVar

from llama_index.core.base.llms.types import (
    ChatMessage,
    ChatResponse,
    LLMMetadata,
    MessageRole,
)
from llama_index.core.llms.llm import LLM
from llama_index.core.types import PydanticProgramMode

from mobilerun.agent.providers.anthropic import (
    ANTHROPIC_API_DEFAULT_MODEL,
    ANTHROPIC_MODELS_WITHOUT_FORCED_TOOL_CHOICE,
    ANTHROPIC_UNSUPPORTED_SAMPLING_PARAMS,
    StreamUsage,
    anthropic_model_context_window,
    anthropic_model_omits_sampling_params,
    collect_stream_usage,
    record_stream_usage,
)
from mobilerun.agent.providers.grok import (
    GROK_API_DEFAULT_MODEL,
    GROK_CONTEXT_WINDOW,
    XAI_API_BASE,
    normalize_grok_model_id,
    sanitize_grok_responses_kwargs,
)
from mobilerun.agent.providers.minimax import (
    MINIMAX_DEFAULT_MODEL,
    MINIMAX_GLOBAL_BASE_URL,
    apply_minimax_defaults,
    is_minimax_base_url,
    warn_if_legacy_minimax_endpoint,
)
from mobilerun.agent.providers.registry import (
    GEMINI_API_DEFAULT_MODEL,
    GEMINI_UNSUPPORTED_SAMPLING_PARAMS,
    OPENAI_API_DEFAULT_MODEL,
    OPENAI_ASTRA_DEFAULT_REASONING_EFFORT,
    OPENAI_GPT6_CONTEXT_WINDOW,
    OPENAI_GPT6_MODELS,
    OPENAI_OAUTH_UNSUPPORTED_MODELS,
    OPENAI_REASONING_EFFORTS,
    gemini_model_omits_sampling_params,
    list_models_for_variant,
    normalize_model_id_for_variant,
)
from mobilerun.agent.usage import track_usage

if TYPE_CHECKING:
    from mobilerun.config_manager.config_manager import LLMProfile

# Configure logging
logger = logging.getLogger("mobilerun")


SUPPORTED_PROVIDERS = [
    "OpenAIResponses",
    "OpenAILike",
    "GoogleGenAI",
    "Ollama",
    "Anthropic",
    "DeepSeek",
    "OpenRouter",
    "MiniMax",
    "XAI",
]

PROVIDER_ALIASES = {
    "openai": "OpenAIResponses",
    "gpt": "OpenAIResponses",
    "gemini": "GoogleGenAI",
    "google": "GoogleGenAI",
    "claude": "Anthropic",
    "openai compatible": "OpenAILike",
    "openai-like": "OpenAILike",
    "openai like": "OpenAILike",
    "openai_compatible": "OpenAILike",
    "openai_like": "OpenAILike",
    "zai": "ZAI",
    "z.ai": "ZAI",
    "xai": "XAI",
}

ZAI_GLOBAL_API_BASE = "https://api.z.ai/api/paas/v4"
# Public Gemini Developer API ids that are not valid on the private
# Antigravity OAuth catalog. Catch these locally so users get the applicable
# OAuth choices instead of a remote model-not-found response.
GEMINI_OAUTH_UNSUPPORTED_MODELS = {
    "gemini-3.8-flash",
    "gemini-3.7-flash",
    "gemini-3.6-flash",
    "gemini-3.5-flash",
    "gemini-3-flash-preview",
    "gemini-3.1-pro-preview",
}
OPENAI_RESPONSES_MODELS_WITHOUT_SAMPLING_PARAMS = {
    "gpt-6-astra",
    "gpt-6.1-sol",
    "gpt-6-sol",
    "gpt-6-luna",
    "gpt-5.6-sol",
    "gpt-5.6-terra",
    "gpt-5.6-luna",
    "gpt-5.4",
    "gpt-5.4-mini",
    "gpt-5.4-nano",
}
OPENAI_RESPONSES_UNSUPPORTED_SAMPLING_PARAMS = {"temperature", "top_p"}
OPENAI_ASTRA_MODEL = "gpt-6-astra"
OPENAI_GPT6_UNSUPPORTED_PARAMS = {"logprobs", "top_logprobs"}
OPENAI_GPT6_UNSUPPORTED_INCLUDE = "message.output_text.logprobs"
DEEPSEEK_DEFAULT_MODEL = "deepseek-flash"
DEEPSEEK_CONTEXT_WINDOW = 1_048_576
DEEPSEEK_FUNCTION_CALLING_MODELS = {"deepseek-flash", "deepseek-v4-pro"}


def normalize_provider_name(provider_name: str) -> str:
    """Map user-facing provider names to Mobilerun runtime providers."""
    stripped = provider_name.strip()
    key = stripped.lower()
    return PROVIDER_ALIASES.get(key, stripped)


def _openai_responses_model_omits_sampling_params(model: object) -> bool:
    return str(model or "").strip() in OPENAI_RESPONSES_MODELS_WITHOUT_SAMPLING_PARAMS


def _validate_openai_oauth_model(model: object) -> None:
    model_id = str(model or "").strip()
    if model_id in OPENAI_OAUTH_UNSUPPORTED_MODELS:
        supported = ", ".join(list_models_for_variant("openai", "oauth"))
        raise ValueError(
            f"Model '{model_id}' is not supported with OpenAI OAuth "
            f"ChatGPT-account credentials. Use {supported}."
        )


def _validate_gemini_oauth_model(model: object) -> None:
    model_id = str(model or "").strip()
    if model_id in GEMINI_OAUTH_UNSUPPORTED_MODELS:
        supported = ", ".join(list_models_for_variant("gemini", "oauth"))
        raise ValueError(
            f"Model '{model_id}' is a Gemini Developer API id and is not valid "
            f"for the Antigravity OAuth catalog. Re-run "
            f"`mobilerun configure gemini` and pick one of: {supported}."
        )


# Default Ollama context size. llama-index's own default (-1) resolves to the
# model's maximum context, which allocates the full KV cache up front (e.g. a
# 256K-context model -> ~19 GB, spilling to CPU) — and because mobilerun sends
# num_ctx per request, it overrides every Ollama-side setting
# (OLLAMA_CONTEXT_LENGTH, Modelfile, /set parameter), so users cannot fix it
# server-side. ``context_window: -1`` in profile kwargs restores model-max.
_OLLAMA_DEFAULT_CONTEXT_WINDOW = 32768

_warned_ollama_kwargs: set[str] = set()


def _prepare_ollama_kwargs(kwargs: dict[str, Any], llm_class: Any) -> dict[str, Any]:
    """Translate provider-portable kwargs for llama-index's Ollama class.

    ``max_tokens`` is not an Ollama constructor field and pydantic silently
    drops it; translate it to ``additional_kwargs.num_predict`` (an explicit
    ``num_predict`` wins). Also default ``context_window`` (see
    ``_OLLAMA_DEFAULT_CONTEXT_WINDOW``) and keep it aligned with an explicit
    ``additional_kwargs.num_ctx`` so the -1 path's hidden ``client.show()``
    lookup is never triggered by mobilerun defaults.
    """
    kwargs = dict(kwargs)
    additional_kwargs = dict(kwargs.get("additional_kwargs") or {})

    if "max_tokens" in kwargs and "max_tokens" not in llm_class.model_fields:
        max_tokens = kwargs.pop("max_tokens")
        if isinstance(max_tokens, bool) or max_tokens is None:
            valid_max_tokens = None
        else:
            try:
                valid_max_tokens = int(max_tokens)
            except (TypeError, ValueError):
                valid_max_tokens = None
        if valid_max_tokens is None:
            logger.warning(
                f"Ignoring non-integer max_tokens={max_tokens!r} for Ollama."
            )
        elif "num_predict" in additional_kwargs:
            if additional_kwargs["num_predict"] != valid_max_tokens:
                logger.warning(
                    f"Both max_tokens={valid_max_tokens} and "
                    f"additional_kwargs.num_predict="
                    f"{additional_kwargs['num_predict']} are set for Ollama; "
                    f"num_predict wins."
                )
        else:
            additional_kwargs["num_predict"] = valid_max_tokens

    if kwargs.get("context_window") is None:
        context_window = _OLLAMA_DEFAULT_CONTEXT_WINDOW
        if "num_ctx" in additional_kwargs:
            try:
                context_window = int(additional_kwargs["num_ctx"])
            except (TypeError, ValueError):
                pass
        kwargs["context_window"] = context_window

    if additional_kwargs:
        kwargs["additional_kwargs"] = additional_kwargs

    for key, value in kwargs.items():
        if value is None or key in llm_class.model_fields:
            continue
        if key not in _warned_ollama_kwargs:
            _warned_ollama_kwargs.add(key)
            logger.warning(
                f"Ollama does not accept the {key!r} option; it will be ignored."
            )

    return kwargs


def _patch_responses_output_parser(responses_cls: Any) -> None:
    """Parse Responses output items one at a time.

    llama-index-llms-openai re-appends earlier message text for every message
    item, so multi-message outputs repeat text.
    """
    original = responses_cls._parse_response_output
    if getattr(original, "_mobilerun_patched", False):
        return

    def parse_response_output(output: list[Any]) -> ChatResponse:
        message = ChatMessage(role=MessageRole.ASSISTANT, blocks=[])
        additional_kwargs: dict[str, Any] = {"built_in_tool_calls": []}
        for item in output:
            parsed = original([item])
            message.blocks.extend(parsed.message.blocks)
            item_kwargs = dict(parsed.additional_kwargs)
            additional_kwargs["built_in_tool_calls"].extend(
                item_kwargs.pop("built_in_tool_calls", [])
            )
            additional_kwargs.update(item_kwargs)
        return ChatResponse(message=message, additional_kwargs=additional_kwargs)

    parse_response_output._mobilerun_patched = True  # type: ignore[attr-defined]
    responses_cls._parse_response_output = builtins.staticmethod(parse_response_output)


def _load_openai_responses(*, grok: bool = False, **kwargs: Any) -> LLM:
    from llama_index.llms.openai.responses import OpenAIResponses

    # Upstream calls the parser through the class, so patch it there.
    _patch_responses_output_parser(OpenAIResponses)

    from mobilerun.agent.utils import llm_openai_responses as adapters

    if grok:
        kwargs = dict(sanitize_grok_responses_kwargs(kwargs))
        additional_kwargs = dict(kwargs.get("additional_kwargs") or {})
        sanitize_grok_responses_kwargs(additional_kwargs)
        # ``store`` is a first-class adapter field; keeping a second copy in
        # additional_kwargs is unnecessary and makes intent harder to inspect.
        additional_kwargs.pop("store", None)
        kwargs["additional_kwargs"] = additional_kwargs

    filtered_kwargs = {k: v for k, v in kwargs.items() if v is not None}
    logger.debug(
        "Initializing MobilerunOpenAIResponses with kwargs: "
        f"{list(filtered_kwargs.keys())}"
    )
    adapter = adapters.MobilerunGrokResponses if grok else adapters.MobilerunOpenAIResponses
    return adapter(**filtered_kwargs)


def _load_google_genai(**kwargs: Any) -> LLM:

    from mobilerun.agent.utils.llm_google_genai import MobilerunGoogleGenAI

    filtered_kwargs = {k: v for k, v in kwargs.items() if v is not None}
    logger.debug(
        "Initializing MobilerunGoogleGenAI with kwargs: "
        f"{list(filtered_kwargs.keys())}"
    )
    return MobilerunGoogleGenAI(**filtered_kwargs)


def _load_anthropic(**kwargs: Any) -> LLM:

    from mobilerun.agent.utils.llm_anthropic import MobilerunAnthropic

    # The upstream adapter defaults to 512 output tokens, which is too small
    # for a manager response that includes a complete control result plus
    # reasoning metadata.  Keep an explicit caller override intact while
    # giving standard Anthropic usage a safe shared default.  OAuth uses its
    # own loader above and deliberately retains its separate output limit.
    if kwargs.get("max_tokens") is None:
        kwargs["max_tokens"] = 2048

    # These models reject the forced tool_choice payload produced by the locked
    # Anthropic adapter for function-based Pydantic programs. Their text path
    # returns the same validated Pydantic result without that field.
    if kwargs.get("model") in ANTHROPIC_MODELS_WITHOUT_FORCED_TOOL_CHOICE:
        kwargs["pydantic_program_mode"] = PydanticProgramMode.LLM

    filtered_kwargs = {k: v for k, v in kwargs.items() if v is not None}
    logger.debug(
        f"Initializing MobilerunAnthropic with kwargs: {list(filtered_kwargs.keys())}"
    )
    return MobilerunAnthropic(**filtered_kwargs)


def _load_deepseek(**kwargs: Any) -> LLM:

    from mobilerun.agent.utils.llm_deepseek import MobilerunDeepSeek

    filtered_kwargs = {k: v for k, v in kwargs.items() if v is not None}
    logger.debug(
        f"Initializing MobilerunDeepSeek with kwargs: {list(filtered_kwargs.keys())}"
    )
    return MobilerunDeepSeek(**filtered_kwargs)


def load_llm(provider_name: str, model: str | None = None, **kwargs: Any) -> LLM:
    """Load and initialize a configured LLM backend.

    Args:
        provider_name: Case-sensitive provider name (e.g. "OpenAIResponses", "Ollama").
        model: Model name (e.g. "gpt-6-astra", "gemini-3.8-flash").
        **kwargs: Keyword arguments for the LLM class constructor.

    Returns:
        An initialized LLM instance.
    """
    if not provider_name:
        raise ValueError("provider_name cannot be empty.")

    provider_name = normalize_provider_name(provider_name)

    if model is not None:
        if provider_name == "OpenAIResponses":
            model = normalize_model_id_for_variant("openai", "api_key", model)
        elif provider_name == "XAI":
            model = normalize_grok_model_id(model)
        elif provider_name == "xai_oauth":
            model = normalize_model_id_for_variant("xai", "oauth", model)
        elif provider_name == "openai_oauth":
            model = normalize_model_id_for_variant("openai", "oauth", model)
        kwargs["model"] = model

    # --- OAuth providers ---
    if provider_name == "openai_oauth":
        from mobilerun.agent.utils.oauth.openai_oauth_llm import OpenAIOAuth

        _validate_openai_oauth_model(kwargs.get("model"))
        return OpenAIOAuth(**{k: v for k, v in kwargs.items() if v is not None})
    if provider_name == "anthropic_oauth":
        from mobilerun.agent.utils.oauth.anthropic_oauth_llm import AnthropicOAuthLLM

        return AnthropicOAuthLLM(**{k: v for k, v in kwargs.items() if v is not None})
    if provider_name == "gemini_oauth_code_assist":
        from mobilerun.agent.utils.oauth.gemini_oauth_code_assist_llm import (
            GeminiOAuthCodeAssistLLM,
        )

        _validate_gemini_oauth_model(kwargs.get("model"))
        # Drop removed/legacy params a stale config YAML might still carry, so
        # construction doesn't fail and the legacy credential slot can't be
        # selected.
        kwargs.pop("consumer_mode", None)
        kwargs.pop("project_id", None)
        kwargs.pop("credential_slot", None)
        return GeminiOAuthCodeAssistLLM(
            **{k: v for k, v in kwargs.items() if v is not None}
        )
    if provider_name == "xai_oauth":
        from mobilerun.agent.utils.oauth.grok_oauth_llm import GrokOAuth

        return GrokOAuth(**{k: v for k, v in kwargs.items() if v is not None})

    # Legacy aliases: MiniMax and DeepSeek route through OpenAILike.
    if provider_name == "MiniMax":
        import os

        api_key = kwargs.get("api_key")
        if not isinstance(api_key, str) or not api_key.strip():
            api_key = os.environ.get("MINIMAX_API_KEY")
        if not isinstance(api_key, str) or not api_key.strip():
            raise ValueError(
                "MiniMax requires an API key. Pass api_key explicitly or set "
                "MINIMAX_API_KEY."
            )

        provider_name = "OpenAILike"
        kwargs["api_key"] = api_key
        kwargs.setdefault("model", MINIMAX_DEFAULT_MODEL)
        kwargs.setdefault("is_chat_model", True)
        base_url = kwargs.pop("base_url", None)
        if not kwargs.get("api_base"):
            kwargs["api_base"] = base_url or MINIMAX_GLOBAL_BASE_URL
        warn_if_legacy_minimax_endpoint(kwargs.get("api_base"))
        kwargs = apply_minimax_defaults(kwargs)

    if provider_name == "ZAI":
        provider_name = "OpenAILike"
        kwargs.setdefault("is_chat_model", True)
        if "base_url" in kwargs and "api_base" not in kwargs:
            kwargs["api_base"] = kwargs.pop("base_url")
        kwargs.setdefault("api_base", ZAI_GLOBAL_API_BASE)

    if provider_name == "XAI":
        import os

        # Mobilerun's reasoning mode selects its agent architecture. It does
        # not opt Grok into a provider-specific reasoning effort.
        kwargs.pop("reasoning_options", None)
        api_key = kwargs.get("api_key")
        if not isinstance(api_key, str) or not api_key.strip():
            api_key = os.environ.get("XAI_API_KEY")
        if not isinstance(api_key, str) or not api_key.strip():
            raise ValueError(
                "XAI requires an API key. Pass api_key explicitly or set "
                "XAI_API_KEY."
            )

        kwargs["api_key"] = api_key
        # The lowercase runtime alias should be useful without a separately
        # generated profile. Keep its implicit model aligned with the catalog.
        kwargs.setdefault("model", GROK_API_DEFAULT_MODEL)
        # XAI_API_KEY must only ever be sent to xAI's pinned endpoint. Ignore
        # generic CLI/profile URL overrides rather than allowing a malicious
        # config to redirect the bearer credential to another host.
        kwargs.pop("base_url", None)
        kwargs["api_base"] = XAI_API_BASE
        # Grok's catalog context is provider metadata, not a caller-tunable
        # endpoint option. Keep hand-written runtime profiles aligned with the
        # first-class provider catalog as well as generated profiles.
        kwargs["context_window"] = GROK_CONTEXT_WINDOW
        return _load_openai_responses(grok=True, **kwargs)

    if provider_name == "DeepSeek":
        import os

        provider_name = "OpenAILike"
        kwargs.setdefault("api_key", os.environ.get("DEEPSEEK_API_KEY"))
        kwargs.setdefault("model", DEEPSEEK_DEFAULT_MODEL)
        kwargs.setdefault("is_chat_model", True)
        kwargs.setdefault(
            "is_function_calling_model",
            kwargs.get("model") in DEEPSEEK_FUNCTION_CALLING_MODELS,
        )
        kwargs.setdefault("context_window", DEEPSEEK_CONTEXT_WINDOW)
        # Thinking mode rejects the forced tool_choice of function programs.
        kwargs.setdefault("pydantic_program_mode", PydanticProgramMode.LLM)
        if "base_url" in kwargs and "api_base" not in kwargs:
            kwargs["api_base"] = kwargs.pop("base_url")
        kwargs.setdefault("api_base", "https://api.deepseek.com")
        return _load_deepseek(**kwargs)

    # --- Standard providers (inline dispatch) ---
    if provider_name == "OpenAIResponses":
        kwargs.setdefault("model", OPENAI_API_DEFAULT_MODEL)
        return _load_openai_responses(**kwargs)
    elif provider_name == "OpenAILike":
        from llama_index.llms.openai_like import OpenAILike

        llm_class = OpenAILike
        kwargs.setdefault("is_chat_model", True)
        if "base_url" in kwargs and "api_base" not in kwargs:
            kwargs["api_base"] = kwargs.pop("base_url")
        if is_minimax_base_url(kwargs.get("api_base")):
            kwargs = apply_minimax_defaults(kwargs)
    elif provider_name == "GoogleGenAI":
        kwargs.setdefault("model", GEMINI_API_DEFAULT_MODEL)
        return _load_google_genai(**kwargs)
    elif provider_name == "Ollama":
        from llama_index.llms.ollama import Ollama

        llm_class = Ollama
        kwargs = _prepare_ollama_kwargs(kwargs, Ollama)
    elif provider_name == "Anthropic":
        kwargs.setdefault("model", ANTHROPIC_API_DEFAULT_MODEL)
        return _load_anthropic(**kwargs)
    elif provider_name == "OpenRouter":
        from llama_index.llms.openrouter import OpenRouter

        llm_class = OpenRouter
    else:
        raise ValueError(
            f"Unsupported provider '{provider_name}'. "
            f"Supported: {sorted(SUPPORTED_PROVIDERS)}"
        )

    filtered_kwargs = {k: v for k, v in kwargs.items() if v is not None}
    logger.debug(
        f"Initializing {llm_class.__name__} with kwargs: {list(filtered_kwargs.keys())}"
    )
    return llm_class(**filtered_kwargs)


def load_llms_from_profiles(
    profiles: dict[str, "LLMProfile"],
    profile_names: list[str] | None = None,
    **override_kwargs_per_profile,
) -> dict[str, LLM]:
    """
    Load multiple LLMs from LLMProfile objects.

    Args:
        profiles: Dict of profile_name -> LLMProfile objects
        profile_names: List of profile names to load. If None, loads all profiles
        **override_kwargs_per_profile: Dict of profile-specific overrides
            Example: manager={'temperature': 0.1}, executor={'max_tokens': 8000}

    Returns:
        Dict mapping profile names to initialized LLM instances

    Example:
        >>> config = MobileConfig.from_yaml("config.yaml")
        >>> llms = load_llms_from_profiles(config.llm_profiles)
        >>> manager_llm = llms['manager']

        >>> # Load specific profiles with overrides
        >>> llms = load_llms_from_profiles(
        ...     config.llm_profiles,
        ...     profile_names=['manager', 'executor'],
        ...     manager={'temperature': 0.1}
        ... )
    """
    if profile_names is None:
        profile_names = list(profiles.keys())

    llms = {}
    for profile_name in profile_names:
        logger.debug(f"Loading LLM for profile: {profile_name}")

        if profile_name not in profiles:
            raise KeyError(
                f"Profile '{profile_name}' not found. "
                f"Available profiles: {list(profiles.keys())}"
            )

        profile = profiles[profile_name]

        # Get base kwargs from profile
        kwargs = profile.to_load_llm_kwargs()

        # Apply profile-specific overrides if provided
        if profile_name in override_kwargs_per_profile:
            logger.debug(
                f"Applying overrides for {profile_name}: {override_kwargs_per_profile[profile_name]}"
            )
            kwargs.update(override_kwargs_per_profile[profile_name])

        # Load the LLM
        llms[profile_name] = load_llm(provider_name=profile.provider, **kwargs)
        logger.debug(
            f"Successfully loaded {profile_name} LLM: {profile.provider}/{profile.model}"
        )

    return llms


# --- Example Usage ---
if __name__ == "__main__":
    # Install the specific LLM integrations you want to test:
    # pip install \
    #   llama-index-llms-anthropic \
    #   llama-index-llms-gemini \
    #   llama-index-llms-openai

    providers = [
        {
            "name": "Anthropic",
            "model": "claude-sonnet-5",
        },
        {
            "name": "DeepSeek",
            "model": "deepseek-flash",
        },
        {
            "name": "GoogleGenAI",
            "model": "gemini-3.8-flash",
        },
        {
            "name": "OpenAIResponses",
            "model": "gpt-6-astra",
        },
        {
            "name": "Ollama",
            "model": "llama3.2:1b",
            "base_url": "http://localhost:11434",
        },
    ]

    system_prompt = ChatMessage(
        role="system",
        content="You are a personal health and food coach. You are given a user's health and food preferences and you need to recommend a meal plan for them. only output the meal plan, no other text.",
    )

    user_prompt = ChatMessage(
        role="user",
        content="I am a 25 year old male. I am 5'10 and 180 pounds. I am a vegetarian. I am allergic to peanuts and tree nuts. I am allergic to shellfish. I am allergic to eggs. I am allergic to dairy. I am allergic to soy. I am allergic to wheat. I am allergic to corn. I am allergic to oats. I am allergic to rice. I am allergic to barley. I am allergic to rye. I am allergic to oats. I am allergic to rice. I am allergic to barley. I am allergic to rye.",
    )

    messages = [system_prompt, user_prompt]

    for provider in providers:
        print(f"\n{'#' * 35} Loading {provider['name']} {'#' * 35}")
        print("-" * 100)

        try:
            provider_name = provider.pop("name")
            llm = load_llm(provider_name, **provider)
            provider["name"] = provider_name
            print(f"Loaded LLM: {type(llm)}")
            print(f"Model: {llm.metadata}")
            print("-" * 100)

            tracker = track_usage(llm)
            print(f"Tracker: {type(tracker)}")
            print(f"Usage: {tracker.usage}")
            print("-" * 100)

            assert tracker.usage.requests == 0
            assert tracker.usage.request_tokens == 0
            assert tracker.usage.response_tokens == 0
            assert tracker.usage.total_tokens == 0

            res = llm.chat(messages)
            print(f"Response: {res.message.content}")
            print("-" * 100)
            print(f"Usage: {tracker.usage}")

            assert tracker.usage.requests == 1
            assert tracker.usage.request_tokens > 0
            assert tracker.usage.response_tokens > 0
            assert tracker.usage.total_tokens > tracker.usage.request_tokens
            assert tracker.usage.total_tokens > tracker.usage.response_tokens
        except Exception as e:
            print(f"Failed to load and track usage for {provider['name']}: {e}")
