impl FileCredentialManager.init(credentials: Any) {
    self.path = None;
    self.secrets = self._load(credentials);

    if self.path {
        logger.debug(f"✅ Loaded {len(self.secrets)} secrets from {self.path}");
    } else {
        logger.debug(f"✅ Loaded {len(self.secrets)} secrets from in-memory dict");
    }
}

impl FileCredentialManager._load(credentials: Any) -> Dict[builtins.str, builtins.str] {
    CredentialsConfig: any = importlib.import_module(
        "mobilerun.config_manager.config_manager"
    ).CredentialsConfig;
    if isinstance(credentials, `dict) {
        return self._load_from_dict(credentials);
    }
    if isinstance(credentials, CredentialsConfig) {
        if not credentials.enabled {
            logger.debug("Credentials disabled in config");
            return {};
        }
        self.path = credentials.file_path;
        return self._load_from_file(credentials.file_path);
    }
    if isinstance(credentials, `str) {
        self.path = credentials;
        return self._load_from_file(credentials);
    }

    logger.warning(f"Unknown credentials type: {`type(credentials)}");
    return {};
}

impl FileCredentialManager._load_from_dict(
    credentials_dict: builtins.dict
) -> Dict[builtins.str, builtins.str] {
    secrets: any = {};
    for (secret_id, secret_value) in credentials_dict.items() {
        if isinstance(secret_value, `str) and secret_value {
            secrets[secret_id] = secret_value;
        } else {
            logger.warning(f"Skipped invalid secret: {secret_id} (type={`type(secret_value)})");
        }
    }
    return secrets;
}

impl FileCredentialManager._load_from_file(
    file_path: builtins.str
) -> Dict[builtins.str, builtins.str] {
    path: any = PathResolver.resolve(file_path, must_exist=True);
    with open(path, "r") as f {
        data: any = yaml.safe_load(f);
    }

    if not data or "secrets" not in data {
        logger.warning(f"No 'secrets' section found in {path}");
        return {};
    }

    secrets: any = {};
    for (secret_id, secret_data) in data["secrets"].items() {
        if isinstance(secret_data, `dict) {
            enabled: any = secret_data.get("enabled", True);
            value: any = secret_data.get("value", "");
        } else {
            enabled = True;
            value = secret_data;
        }

        if enabled and value {
            secrets[secret_id] = value;
            logger.debug(f"Loaded secret: {secret_id}");
        } else {
            logger.debug(
                f"Skipped secret: {secret_id} (enabled={enabled}, has_value={`bool(value)})"
            );
        }
    }

    return secrets;
}

impl FileCredentialManager.resolve_key(key: builtins.str) -> builtins.str {
    logger.debug(f"🔑 Accessing secret: '{key}'");

    if key not in self.secrets {
        available: any = `list(self.secrets.keys());
        raise CredentialNotFoundError(f"Secret '{key}' not found. Available: {available}");
    }

    return self.secrets[key];
}

impl FileCredentialManager.get_keys -> builtins.list[builtins.str] {
    return `list(self.secrets.keys());
}

impl FileCredentialManager.has_credential(secret_id: builtins.str) -> builtins.bool {
    return secret_id in self.secrets;
}

impl FileCredentialManager.__repr__ -> str {
    count: any = len(self.secrets);
    if self.path {
        return f"<FileCredentialManager path={self.path} secrets={count}>";
    }
    return f"<FileCredentialManager mode=dict secrets={count}>";
}
