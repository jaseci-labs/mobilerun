impl family_choices -> tuple[ProviderFamilySpec, ...] {
    return list_provider_families();
}

impl auth_mode_choices(family_id: str) -> tuple[str, ...] {
    family: any = next(f for f in list_provider_families() if f.id == family_id);
    return `tuple(variant.auth_mode for variant in family.variants);
}

impl variant_models(family_id: str, auth_mode: str) -> tuple[str, ...] {
    variant: any = resolve_provider_variant(family_id, auth_mode);
    return `tuple(variant.models);
}

impl _normalize_generated_temperature(family_id: str, temperature: float) -> float {
    if family_id == "minimax" and not 0 < temperature <= 1 {
        return _MINIMAX_DETERMINISTIC_TEMPERATURE;
    }
    return temperature;
}

impl _probe_zai_chat_completions(
    *, base_url: str, api_key: str, model_id: str, timeout_seconds: float = 5.0
) -> bool {
    try {
        response: any = httpx.post(
            format(base_url.rstrip("/"), "") + "/chat/completions",
            headers={"authorization": f"Bearer {api_key}", "content-type": "application/json"},
            json={
                "model": model_id,
                "stream": False,
                "max_tokens": 1,
                "messages": [{"role": "user", "content": "ping"}],
            },
            timeout=timeout_seconds,
        );
        return response.is_success;
    } except Exception {
        return False;
    }
}

impl _resolve_zai_selection(selection: SetupSelection, base_url: str | None) -> tuple[str
    | None, str] {
    effective_base_url: any = base_url;
    effective_model: any = selection.model;

    if selection.family_id != "zai" {
        return (effective_base_url, effective_model);
    }

    if not effective_base_url {
        effective_base_url = _ZAI_CODING_GLOBAL_BASE_URL
            if selection.auth_mode == "coding_api"
            else _ZAI_GLOBAL_BASE_URL;
    }

    if selection.auth_mode == "coding_api"
        and selection.api_key
        and selection.model == "glm-5"
        and not _probe_zai_chat_completions(
            base_url=effective_base_url, api_key=selection.api_key, model_id="glm-5"
        )
        and _probe_zai_chat_completions(
            base_url=effective_base_url, api_key=selection.api_key, model_id="glm-4.7"
        )
    {
        effective_model = "glm-4.7";
    }

    return (effective_base_url, effective_model);
}

impl create_profile_for_variant(
    variant: ProviderVariantSpec, selection: SetupSelection, *, temperature: float = 0.2
) -> LLMProfile {
    base_url: any = selection.base_url or variant.base_url;
    (base_url, resolved_model) = _resolve_zai_selection(selection, base_url) as any;
    resolved_model = normalize_model_id_for_variant(
        selection.family_id, selection.auth_mode, resolved_model
    );
    kwargs: dict[str, str | int] = `dict(DEFAULT_KWARGS_BY_VARIANT.get(variant.id, {}));
    env_slot: any = VARIANT_ENV_KEY_SLOT.get(variant.id);
    runtime_provider_name: any = variant.runtime_transport_provider_name
        or variant.runtime_provider_name;

    if variant.id == "OpenAILike" {
        if selection.api_key_source != "env" {
            kwargs["api_key"] = selection.api_key or "stub";
        }
    } elif variant.id in {"ZAI", "ZAI_Coding"} {
        if selection.api_key_source != "env" {
            kwargs["api_key"] = selection.api_key or "stub";
        }
    }
    if selection.family_id == "openai" {
        temperature = 1.0;
    } else {
        temperature = _normalize_generated_temperature(selection.family_id, temperature);
    }

    return LLMProfile(
        provider=runtime_provider_name,
        provider_family=selection.family_id,
        auth_mode=selection.auth_mode,
        model=resolved_model,
        temperature=temperature,
        api_key_source=selection.api_key_source,
        base_url=base_url,
        api_base=base_url if runtime_provider_name in {"OpenAILike", "MiniMax", "XAI"} else None,
        credential_path=selection.credential_path or variant.credential_path,
        kwargs=kwargs if env_slot is None or variant.id == "XAI" else {},
    );
}

impl apply_selection_to_roles(
    config: MobileConfig, selection: SetupSelection, roles: Iterable[str]
) -> MobileConfig {
    variant: any = resolve_provider_variant(selection.family_id, selection.auth_mode);
    env_slot: any = VARIANT_ENV_KEY_SLOT.get(variant.id);
    if selection.api_key and env_slot and selection.api_key_source != "env" {
        existing: any = load_env_keys();
        existing[env_slot] = selection.api_key;
        try {
            save_env_keys(existing);
        } except OSError {}
    }

    if variant.id == "anthropic_oauth" {
        config.agent.streaming = False;
    }

    for role in roles {
        if role not in config.llm_profiles {
            continue;
        }
        current: any = config.llm_profiles[role];
        config.llm_profiles[role] = create_profile_for_variant(
            variant, selection, temperature=current.temperature
        );
    }

    if "fast_agent" in roles {
        fast_agent_profile: any = config.llm_profiles.get("fast_agent");
        if fast_agent_profile is not None {
            for hidden_role in HIDDEN_ROLE_FALLBACKS {
                if hidden_role not in config.llm_profiles {
                    continue;
                }
                current = config.llm_profiles[hidden_role];
                config.llm_profiles[hidden_role] = LLMProfile(
                    provider=fast_agent_profile.provider,
                    model=fast_agent_profile.model,
                    temperature=_normalize_generated_temperature(
                        selection.family_id, current.temperature
                    ),
                    base_url=fast_agent_profile.base_url,
                    api_base=fast_agent_profile.api_base,
                    provider_family=fast_agent_profile.provider_family,
                    auth_mode=fast_agent_profile.auth_mode,
                    api_key_source=fast_agent_profile.api_key_source,
                    credential_path=fast_agent_profile.credential_path,
                    kwargs=`dict(fast_agent_profile.kwargs),
                );
            }
        }
    }

    return config;
}
