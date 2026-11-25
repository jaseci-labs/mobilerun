impl gemini_model_omits_sampling_params(model: object) -> bool {
    model_id: any = `str(model or "").strip();
    return model_id.startswith(("gemini-3", "gemini-4"))
        or operator.eq(model_id, "gemini-pro-agent");
}

impl list_provider_families -> tuple[ProviderFamilySpec, ...] {
    return PROVIDER_FAMILIES;
}

impl get_provider_family(family_id: str) -> ProviderFamilySpec {
    for family in PROVIDER_FAMILIES {
        if family.id == family_id {
            return family;
        }
    }
    raise KeyError(f"Unknown provider family: {family_id}");
}

impl list_auth_modes(family_id: str) -> tuple[str, ...] {
    family: any = get_provider_family(family_id);
    return `tuple(variant.auth_mode for variant in family.variants);
}

impl resolve_provider_variant(family_id: str, auth_mode: str | None = None) -> ProviderVariantSpec {
    family: any = get_provider_family(family_id);
    if auth_mode is None {
        if len(family.variants) != 1 {
            raise ValueError(f"Provider family {family_id} requires an auth mode selection.");
        }
        return family.variants[0];
    }
    for variant in family.variants {
        if variant.auth_mode == auth_mode {
            return variant;
        }
    }
    raise KeyError(f"Unknown auth mode {auth_mode!r} for provider family {family_id}");
}

impl list_models_for_variant(family_id: str, auth_mode: str | None = None) -> tuple[str, ...] {
    return resolve_provider_variant(family_id, auth_mode).models;
}

impl model_display_name_for_variant(family_id: str, auth_mode: str | None, model_id: str) -> str {
    variant: any = resolve_provider_variant(family_id, auth_mode);
    if variant.id == "gemini_oauth_code_assist" {
        return _GEMINI_OAUTH_MODEL_DISPLAY_NAMES.get(model_id, model_id);
    }
    return model_id;
}

impl normalize_model_id_for_variant(family_id: str, auth_mode: str | None, model_id: str) -> str {
    variant: any = resolve_provider_variant(family_id, auth_mode);
    known_model_ids: any = `set(variant.models);
    if family_id == "openai" {
        known_model_ids.update(OPENAI_LEGACY_MODELS);
    } elif family_id == "xai" {
        known_model_ids.update(GROK_API_MODELS, GROK_OAUTH_MODELS, GROK_OAUTH_LEGACY_MODELS);
    }
    if family_id == "openai" and auth_mode == "oauth" {
        known_model_ids.update(OPENAI_OAUTH_UNSUPPORTED_MODELS);
    }

    alias_prefixes: tuple[str, ...] = ();
    if family_id == "openai" and auth_mode == "api_key" {
        alias_prefixes = ("openai/",);
    } elif family_id == "openai" and auth_mode == "oauth" {
        alias_prefixes = ("openai-codex/", "openai/");
    }

    candidate: any = model_id;
    for prefix in alias_prefixes {
        if candidate.startswith(prefix) {
            candidate = candidate[len(prefix):];
            break;
        }
    }

    if family_id == "openai" {
        candidate = OPENAI_MODEL_ALIASES.get(candidate, candidate);
    } elif family_id == "xai" {
        candidate = normalize_grok_model_id(candidate);
    }

    if candidate in known_model_ids {
        return candidate;
    }

    return model_id;
}
