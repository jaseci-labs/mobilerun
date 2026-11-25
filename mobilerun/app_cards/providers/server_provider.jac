"""
Server-based app card provider.

Fetches app cards from a remote HTTP server.
"""

import builtins;

import decimal as _jacm;

import logging;

import from typing { Dict }

import httpx;

glob logger: any;

with entry {
    logger = logging.getLogger("mobilerun");
}

"""Load app cards from remote server with in-memory caching."""
class ServerAppCardProvider(AppCardProvider) {
    """
        Initialize server provider.

        Args:
            server_url: Base URL of the app card server (e.g., "https://api.example.com")
            timeout: Request timeout in seconds
            max_retries: Number of retry attempts on failure
        """
    def init(
        server_url: builtins.str, timeout: builtins.float = 2.0, max_retries: builtins.int = 2
    );

    """
        Load app card from remote server.

        Args:
            package_name: Android package name or iOS bundle id
            instruction: User instruction/goal (sent to server for context)
            platform: "android" or "ios", sent to the server when known

        Returns:
            App card content or empty string if not found or on error
        """
    def load_app_card(
        package_name: builtins.str,
        instruction: builtins.str = "",
        platform: builtins.str | None = None,
    ) -> builtins.str;

    """Clear content cache."""
    def clear_cache -> None;

    """
        Get cache statistics.

        Returns:
            Dict with cache stats (useful for debugging)
        """
    def get_cache_stats -> Dict[builtins.str, builtins.int];
}
