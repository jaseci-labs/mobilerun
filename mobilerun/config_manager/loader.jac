import builtins;

import from jaclang.comptime { target }

import from __future__ { annotations }

import os;

import from pathlib { Path }

import from typing { Any, Dict, Optional }

import platformdirs;

import yaml;

"""Raised when user config is missing _version field."""
class OutdatedConfigError(Exception) {}

"""Unified config loading with user config support."""
class ConfigLoader {
    static has APP_NAME: any = "droidrun";

    static has CONFIG_FILE: any = "config.yaml";

    class def get_user_config_dir -> Path;

    class def get_user_config_path -> Path;

    class def load(config_path: Optional[str] = None) -> MobileConfig;

    class def _load_user_config(user_config_path: Path) -> MobileConfig;

    class def _init_user_config -> MobileConfig;

    class def save(config: MobileConfig) -> Path;

    class def _save_dict(config_dict: Dict[str, Any], path: Path) -> Path;
}
