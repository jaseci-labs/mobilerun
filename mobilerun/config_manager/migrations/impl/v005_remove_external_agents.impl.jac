impl migrate(config: Dict[builtins.str, Any]) -> Dict[builtins.str, Any] {
    external_agents: any = config.get("external_agents", {});
    if isinstance(external_agents, `dict) {
        external_agents.pop("mai_ui", None);
        external_agents.pop("autoglm", None);
    }

    return config;
}
