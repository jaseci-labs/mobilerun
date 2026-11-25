import importlib;

import builtins;

import inspect;

import logging;

import from functools { wraps }

import from typing { TYPE_CHECKING, Any, ClassVar }

import from llama_index.core.base.llms.types { ChatMessage, ChatResponse, LLMMetadata, MessageRole }

import from llama_index.core.llms.llm { LLM }

import from llama_index.core.types { PydanticProgramMode }

glob logger: any;

glob SUPPORTED_PROVIDERS: any;

glob PROVIDER_ALIASES: any;

glob ZAI_GLOBAL_API_BASE: any;

glob GEMINI_OAUTH_UNSUPPORTED_MODELS: any;

glob DEEPSEEK_DEFAULT_MODEL: any;

glob DEEPSEEK_CONTEXT_WINDOW: any;

glob DEEPSEEK_FUNCTION_CALLING_MODELS: any;

glob _OLLAMA_DEFAULT_CONTEXT_WINDOW: any;

glob _warned_ollama_kwargs: builtins.set[builtins.str];

glob providers: any;

glob system_prompt: any;

glob user_prompt: any;

glob messages: any;

glob provider: any;

glob provider_name: any;

glob llm: any;

glob tracker: any;

glob res: any;

with entry {
    logger = logging.getLogger("mobilerun");

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
    ];

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
    };

    ZAI_GLOBAL_API_BASE = "https://api.z.ai/api/paas/v4";
    GEMINI_OAUTH_UNSUPPORTED_MODELS = {
        "gemini-3.8-flash",
        "gemini-3.7-flash",
        "gemini-3.6-flash",
        "gemini-3.5-flash",
        "gemini-3-flash-preview",
        "gemini-3.1-pro-preview",
    };
    DEEPSEEK_DEFAULT_MODEL = "deepseek-flash";
    DEEPSEEK_CONTEXT_WINDOW = 1048576;
    DEEPSEEK_FUNCTION_CALLING_MODELS = {"deepseek-flash", "deepseek-v4-pro"};
}

def normalize_provider_name(provider_name: builtins.str) -> builtins.str;

def _validate_openai_oauth_model(model: builtins.object) -> None;

def _validate_gemini_oauth_model(model: builtins.object) -> None;

with entry {
    _OLLAMA_DEFAULT_CONTEXT_WINDOW = 32768;

    _warned_ollama_kwargs = set[any]();
}

def _prepare_ollama_kwargs(
    kwargs: builtins.dict[builtins.str, Any], llm_class: Any
) -> builtins.dict[builtins.str, Any];

def _patch_responses_output_parser(responses_cls: Any) -> None;

def _load_openai_responses(*, grok: builtins.bool = False, **kwargs: Any) -> LLM;

def _load_google_genai(**kwargs: Any) -> LLM;

def _load_anthropic(**kwargs: Any) -> LLM;

def _load_deepseek(**kwargs: Any) -> LLM;

def load_llm(provider_name: builtins.str, model: builtins.str | None = None, **kwargs: Any) -> LLM;

def load_llms_from_profiles(
    profiles: builtins.dict[builtins.str, "LLMProfile"],
    profile_names: builtins.list[builtins.str] | None = None,
    **override_kwargs_per_profile,
) -> builtins.dict[builtins.str, LLM];

with entry:__main__ {
    providers = [
        {"name": "Anthropic", "model": "claude-sonnet-5"},
        {"name": "DeepSeek", "model": "deepseek-flash"},
        {"name": "GoogleGenAI", "model": "gemini-3.8-flash"},
        {"name": "OpenAIResponses", "model": "gpt-6-astra"},
        {"name": "Ollama", "model": "llama3.2:1b", "base_url": "http://localhost:11434"},
    ];

    system_prompt = ChatMessage(
        role="system",
        content="You are a personal health and food coach. You are given a user's health and food preferences and you need to recommend a meal plan for them. only output the meal plan, no other text.",
    );

    user_prompt = ChatMessage(
        role="user",
        content="I am a 25 year old male. I am 5'10 and 180 pounds. I am a vegetarian. I am allergic to peanuts and tree nuts. I am allergic to shellfish. I am allergic to eggs. I am allergic to dairy. I am allergic to soy. I am allergic to wheat. I am allergic to corn. I am allergic to oats. I am allergic to rice. I am allergic to barley. I am allergic to rye. I am allergic to oats. I am allergic to rice. I am allergic to barley. I am allergic to rye.",
    );

    messages = [system_prompt, user_prompt];

    for provider_ in providers {
        provider = provider_;
        print(
            "\n"
                + format("#" * 35, "")
                + " Loading "
                + format(provider["name"], "")
                + " "
                + format("#" * 35, ""),
        );
        print("-" * 100);

        try {
            provider_name = provider.pop("name");
            llm = load_llm(provider_name, **provider);
            provider["name"] = provider_name;
            print(f"Loaded LLM: {`type(llm)}");
            print(f"Model: {llm.metadata}");
            print("-" * 100);

            tracker = track_usage(llm);
            print(f"Tracker: {`type(tracker)}");
            print(f"Usage: {tracker.usage}");
            print("-" * 100);

            assert tracker.usage.requests == 0;
            assert tracker.usage.request_tokens == 0;
            assert tracker.usage.response_tokens == 0;
            assert tracker.usage.total_tokens == 0;

            res = llm.chat(messages);
            print(f"Response: {res.message.content}");
            print("-" * 100);
            print(f"Usage: {tracker.usage}");

            assert tracker.usage.requests == 1;
            assert tracker.usage.request_tokens > 0;
            assert tracker.usage.response_tokens > 0;
            assert tracker.usage.total_tokens > tracker.usage.request_tokens;
            assert tracker.usage.total_tokens > tracker.usage.response_tokens;
        } except Exception as e {
            print(
                "Failed to load and track usage for "
                    + format(provider["name"], "")
                    + ": "
                    + format(e, ""),
            );
        }
    }
}
