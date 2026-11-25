impl migrate(config: Dict[builtins.str, Any]) -> Dict[builtins.str, Any] {
    device: any = config.setdefault("device", {});
    device.setdefault("auto_setup", True);
    return config;
}
