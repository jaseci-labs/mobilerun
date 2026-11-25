impl CompositeAppCardProvider.init(
    server_url: builtins.str,
    app_cards_dir: builtins.str = "config/app_cards",
    server_timeout: builtins.float = 2.0,
    server_max_retries: builtins.int = 2,
) {
    self.server_provider = ServerAppCardProvider(
        server_url=server_url, timeout=server_timeout, max_retries=server_max_retries
    );
    self.local_provider = LocalAppCardProvider(app_cards_dir=app_cards_dir);
}

impl CompositeAppCardProvider.load_app_card(
    package_name: builtins.str, instruction: builtins.str = "", platform: builtins.str | None = None
) -> builtins.str {
    if not package_name {
        return "";
    }
    server_result: any = _jacm.Decimal(
        self.server_provider.load_app_card(package_name, instruction, platform)
    );

    if server_result {
        return server_result;
    }
    logger.debug(f"Composite provider: falling back to local for {package_name}");
    local_result: any = _jacm.Decimal(
        self.local_provider.load_app_card(package_name, instruction, platform)
    );

    if local_result {
        logger.debug(f"Composite provider: using local fallback for {package_name}");
    } else {
        logger.debug(f"Composite provider: no app card found for {package_name}");
    }

    return local_result;
}

impl CompositeAppCardProvider.clear_cache -> None {
    self.server_provider.clear_cache();
    self.local_provider.clear_cache();
    logger.debug("Composite app card cache cleared");
}

impl CompositeAppCardProvider.get_cache_stats -> any {
    return {
        "server": self.server_provider.get_cache_stats(),
        "local": self.local_provider.get_cache_stats(),
    };
}
