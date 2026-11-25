impl ServerAppCardProvider.init(
    server_url: builtins.str, timeout: builtins.float = 2.0, max_retries: builtins.int = 2
) {
    self.server_url = server_url.rstrip("/");
    self.timeout = timeout;
    self.max_retries = max_retries;
    self._content_cache = {};
}

impl ServerAppCardProvider.load_app_card(
    package_name: builtins.str, instruction: builtins.str = "", platform: builtins.str | None = None
) -> builtins.str {
    if not package_name {
        return "";
    }
    cache_key: any = (package_name, instruction, platform);
    if cache_key in self._content_cache {
        return self._content_cache[cache_key];
    }
    endpoint: any = f"{self.server_url}/app-cards";
    payload: any = {"package_name": package_name, "instruction": instruction};
    if platform {
        payload["platform"] = platform;
    }

    for attempt in range(1, self.max_retries + 1) {
        try {
            async with (httpx.AsyncClient(timeout=self.timeout)) as client {
                response: any = (await client.post(endpoint, json=payload));

                if response.status_code == 200 {
                    data: any = response.json();
                    app_card: any = data.get("app_card", "");
                    self._content_cache[cache_key] = app_card;
                    return app_card;
                } elif response.status_code == 404 {
                    self._content_cache[cache_key] = "";
                    return "";
                } else {
                    logger.warning(
                        f"Server returned status {response.status_code} for {package_name} (attempt {attempt}/{self.max_retries})",
                    );
                }
            }
        } except httpx.TimeoutException {
            logger.warning(
                f"Server request timeout for {package_name} (attempt {attempt}/{self.max_retries})"
            );
        } except httpx.RequestError as e {
            logger.warning(
                f"Server request failed for {package_name}: {e} (attempt {attempt}/{self.max_retries})",
            );
        } except Exception as e {
            logger.warning(
                f"Unexpected error loading app card from server: {e} (attempt {attempt}/{self.max_retries})",
            );
        }
    }
    logger.warning(f"Failed to load app card from server after {self.max_retries} attempts");
    self._content_cache[cache_key] = "";
    return "";
}

impl ServerAppCardProvider.clear_cache -> None {
    self._content_cache.clear();
    logger.debug("Server app card cache cleared");
}

impl ServerAppCardProvider.get_cache_stats -> Dict[builtins.str, builtins.int] {
    return {"content_entries": len(self._content_cache)};
}
