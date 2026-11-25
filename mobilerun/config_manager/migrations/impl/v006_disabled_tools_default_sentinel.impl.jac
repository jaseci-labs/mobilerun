impl migrate(config: Dict[builtins.str, Any]) -> Dict[builtins.str, Any] {
    tools: any = config.get("tools");
    if not isinstance(tools, `dict) {
        return config;
    }

    disabled: any = tools.get("disabled_tools");
    if isinstance(disabled, `list) and `set(disabled) == _OLD_DEFAULT {
        tools["disabled_tools"] = None;
    }

    return config;
}
