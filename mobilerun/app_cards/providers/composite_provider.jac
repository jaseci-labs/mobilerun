"""
Composite app card provider.

Tries server first, falls back to local if server fails or returns empty.
"""

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
    """
        Initialize composite provider.

        Args:
            server_url: Base URL of the app card server
            app_cards_dir: Directory containing the android/ and ios/ card folders
            server_timeout: Server request timeout in seconds
            server_max_retries: Number of server retry attempts
        """
    def init(
        server_url: builtins.str,
        app_cards_dir: builtins.str = "config/app_cards",
        server_timeout: builtins.float = 2.0,
        server_max_retries: builtins.int = 2,
    );

    """
        Load app card with server-first, local-fallback strategy.

        Args:
            package_name: Android package name or iOS bundle id
            instruction: User instruction/goal
            platform: "android" or "ios", when known

        Returns:
            App card content from server or local, or empty string if both fail
        """
    async def load_app_card(
        package_name: builtins.str,
        instruction: builtins.str = "",
        platform: builtins.str | None = None,
    ) -> builtins.str;

    """Clear caches in both providers."""
    def clear_cache -> None;

    """
        Get cache statistics from both providers.

        Returns:
            Dict with cache stats from server and local providers
        """
    def get_cache_stats -> any;
}
