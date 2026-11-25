impl normalize_provider_name(provider_name: builtins.str) -> builtins.str {
    stripped: any = provider_name.strip();
    key: any = stripped.lower();
    return PROVIDER_ALIASES.get(key, stripped);
}

impl _validate_openai_oauth_model(model: builtins.object) -> None {
    model_id: any = `str(model or "").strip();
    if model_id in OPENAI_OAUTH_UNSUPPORTED_MODELS {
        supported: any = ", ".join(list_models_for_variant("openai", "oauth"));
        raise ValueError(
            f"Model '{model_id}' is not supported with OpenAI OAuth ChatGPT-account credentials. Use {supported}.",
        );
    }
}

impl _validate_gemini_oauth_model(model: builtins.object) -> None {
    model_id: any = `str(model or "").strip();
    if model_id in GEMINI_OAUTH_UNSUPPORTED_MODELS {
        supported: any = ", ".join(list_models_for_variant("gemini", "oauth"));
        raise ValueError(
            f"Model '{model_id}' is a Gemini Developer API id and is not valid for the Antigravity OAuth catalog. Re-run `mobilerun configure gemini` and pick one of: {supported}.",
        );
    }
}

impl _prepare_ollama_kwargs(
    kwargs: builtins.dict[builtins.str, Any], llm_class: Any
) -> builtins.dict[builtins.str, Any] {
    kwargs = `dict(kwargs);
    additional_kwargs: any = `dict(kwargs.get("additional_kwargs") or {});

    if "max_tokens" in kwargs and "max_tokens" not in llm_class.model_fields {
        max_tokens: any = kwargs.pop("max_tokens");
        if isinstance(max_tokens, `bool) or max_tokens is None {
            valid_max_tokens: any = None;
        } else {
            try {
                valid_max_tokens = `int(max_tokens);
            } except (TypeError, ValueError) {
                valid_max_tokens = None;
            }
        }
        if valid_max_tokens is None {
            logger.warning(f"Ignoring non-integer max_tokens={max_tokens!r} for Ollama.");
        } elif "num_predict" in additional_kwargs {
            if additional_kwargs["num_predict"] != valid_max_tokens {
                logger.warning(
                    "Both max_tokens="
                        + format(valid_max_tokens, "")
                        + " and additional_kwargs.num_predict="
                        + format(additional_kwargs["num_predict"], "")
                        + " are set for Ollama; num_predict wins.",
                );
            }
        } else {
            additional_kwargs["num_predict"] = valid_max_tokens;
        }
    }

    if kwargs.get("context_window") is None {
        context_window: any = _OLLAMA_DEFAULT_CONTEXT_WINDOW;
        if "num_ctx" in additional_kwargs {
            try {
                context_window = `int(additional_kwargs["num_ctx"]);
            } except (TypeError, ValueError) {}
        }
        kwargs["context_window"] = context_window;
    }

    if additional_kwargs {
        kwargs["additional_kwargs"] = additional_kwargs;
    }

    for (key, value) in kwargs.items() {
        if value is None or key in llm_class.model_fields {
            continue;
        }
        if key not in _warned_ollama_kwargs {
            _warned_ollama_kwargs.add(key);
            logger.warning(f"Ollama does not accept the {key!r} option; it will be ignored.");
        }
    }

    return kwargs;
}

impl _patch_responses_output_parser(responses_cls: Any) -> None {
    original: any;
    original = responses_cls._parse_response_output;
    if getattr(original, "_mobilerun_patched", False) {
        return;
    }

    def parse_response_output(output: builtins.list[Any]) -> ChatResponse {
        message: any = ChatMessage(role=MessageRole.ASSISTANT, blocks=[]);
        additional_kwargs: builtins.dict[builtins.str, Any] = {"built_in_tool_calls": []};
        for item in output {
            parsed: any = original([item]);
            message.blocks.extend(parsed.message.blocks);
            item_kwargs: any = `dict(parsed.additional_kwargs);
            additional_kwargs["built_in_tool_calls"].extend(
                item_kwargs.pop("built_in_tool_calls", [])
            );
            additional_kwargs.update(item_kwargs);
        }
        return ChatResponse(message=message, additional_kwargs=additional_kwargs);
    }

    setattr(parse_response_output as any, "_mobilerun_patched", True);
    responses_cls._parse_response_output = builtins.staticmethod(parse_response_output);
}

impl _load_openai_responses(*, grok: builtins.bool = False, **kwargs: Any) -> LLM {
    import from llama_index.llms.openai.responses { OpenAIResponses }
    _patch_responses_output_parser(OpenAIResponses);

    adapters: any = importlib.import_module("mobilerun.agent.utils.llm_openai_responses");

    if grok {
        kwargs = `dict(sanitize_grok_responses_kwargs(kwargs));
        additional_kwargs: any = `dict(kwargs.get("additional_kwargs") or {});
        sanitize_grok_responses_kwargs(additional_kwargs);
        additional_kwargs.pop("store", None);
        kwargs["additional_kwargs"] = additional_kwargs;
    }

    filtered_kwargs: any = {k: v for (k, v) in kwargs.items() if v is not None};
    logger.debug(
        f"Initializing MobilerunOpenAIResponses with kwargs: {`list(filtered_kwargs.keys())}"
    );
    adapter: any = adapters.MobilerunGrokResponses if grok else adapters.MobilerunOpenAIResponses;
    return adapter(**filtered_kwargs);
}

impl _load_google_genai(**kwargs: Any) -> LLM {
    MobilerunGoogleGenAI: any = importlib.import_module(
        "mobilerun.agent.utils.llm_google_genai"
    ).MobilerunGoogleGenAI;

    filtered_kwargs: any = {k: v for (k, v) in kwargs.items() if v is not None};
    logger.debug(f"Initializing MobilerunGoogleGenAI with kwargs: {`list(filtered_kwargs.keys())}");
    return MobilerunGoogleGenAI(**filtered_kwargs);
}

impl _load_anthropic(**kwargs: Any) -> LLM {
    MobilerunAnthropic: any = importlib.import_module(
        "mobilerun.agent.utils.llm_anthropic"
    ).MobilerunAnthropic;
    if kwargs.get("max_tokens") is None {
        kwargs["max_tokens"] = 2048;
    }
    if kwargs.get("model") in ANTHROPIC_MODELS_WITHOUT_FORCED_TOOL_CHOICE {
        kwargs["pydantic_program_mode"] = PydanticProgramMode.LLM;
    }

    filtered_kwargs: any = {k: v for (k, v) in kwargs.items() if v is not None};
    logger.debug(f"Initializing MobilerunAnthropic with kwargs: {`list(filtered_kwargs.keys())}");
    return MobilerunAnthropic(**filtered_kwargs);
}

impl _load_deepseek(**kwargs: Any) -> LLM {
    MobilerunDeepSeek: any = importlib.import_module(
        "mobilerun.agent.utils.llm_deepseek"
    ).MobilerunDeepSeek;

    filtered_kwargs: any = {k: v for (k, v) in kwargs.items() if v is not None};
    logger.debug(f"Initializing MobilerunDeepSeek with kwargs: {`list(filtered_kwargs.keys())}");
    return MobilerunDeepSeek(**filtered_kwargs);
}

impl load_llm(
    provider_name: builtins.str, model: builtins.str | None = None, **kwargs: Any
) -> LLM {
    if not provider_name {
        raise ValueError("provider_name cannot be empty.");
    }

    provider_name = normalize_provider_name(provider_name);

    if model is not None {
        if provider_name == "OpenAIResponses" {
            model = normalize_model_id_for_variant("openai", "api_key", model);
        } elif provider_name == "XAI" {
            model = normalize_grok_model_id(model);
        } elif provider_name == "xai_oauth" {
            model = normalize_model_id_for_variant("xai", "oauth", model);
        } elif provider_name == "openai_oauth" {
            model = normalize_model_id_for_variant("openai", "oauth", model);
        }
        kwargs["model"] = model;
    }
    if provider_name == "openai_oauth" {
        OpenAIOAuth: any = importlib.import_module(
            "mobilerun.agent.utils.oauth.openai_oauth_llm"
        ).OpenAIOAuth;

        _validate_openai_oauth_model(kwargs.get("model"));
        return OpenAIOAuth(**{k: v for (k, v) in kwargs.items() if v is not None});
    }
    if provider_name == "anthropic_oauth" {
        AnthropicOAuthLLM: any = importlib.import_module(
            "mobilerun.agent.utils.oauth.anthropic_oauth_llm"
        ).AnthropicOAuthLLM;

        return AnthropicOAuthLLM(**{k: v for (k, v) in kwargs.items() if v is not None});
    }
    if provider_name == "gemini_oauth_code_assist" {
        GeminiOAuthCodeAssistLLM: any = importlib.import_module(
            "mobilerun.agent.utils.oauth.gemini_oauth_code_assist_llm"
        ).GeminiOAuthCodeAssistLLM;

        _validate_gemini_oauth_model(kwargs.get("model"));
        kwargs.pop("consumer_mode", None);
        kwargs.pop("project_id", None);
        kwargs.pop("credential_slot", None);
        return GeminiOAuthCodeAssistLLM(**{k: v for (k, v) in kwargs.items() if v is not None});
    }
    if provider_name == "xai_oauth" {
        GrokOAuth: any = importlib.import_module(
            "mobilerun.agent.utils.oauth.grok_oauth_llm"
        ).GrokOAuth;

        return GrokOAuth(**{k: v for (k, v) in kwargs.items() if v is not None});
    }
    if provider_name == "MiniMax" {
        import os;

        api_key: any = kwargs.get("api_key");
        if not isinstance(api_key, `str) or not api_key.strip() {
            api_key = os.environ.get("MINIMAX_API_KEY");
        }
        if not isinstance(api_key, `str) or not api_key.strip() {
            raise ValueError(
                "MiniMax requires an API key. Pass api_key explicitly or set MINIMAX_API_KEY."
            );
        }

        provider_name = "OpenAILike";
        kwargs["api_key"] = api_key;
        kwargs.setdefault("model", MINIMAX_DEFAULT_MODEL);
        kwargs.setdefault("is_chat_model", True);
        base_url: any = kwargs.pop("base_url", None);
        if not kwargs.get("api_base") {
            kwargs["api_base"] = base_url or MINIMAX_GLOBAL_BASE_URL;
        }
        warn_if_legacy_minimax_endpoint(kwargs.get("api_base"));
        kwargs = apply_minimax_defaults(kwargs);
    }

    if provider_name == "ZAI" {
        provider_name = "OpenAILike";
        kwargs.setdefault("is_chat_model", True);
        if "base_url" in kwargs and "api_base" not in kwargs {
            kwargs["api_base"] = kwargs.pop("base_url");
        }
        kwargs.setdefault("api_base", ZAI_GLOBAL_API_BASE);
    }

    if provider_name == "XAI" {
        import os;
        kwargs.pop("reasoning_options", None);
        api_key = kwargs.get("api_key");
        if not isinstance(api_key, `str) or not api_key.strip() {
            api_key = os.environ.get("XAI_API_KEY");
        }
        if not isinstance(api_key, `str) or not api_key.strip() {
            raise ValueError(
                "XAI requires an API key. Pass api_key explicitly or set XAI_API_KEY."
            );
        }

        kwargs["api_key"] = api_key;
        kwargs.setdefault("model", GROK_API_DEFAULT_MODEL);
        kwargs.pop("base_url", None);
        kwargs["api_base"] = XAI_API_BASE;
        kwargs["context_window"] = GROK_CONTEXT_WINDOW;
        return _load_openai_responses(grok=True, **kwargs);
    }

    if provider_name == "DeepSeek" {
        import os;

        provider_name = "OpenAILike";
        kwargs.setdefault("api_key", os.environ.get("DEEPSEEK_API_KEY"));
        kwargs.setdefault("model", DEEPSEEK_DEFAULT_MODEL);
        kwargs.setdefault("is_chat_model", True);
        kwargs.setdefault(
            "is_function_calling_model", kwargs.get("model") in DEEPSEEK_FUNCTION_CALLING_MODELS
        );
        kwargs.setdefault("context_window", DEEPSEEK_CONTEXT_WINDOW);
        kwargs.setdefault("pydantic_program_mode", PydanticProgramMode.LLM);
        if "base_url" in kwargs and "api_base" not in kwargs {
            kwargs["api_base"] = kwargs.pop("base_url");
        }
        kwargs.setdefault("api_base", "https://api.deepseek.com");
        return _load_deepseek(**kwargs);
    }
    if provider_name == "OpenAIResponses" {
        kwargs.setdefault("model", OPENAI_API_DEFAULT_MODEL);
        return _load_openai_responses(**kwargs);
    } elif provider_name == "OpenAILike" {
        import from llama_index.llms.openai_like { OpenAILike }

        llm_class: any = OpenAILike;
        kwargs.setdefault("is_chat_model", True);
        if "base_url" in kwargs and "api_base" not in kwargs {
            kwargs["api_base"] = kwargs.pop("base_url");
        }
        if is_minimax_base_url(kwargs.get("api_base")) {
            kwargs = apply_minimax_defaults(kwargs);
        }
    } elif provider_name == "GoogleGenAI" {
        kwargs.setdefault("model", GEMINI_API_DEFAULT_MODEL);
        return _load_google_genai(**kwargs);
    } elif provider_name == "Ollama" {
        import from llama_index.llms.ollama { Ollama }

        llm_class = Ollama;
        kwargs = _prepare_ollama_kwargs(kwargs, Ollama);
    } elif provider_name == "Anthropic" {
        kwargs.setdefault("model", ANTHROPIC_API_DEFAULT_MODEL);
        return _load_anthropic(**kwargs);
    } elif provider_name == "OpenRouter" {
        import from llama_index.llms.openrouter { OpenRouter }

        llm_class = OpenRouter;
    } else {
        raise ValueError(
            f"Unsupported provider '{provider_name}'. Supported: {sorted(SUPPORTED_PROVIDERS)}"
        );
    }

    filtered_kwargs: any = {k: v for (k, v) in kwargs.items() if v is not None};
    logger.debug(f"Initializing {llm_class.__name__} with kwargs: {`list(filtered_kwargs.keys())}");
    return llm_class(**filtered_kwargs);
}

impl load_llms_from_profiles(
    profiles: builtins.dict[builtins.str, "LLMProfile"],
    profile_names: builtins.list[builtins.str] | None = None,
    **override_kwargs_per_profile,
) -> builtins.dict[builtins.str, LLM] {
    if profile_names is None {
        profile_names = `list(profiles.keys());
    }

    llms: any = {};
    for profile_name in profile_names {
        logger.debug(f"Loading LLM for profile: {profile_name}");

        if profile_name not in profiles {
            raise KeyError(
                f"Profile '{profile_name}' not found. Available profiles: {`list(profiles.keys())}"
            );
        }

        profile: any = profiles[profile_name];
        kwargs: any = profile.to_load_llm_kwargs();
        if profile_name in override_kwargs_per_profile {
            logger.debug(
                f"Applying overrides for {profile_name}: {override_kwargs_per_profile[profile_name]}",
            );
            kwargs.update(override_kwargs_per_profile[profile_name]);
        }
        llms[profile_name] = load_llm(provider_name=profile.provider, **kwargs);
        logger.debug(f"Successfully loaded {profile_name} LLM: {profile.provider}/{profile.model}");
    }

    return llms;
}
