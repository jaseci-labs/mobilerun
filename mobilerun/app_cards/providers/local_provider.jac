import builtins;

import json;

import logging;

import from pathlib { Path }

import from typing { Dict }

glob logger: any = logging.getLogger("mobilerun");

glob PLATFORMS: any = ("android", "ios");

glob _MAPPING_FILE: any = "app_cards.json";

def _resolve_cards_folder(app_cards_dir: builtins.str) -> Path;

def _warn_if_flat(folder: Path) -> None;

"""Load app cards from local filesystem with in-memory caching.

    Layout: <app_cards_dir>/android/app_cards.json and
    <app_cards_dir>/ios/app_cards.json, each mapping an app id to a card
    file in the same folder.
    """
class LocalAppCardProvider(AppCardProvider) {
    def init(app_cards_dir: builtins.str = "config/app_cards");

    async def load_app_card(
        package_name: builtins.str,
        instruction: builtins.str = "",
        platform: builtins.str | None = None,
    ) -> builtins.str;

    def clear_cache -> None;

    def get_cache_stats -> Dict[builtins.str, builtins.int];
}
