import builtins;

import logging;

import from typing { Dict }

glob logger: any;

with entry {
    logger = logging.getLogger("mobilerun");
}

"""
    Load app cards from server with local fallback.

    Strategy:
    1. Try server first
    2. If server fails or returns empty, try local
    3. Return first non-empty result, or empty if both fail
    """
class CompositeAppCardProvider(AppCardProvider) {
    def init(
        server_url: builtins.str,
        app_cards_dir: builtins.str = "config/app_cards",
        server_timeout: builtins.float = 2.0,
        server_max_retries: builtins.int = 2,
    );

    async def load_app_card(
        package_name: builtins.str,
        instruction: builtins.str = "",
        platform: builtins.str | None = None,
    ) -> builtins.str;

    def clear_cache -> None;

    def get_cache_stats -> any;
}
