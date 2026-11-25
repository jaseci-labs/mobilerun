import importlib;

import builtins;

import logging;

import from typing { Any, Dict, Optional }

import yaml;

glob logger: any;

with entry {
    logger = logging.getLogger("mobilerun");
}

"""
    Credential manager that supports both dict and YAML file sources.
    """
class FileCredentialManager(CredentialManager) {
    """
        Initialize credential manager from dict or file path.

        Args:
            credentials: Either dict or string (file path) or CredentialsConfig
        """
    def init(credentials: Any);

    """Load credentials from dict or file."""
    def _load(credentials: Any) -> Dict[builtins.str, builtins.str];

    """Load credentials from in-memory dict."""
    def _load_from_dict(credentials_dict: builtins.dict) -> Dict[builtins.str, builtins.str];

    """
        Load credentials from YAML file.

        File format:
            secrets:
              MY_PASSWORD:
                value: "secret123"
                enabled: true
              SIMPLE_KEY: "simple_value"  # Auto-enabled

        Returns:
            Dict of enabled secrets {secret_id: secret_value}
        """
    def _load_from_file(file_path: builtins.str) -> Dict[builtins.str, builtins.str];

    """Get secret value by key."""
    async def resolve_key(key: builtins.str) -> builtins.str;

    """Get all available credential keys."""
    async def get_keys -> builtins.list[builtins.str];

    """Check if secret ID exists."""
    def has_credential(secret_id: builtins.str) -> builtins.bool;

    """String representation."""
    def __repr__ -> str;
}
