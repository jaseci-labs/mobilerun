impl LLMProfile.to_load_llm_kwargs -> Dict[str, Any] {
    if self.provider_family == "minimax" {
        warn_if_legacy_minimax_endpoint(self.api_base or self.base_url);
    }

    result: any = {"model": self.model, "temperature": self.temperature};
    if self.base_url {
        result["base_url"] = self.base_url;
    }
    if self.api_base {
        result["api_base"] = self.api_base;
    }
    if self.credential_path {
        result["credential_path"] = self.credential_path;
    }
    result.update(self.kwargs);
    if self.auth_mode == "oauth" {
        return result;
    }
    env_slot: any = VARIANT_ENV_KEY_SLOT.get(self.provider);
    if env_slot is None and self.provider_family in API_KEY_ENV_VARS {
        env_slot = self.provider_family;
    }
    if env_slot and "api_key" not in result {
        sources: any = load_env_key_sources().get(env_slot);
        if sources is not None {
            if self.api_key_source == "env" {
                api_key: any = sources.shell;
            } elif self.api_key_source == "file" {
                api_key = sources.saved;
            } else {
                api_key = sources.saved or sources.shell;
            }

            if api_key {
                result["api_key"] = api_key;
            } else {
                env_var: any = API_KEY_ENV_VARS.get(env_slot, env_slot.upper());
                raise ValueError(
                    f"No API key found for provider '{self.provider}'. Set {env_var}, save a key in the env file, or switch api_key_source to 'env'/'file'.",
                );
            }
        }
    }
    return result;
}

impl AgentConfig.get_fast_agent_system_prompt_path -> str {
    return `str(PathResolver.resolve(self.fast_agent.system_prompt, must_exist=True));
}

impl AgentConfig.get_fast_agent_user_prompt_path -> str {
    return `str(PathResolver.resolve(self.fast_agent.user_prompt, must_exist=True));
}

impl AgentConfig.get_manager_system_prompt_path -> str {
    prompt_path: any = self.manager.system_prompt;
    if prompt_path is None {
        bundled_prompt_path: any = DEFAULT_STATELESS_MANAGER_SYSTEM_PROMPT
            if self.manager.stateless
            else DEFAULT_MANAGER_SYSTEM_PROMPT;
        prompt_path = PathResolver.get_project_root() / bundled_prompt_path;
    }
    return `str(PathResolver.resolve(prompt_path, must_exist=True));
}

impl AgentConfig.get_executor_system_prompt_path -> str {
    return `str(PathResolver.resolve(self.executor.system_prompt, must_exist=True));
}

impl DeviceConfig.resolve_auth_token -> Optional[str] {
    return os.environ.get("MOBILERUN_DEVICE_TOKEN") or self.auth_token;
}

impl _fill_default_profiles(config: any) -> None {
    if not config.llm_profiles {
        config.llm_profiles = MobileConfig._default_profiles();
    }
}

impl MobileConfig._default_profiles -> Dict[str, LLMProfile] {
    return {
        "manager": LLMProfile(
            provider="GoogleGenAI", model=GEMINI_API_DEFAULT_MODEL, temperature=0.2, kwargs={}
        ),
        "executor": LLMProfile(
            provider="GoogleGenAI", model=GEMINI_API_DEFAULT_MODEL, temperature=0.1, kwargs={}
        ),
        "fast_agent": LLMProfile(
            provider="GoogleGenAI", model=GEMINI_API_DEFAULT_MODEL, temperature=0.2, kwargs={}
        ),
        "app_opener": LLMProfile(
            provider="GoogleGenAI", model=GEMINI_API_DEFAULT_MODEL, temperature=0.0, kwargs={}
        ),
        "structured_output": LLMProfile(
            provider="GoogleGenAI", model=GEMINI_API_DEFAULT_MODEL, temperature=0.0, kwargs={}
        ),
    };
}

impl MobileConfig.to_dict -> Dict[str, Any] {
    result: any = asdict(self);
    result["llm_profiles"] = {
        name: asdict(profile)
        for (name, profile) in self.llm_profiles.items()
    };
    return result;
}

impl MobileConfig.from_dict(data: Dict[str, Any]) -> "MobileConfig" {
    import copy as _copy;

    import from mobilerun.config_manager.migrations { CURRENT_VERSION, migrate }

    if "_version" in data and data["_version"] < CURRENT_VERSION {
        data = migrate(_copy.deepcopy(data));
    }
    llm_profiles: any = {};
    for (name, profile_data) in data.get("llm_profiles", {}).items() {
        llm_profiles[name] = LLMProfile(**profile_data);
    }
    agent_data: any = data.get("agent", {});

    fast_agent_data: any = agent_data.get("fast_agent", {});
    fast_agent_config: any = FastAgentConfig(**fast_agent_data)
        if fast_agent_data
        else FastAgentConfig();

    manager_data: any = agent_data.get("manager", {});
    manager_config: any = ManagerConfig(**manager_data) if manager_data else ManagerConfig();

    executor_data: any = agent_data.get("executor", {});
    executor_config: any = ExecutorConfig(**executor_data) if executor_data else ExecutorConfig();

    app_cards_data: any = agent_data.get("app_cards", {});
    app_cards_config: any = AppCardConfig(**app_cards_data) if app_cards_data else AppCardConfig();

    agent_config: any = AgentConfig(
        name=agent_data.get("name", "mobilerun"),
        max_steps=agent_data.get("max_steps", 15),
        reasoning=agent_data.get("reasoning", False),
        streaming=agent_data.get("streaming", False),
        vision_only=agent_data.get("vision_only", False),
        after_sleep_action=agent_data.get("after_sleep_action", 1.0),
        wait_for_stable_ui=agent_data.get("wait_for_stable_ui", 0.3),
        use_normalized_coordinates=agent_data.get("use_normalized_coordinates", False),
        model_screenshot_max_side=agent_data.get("model_screenshot_max_side"),
        fast_agent=fast_agent_config,
        manager=manager_config,
        executor=executor_config,
        app_cards=app_cards_config,
    );
    external_agents: any = data.get("external_agents", {});
    mcp_data: any = data.get("mcp", {}) or {};
    mcp_servers: any = {};
    servers_data: any = mcp_data.get("servers") or {};
    for (server_name, server_data) in servers_data.items() {
        mcp_servers[server_name] = MCPServerConfig(
            command=server_data.get("command", ""),
            args=server_data.get("args", []),
            env=server_data.get("env", {}),
            prefix=server_data.get("prefix"),
            enabled=server_data.get("enabled", True),
            include_tools=server_data.get("include_tools"),
            exclude_tools=server_data.get("exclude_tools", []),
        );
    }
    mcp_config: any = MCPConfig(enabled=mcp_data.get("enabled", False), servers=mcp_servers);
    return cls(
        agent=agent_config,
        llm_profiles=llm_profiles,
        device=DeviceConfig(**(data.get("device") or {})),
        telemetry=TelemetryConfig(**(data.get("telemetry") or {})),
        tracing=TracingConfig(**(data.get("tracing") or {})),
        logging=LoggingConfig(**(data.get("logging") or {})),
        tools=ToolsConfig(**(data.get("tools") or {})),
        credentials=CredentialsConfig(**(data.get("credentials") or {})),
        external_agents=external_agents,
        mcp=mcp_config,
    );
}

impl MobileConfig.from_yaml(path: str) -> "MobileConfig" {
    f: any;
    with open(path, "r", encoding="utf-8") as f {
        data: any = yaml.safe_load(f);
    }
    return cls.from_dict(data);
}
