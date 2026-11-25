"""OAuth 2.0 Device Authorization Grant (RFC 8628) client for Mobilerun.

Python port of the mobilerun-ios ``pkg/deviceauth`` flow: request a device
code, poll the better-auth token endpoint until the user approves, and return
the session access token. Transport + storage only — callers handle UI.
"""

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

"""POST /device/code — returns the device + user codes."""
def request_code(auth_url: str, client_id: str) -> CodeResponse;

def _exchange(auth_url: str, client_id: str, device_code: str) -> str;

"""Poll /device/token until approval; return the access token.

    Handles ``authorization_pending`` and ``slow_down`` internally. Raises
    ``DeviceAuthError`` on terminal errors (access_denied, expired_token, ...).
    """
def poll_token(auth_url: str, client_id: str, code: CodeResponse) -> str;

"""GET /get-session with the token as Bearer. None if no active session."""
def fetch_session(auth_url: str, token: str) -> Optional[dict];

def credential_path -> Path;

def _chmod_private(path: Path, mode: int) -> None;

"""Persist the session token to the credentials dir."""
def save_token(token: str, auth_url: str) -> Path;

def load_credentials -> Optional[dict];

"""Delete the saved login. Returns True if a file was removed."""
def clear_credentials -> bool;
