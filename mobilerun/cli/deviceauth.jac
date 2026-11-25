import importlib;

import builtins;

import from jaclang.comptime { target }

import from __future__ { annotations }

import json;

import os;

import tempfile;

import time;

import from dataclasses { dataclass }

import from pathlib { Path }

import from typing { Optional }

import httpx;

glob GRANT_TYPE_DEVICE_CODE: any = "urn:ietf:params:oauth:grant-type:device_code";

glob _REQUEST_TIMEOUT: any = 10.0;

glob _MIN_POLL_INTERVAL: any = 5.0;

glob _SLOW_DOWN_BUMP: any = 5.0;

"""An OAuth 2.0 error response from the token endpoint."""
class DeviceAuthError(Exception) {
    has code: any,
        description: any;

    def init(code: str, description: str = "");
}

@dataclass
class CodeResponse {
    has device_code: str;

    has user_code: str;

    has verification_uri: str;

    has verification_uri_complete: str;

    has expires_in: int;

    has interval: int;
}

def _endpoint(auth_url: str, path: str) -> str;

def request_code(auth_url: str, client_id: str) -> CodeResponse;

def _exchange(auth_url: str, client_id: str, device_code: str) -> str;

def poll_token(auth_url: str, client_id: str, code: CodeResponse) -> str;

def fetch_session(auth_url: str, token: str) -> Optional[dict];

def credential_path -> Path;

def _chmod_private(path: Path, mode: int) -> None;

def save_token(token: str, auth_url: str) -> Path;

def load_credentials -> Optional[dict];

def clear_credentials -> bool;
