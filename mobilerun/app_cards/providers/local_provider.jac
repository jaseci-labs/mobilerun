"""
Local file-based app card provider.

Loads app cards from one folder per platform, each with its own
app_cards.json mapping.
"""

import builtins;

import decimal as _jacm;

import json;

import logging;

import from pathlib { Path }

import from typing { Dict }

glob logger: any;

glob PLATFORMS: any;

glob _MAPPING_FILE: any;

with entry {
    logger = logging.getLogger("mobilerun");

    PLATFORMS = ("android", "ios");
    _MAPPING_FILE = "app_cards.json";
}

"""Use the working-dir folder if it has app cards, else the package one."""
def _resolve_cards_folder(app_cards_dir: builtins.str) -> Path;

def _warn_if_flat(folder: Path) -> None;

"""Load app cards from local filesystem with in-memory caching.

    Layout: <app_cards_dir>/android/app_cards.json and
    <app_cards_dir>/ios/app_cards.json, each mapping an app id to a card
    file in the same folder.
    """
class LocalAppCardProvider(AppCardProvider) {
    """
        Initialize local provider.

        Args:
            app_cards_dir: Directory containing the android/ and ios/ card folders
        """
    def init(app_cards_dir: builtins.str = "config/app_cards");

    """
        Load app card for a package name from local files.

        Args:
            package_name: Android package name or iOS bundle id
            instruction: User instruction (for cache key consistency, not used in loading)
            platform: "android" or "ios", when known

        Returns:
            App card content or empty string if not found
        """
    def load_app_card(
        package_name: builtins.str,
        instruction: builtins.str = "",
        platform: builtins.str | None = None,
    ) -> builtins.str;

    """Clear content cache (useful for testing or runtime reloading)."""
    def clear_cache -> None;

    """
        Get cache statistics.

        Returns:
            Dict with cache stats (useful for debugging)
        """
    def get_cache_stats -> Dict[builtins.str, builtins.int];
}
