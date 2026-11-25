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

    class def get_user_config_dir -> Path {
        return Path(platformdirs.user_config_dir(cls.APP_NAME));
    }

    class def get_user_config_path -> Path {
        return cls.get_user_config_dir() / cls.CONFIG_FILE;
    }

    class def load(config_path: Optional[str] = None) -> MobileConfig {
        if config_path {
            return cls._load_user_config(Path(config_path));
        }

        env_config: any = os.environ.get("MOBILERUN_CONFIG") or os.environ.get("DROIDRUN_CONFIG");
        if os.environ.get("DROIDRUN_CONFIG") and not os.environ.get("MOBILERUN_CONFIG") {
            import warnings;

            warnings.warn(
                "DROIDRUN_CONFIG is deprecated. Use MOBILERUN_CONFIG instead.",
                DeprecationWarning,
                stacklevel=2,
            );
        }
        if env_config and Path(env_config).exists() {
            return cls._load_user_config(Path(env_config));
        }

        user_config_path: any = cls.get_user_config_path();

        if user_config_path.exists() {
            return cls._load_user_config(user_config_path);
        }

        return cls._init_user_config();
    }

    class def _load_user_config(user_config_path: Path) -> MobileConfig {
        with open(user_config_path, "r", encoding="utf-8") as f {
            user_dict: any = yaml.safe_load(f) or dict[any, any]();
        }

        if "_version" not in user_dict {
            raise OutdatedConfigError(
                f"Config at {user_config_path} is outdated (missing _version).\nPlease update your config based on the latest example:\nhttps://github.com/droidrun/mobilerun/blob/main/mobilerun/config_example.yaml",
            );
        }

        old_version: any = user_dict["_version"];
        user_dict = migrate(user_dict);

        if user_dict.get("_version", 0) > old_version {
            cls._save_dict(user_dict, user_config_path);
        }

        return MobileConfig.from_dict(user_dict);
    }

    class def _init_user_config -> MobileConfig {
        config: any = MobileConfig();
        cls.save(config);
        return config;
    }

    class def save(config: MobileConfig) -> Path {
        config_dict: any = config.to_dict();
        config_dict["_version"] = CURRENT_VERSION;
        return cls._save_dict(config_dict, cls.get_user_config_path());
    }

    class def _save_dict(config_dict: Dict[str, Any], path: Path) -> Path {
        path.parent.mkdir(parents=True, exist_ok=True);
        fd: any = os.open(path, os.O_WRONLY | os.O_CREAT, 384);
        try {
            comptime if target().os != "windows" {
                os.fchmod(fd, 384);
            }
            with os.fdopen(fd, "w", encoding="utf-8") as f {
                fd = -1;
                f.seek(0);
                f.truncate();
                yaml.dump(config_dict, f, default_flow_style=False, sort_keys=False);
            }
        } finally {
            if fd != -1 {
                os.close(fd);
            }
        }
        return path;
    }
}
