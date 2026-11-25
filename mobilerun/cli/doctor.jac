"""Mobilerun Doctor - System health checks and diagnostics."""

import builtins;

import importlib;

import asyncio;

import json;

import re;

import shutil;

import from dataclasses { dataclass }

import from enum { Enum }

import from typing { Any }

import httpx;

import requests;

import from async_adbutils { AdbDevice, adb }

import from mobilerun_core_local.driver.android.portal {
    GITHUB_API_HOSTS,
    PORTAL_PACKAGE_NAME,
    REPO,
    check_portal_accessibility,
    enable_portal_accessibility,
    get_compatible_portal_version,
    portal_content_uri,
    portal_ime_id,
}

import from mobilerun_core_local.transport.android.portal_client { PortalClient }

import from rich.console { Console }

glob __version__: any = _PACKAGE_VERSION;

glob console: any;

glob PORTAL_REMOTE_PORT: any;

with entry {
    console = Console();

    PORTAL_REMOTE_PORT = 8080;
}

class Status(Enum) {
    static has PASS: any = "pass";

    static has WARN: any = "warn";

    static has FAIL: any = "fail";
}

@dataclass
class CheckResult {
    has name: builtins.str;

    has status: Status;

    has message: builtins.str;

    has detail: builtins.str = "";
}

def _status_icon(status: Status) -> builtins.str;

def _print_result(result: CheckResult, debug: builtins.bool = False) -> None;

"""Parse a version string like '0.4.23' or 'v0.4.23' into a comparable tuple."""
def _parse_version_tuple(version_str: builtins.str) -> builtins.tuple;

"""Like _parse_version_tuple, but '0.7.26-dev' reads as 0.7.26."""
def _parse_portal_version(version_str: builtins.str) -> builtins.tuple;

"""Check Mobilerun SDK version against latest GitHub release."""
async def check_sdk_version(debug: builtins.bool) -> CheckResult;

"""Check config file exists and loads."""
async def check_config(debug: builtins.bool) -> builtins.tuple[CheckResult, Any];

"""Check ADB is available and list devices."""
async def check_adb(debug: builtins.bool) -> CheckResult;

"""Check device connection."""
async def check_device(
    serial: builtins.str | None, debug: builtins.bool
) -> builtins.tuple[CheckResult, AdbDevice | None];

"""Check if Portal APK is installed. Returns (result, is_installed)."""
async def check_portal_installed(
    device: AdbDevice, debug: builtins.bool
) -> builtins.tuple[CheckResult, builtins.bool];

"""Fetch latest portal release version from GitHub."""
def _get_latest_portal_version -> builtins.str | None;

"""Check portal version and compatibility. Returns (result, installed_ver, expected_ver, download_base)."""
async def check_portal_version(
    device: AdbDevice, debug: builtins.bool
) -> builtins.tuple[CheckResult, builtins.str | None, builtins.str | None, builtins.str | None];

"""Check accessibility service. Returns (result, is_enabled)."""
async def check_accessibility(
    device: AdbDevice, debug: builtins.bool
) -> builtins.tuple[CheckResult, builtins.bool];

"""Check content provider connectivity."""
async def check_content_provider(device: AdbDevice, debug: builtins.bool) -> CheckResult;

"""Check TCP mode with explicit steps: enable server, forward port, auth, ping."""
async def check_tcp(device: AdbDevice, debug: builtins.bool) -> CheckResult;

"""Fetch full state and verify a11y_tree, phone_state, device_context are present."""
async def check_portal_state(
    device: AdbDevice, use_tcp: builtins.bool, debug: builtins.bool
) -> builtins.tuple[CheckResult, Any];

"""Take a test screenshot to verify the full capture pipeline."""
async def check_screenshot(portal: Any, debug: builtins.bool) -> CheckResult;

"""Check if Mobilerun keyboard IME is available."""
async def check_keyboard(device: AdbDevice, debug: builtins.bool) -> CheckResult;

"""Enable accessibility service. Returns True on success."""
async def fix_enable_accessibility(device: AdbDevice, debug: builtins.bool) -> builtins.bool;

"""Run all doctor checks and auto-fix where possible."""
async def run_doctor(
    device_serial: builtins.str | None = None, debug: builtins.bool = False
) -> None;

"""Print final summary."""
def _print_summary(results: builtins.list[CheckResult]) -> None;
