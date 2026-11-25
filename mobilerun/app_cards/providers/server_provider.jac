import builtins;

import logging;

import from typing { Dict }

import httpx;

glob logger: any = logging.getLogger("mobilerun");

"""Load app cards from remote server with in-memory caching."""
class ServerAppCardProvider(AppCardProvider) {
    def init(
        server_url: builtins.str, timeout: builtins.float = 2.0, max_retries: builtins.int = 2
    );

    async def load_app_card(
        package_name: builtins.str,
        instruction: builtins.str = "",
        platform: builtins.str | None = None,
    ) -> builtins.str;

    def clear_cache -> None;

    def get_cache_stats -> Dict[builtins.str, builtins.int];
}
