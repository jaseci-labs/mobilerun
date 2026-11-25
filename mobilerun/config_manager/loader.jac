"""Config loading with platform-aware user config and migrations."""

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

    """
        Load config with resolution order:
        1. Explicit config_path argument
        2. MOBILERUN_CONFIG env var
        3. User config (platformdirs config dir for "droidrun", e.g.
           ~/Library/Application Support/droidrun/config.yaml on macOS,
           ~/.config/droidrun/config.yaml on Linux)
        4. Package defaults (creates user config)
        """
    class def load(config_path: Optional[str] = None) -> MobileConfig;

    """Load user config and run migrations."""
    class def _load_user_config(user_config_path: Path) -> MobileConfig;

    """Create user config from defaults on first run."""
    class def _init_user_config -> MobileConfig;

    """Save config to user config path."""
    class def save(config: MobileConfig) -> Path;

    """Save config dict to path."""
    class def _save_dict(config_dict: Dict[str, Any], path: Path) -> Path;
}
