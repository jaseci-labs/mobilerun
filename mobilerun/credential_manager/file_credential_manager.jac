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
    def init(credentials: Any);

    def _load(credentials: Any) -> Dict[builtins.str, builtins.str];

    def _load_from_dict(credentials_dict: builtins.dict) -> Dict[builtins.str, builtins.str];

    def _load_from_file(file_path: builtins.str) -> Dict[builtins.str, builtins.str];

    async def resolve_key(key: builtins.str) -> builtins.str;

    async def get_keys -> builtins.list[builtins.str];

    def has_credential(secret_id: builtins.str) -> builtins.bool;

    def __repr__ -> str;
}
