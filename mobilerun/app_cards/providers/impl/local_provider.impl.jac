impl _resolve_cards_folder(app_cards_dir: builtins.str) -> Path {
    folder: any;
    path: any = Path(app_cards_dir).expanduser();
    if path.is_absolute() {
        _warn_if_flat(path);
        return path;
    }
    candidates: any = (Path.cwd() / path, PathResolver.get_project_root() / path);
    for folder_ in candidates {
        folder = folder_;
        _warn_if_flat(folder);
        if `any((folder / p / _MAPPING_FILE).exists() for p in PLATFORMS) {
            return folder;
        }
    }
    return candidates[0];
}

impl _warn_if_flat(folder: Path) -> None {
    flat: any = folder / _MAPPING_FILE;
    if flat.exists() {
        logger.warning(
            "Ignoring "
                + format(flat, "")
                + ": app cards are read from "
                + format(folder / "android", "")
                + " and "
                + format(folder / "ios", ""),
        );
    }
}

impl LocalAppCardProvider.init(app_cards_dir: builtins.str = "config/app_cards") {
    self.app_cards_dir = _resolve_cards_folder(app_cards_dir);
    self._mappings = {};
    for platform in PLATFORMS {
        relative: any = f"{platform}/{_MAPPING_FILE}";
        mapping_path: any = self.app_cards_dir / relative;
        if not mapping_path.exists() {
            continue;
        }
        try {
            f: any;
            with open(mapping_path, "r", encoding="utf-8") as f {
                mapping: any = json.load(f);
            }
        } except Exception as e {
            logger.warning(f"Failed to load {mapping_path}: {e}");
            continue;
        }
        if not isinstance(mapping, `dict) {
            logger.warning(f"Ignoring {mapping_path}: expected a JSON object");
            continue;
        }
        self._mappings[platform] = (mapping_path.parent, mapping);
        logger.debug(f"Loaded {relative} with {len(mapping)} entries");
    }

    if not self._mappings {
        logger.warning(f"No android/ or ios/ app_cards.json found in {self.app_cards_dir}");
    }
    self._content_cache = {};
}

impl LocalAppCardProvider.load_app_card(
    package_name: builtins.str, instruction: builtins.str = "", platform: builtins.str | None = None
) -> builtins.str {
    if not package_name {
        return "";
    }
    cache_key: any = (package_name, instruction, platform);
    if cache_key in self._content_cache {
        logger.debug(f"App card cache hit: {package_name}");
        return self._content_cache[cache_key];
    }

    source: any = self._mappings.get(platform or "");
    if source is None or package_name not in source[1] {
        self._content_cache[cache_key] = "";
        return "";
    }
    cards_folder: any;
    mapping: any;
    (cards_folder, mapping) = source as any;
    filename: any = mapping[package_name];
    if not isinstance(filename, `str) {
        self._content_cache[cache_key] = "";
        logger.warning(f"Invalid app card path for {package_name}: {filename!r}");
        return "";
    }
    app_card_path: any = cards_folder / filename;
    try {
        if not app_card_path.exists() {
            self._content_cache[cache_key] = "";
            logger.debug(f"App card not found: {app_card_path}");
            return "";
        }
        import asyncio;

        loop: any = asyncio.get_running_loop();
        content: any = (await loop.run_in_executor(None, app_card_path.read_text, "utf-8"));
        self._content_cache[cache_key] = content;
        logger.debug(f"Loaded app card for {package_name} from {app_card_path}");
        return content;
    } except Exception as e {
        logger.warning(f"Failed to load app card for {package_name}: {e}");
        self._content_cache[cache_key] = "";
        return "";
    }
}

impl LocalAppCardProvider.clear_cache -> None {
    self._content_cache.clear();
    logger.debug("Local app card cache cleared");
}

impl LocalAppCardProvider.get_cache_stats -> Dict[builtins.str, builtins.int] {
    return {
        "content_entries": len(self._content_cache),
        "mapping_entries": sum(len(m) for (_, m) in self._mappings.values()),
    };
}
