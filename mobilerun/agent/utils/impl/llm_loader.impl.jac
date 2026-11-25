impl _get_required_profiles(
    config: MobileConfig, output_model: Type[BaseModel] | None = None
) -> List[builtins.str] {
    if config.agent.reasoning {
        profiles: any = ["manager", "executor", "app_opener"];
    } else {
        profiles = ["fast_agent", "app_opener"];
    }
    if output_model is not None {
        profiles.append("structured_output");
    }

    return profiles;
}

impl validate_llm_dict(
    config: MobileConfig,
    llms: builtins.dict[builtins.str, LLM],
    output_model: Type[BaseModel] | None = None,
) -> List[builtins.str] {
    required_profiles: any = _get_required_profiles(config, output_model);
    missing_profiles: any = [name for name in required_profiles if name not in llms];

    if missing_profiles {
        available_profiles: any = `list(llms.keys());
        raise ValueError(
            "Missing required LLM profiles: "
                + format(", ".join(missing_profiles), "")
                + ".\nAvailable profiles: "
                + format(", ".join(available_profiles), "")
                + ".\nPlease add the missing profiles to your config.",
        );
    }

    return required_profiles;
}

impl validate_llm_profiles(
    config: MobileConfig, output_model: Type[BaseModel] | None = None
) -> List[builtins.str] {
    required_profiles: any = _get_required_profiles(config, output_model);
    missing_profiles: any = [name for name in required_profiles if name not in config.llm_profiles];

    if missing_profiles {
        available_profiles: any = `list(config.llm_profiles.keys());
        raise ValueError(
            "Missing required LLM profiles in config: "
                + format(", ".join(missing_profiles), "")
                + ".\nAvailable profiles: "
                + format(", ".join(available_profiles), "")
                + ".\nPlease add the missing profiles to your config.",
        );
    }

    return required_profiles;
}

impl load_agent_llms(
    config: MobileConfig,
    custom_provider: builtins.str | None = None,
    custom_model: builtins.str | None = None,
    temperature: builtins.float | None = None,
    output_model: Type[BaseModel] | None = None,
    **kwargs: Any,
) -> builtins.dict[builtins.str, LLM] {
    if custom_provider is not None or custom_model is not None {
        logger.debug("🔧 Using custom LLM for all agents");
        if custom_provider is None {
            custom_provider = `list(config.llm_profiles.values())[0].provider;
        }
        if custom_model is None {
            custom_model = `list(config.llm_profiles.values())[0].model;
        }
        llm_kwargs: any = {};
        if temperature is not None {
            llm_kwargs["temperature"] = temperature;
        } else {
            llm_kwargs["temperature"] = kwargs.get("temperature", 0.3);
        }
        llm_kwargs.update(kwargs);
        custom_llm: any = load_llm(provider_name=custom_provider, model=custom_model, **llm_kwargs);
        llms: any = {
            "manager": custom_llm,
            "executor": custom_llm,
            "fast_agent": custom_llm,
            "app_opener": custom_llm,
        };
        if output_model is not None {
            llms["structured_output"] = custom_llm;
        }

        logger.debug(f"🧠 Custom LLM ready: {custom_provider}/{custom_model}");
        return llms;
    }
    logger.debug("📋 Loading LLMs from config profiles...");
    profile_names: any = validate_llm_profiles(config, output_model);
    overrides: any = {};
    if temperature is not None {
        overrides = {name: {"temperature": temperature} for name in profile_names};
    }
    if kwargs {
        for name in profile_names {
            if name not in overrides {
                overrides[name] = {};
            }
            overrides[name].update(kwargs);
        }
    }
    llms = load_llms_from_profiles(config.llm_profiles, profile_names=profile_names, **overrides);
    logger.debug(f"🧠 Loaded {len(llms)} agent-specific LLMs from profiles");

    return llms;
}

impl merge_llms_with_config(
    config: MobileConfig,
    llms: builtins.dict[builtins.str, LLM],
    output_model: Type[BaseModel] | None = None,
    **kwargs: Any,
) -> builtins.dict[builtins.str, LLM] {
    required: any = _get_required_profiles(config, output_model);

    missing: any = [name for name in required if name not in llms];
    if not missing {
        return llms;
    }

    logger.debug(
        "🔁 Merging provided LLMs with config for missing profiles: "
            + format(", ".join(missing), ""),
    );
    overrides: builtins.dict[builtins.str, builtins.dict] = {};
    temperature: any = kwargs.get("temperature", None);
    if temperature is not None {
        overrides = {name: {"temperature": temperature} for name in missing};
    }

    if kwargs {
        for name in missing {
            if name not in overrides {
                overrides[name] = {};
            }
            overrides[name].update(kwargs);
        }
    }

    loaded: any = load_llms_from_profiles(config.llm_profiles, profile_names=missing, **overrides);

    merged: any = {**llms, **loaded};
    logger.debug("✅ Merged LLMs. Loaded: " + format(", ".join(`list(loaded.keys())), ""));
    return merged;
}
