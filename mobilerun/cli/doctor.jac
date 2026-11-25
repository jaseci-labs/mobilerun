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

glob console: any = Console();

glob PORTAL_REMOTE_PORT: any = 8080;

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

def _parse_version_tuple(version_str: builtins.str) -> builtins.tuple;

def _parse_portal_version(version_str: builtins.str) -> builtins.tuple;

async def check_sdk_version(debug: builtins.bool) -> CheckResult;

async def check_config(debug: builtins.bool) -> builtins.tuple[CheckResult, Any];

async def check_adb(debug: builtins.bool) -> CheckResult;

async def check_device(
    serial: builtins.str | None, debug: builtins.bool
) -> builtins.tuple[CheckResult, AdbDevice | None];

async def check_portal_installed(
    device: AdbDevice, debug: builtins.bool
) -> builtins.tuple[CheckResult, builtins.bool];

def _get_latest_portal_version -> builtins.str | None;

async def check_portal_version(
    device: AdbDevice, debug: builtins.bool
) -> builtins.tuple[CheckResult, builtins.str | None, builtins.str | None, builtins.str | None];

async def check_accessibility(
    device: AdbDevice, debug: builtins.bool
) -> builtins.tuple[CheckResult, builtins.bool];

async def check_content_provider(device: AdbDevice, debug: builtins.bool) -> CheckResult;

async def check_tcp(device: AdbDevice, debug: builtins.bool) -> CheckResult;

async def check_portal_state(
    device: AdbDevice, use_tcp: builtins.bool, debug: builtins.bool
) -> builtins.tuple[CheckResult, Any];

async def check_screenshot(portal: Any, debug: builtins.bool) -> CheckResult;

async def check_keyboard(device: AdbDevice, debug: builtins.bool) -> CheckResult;

async def fix_enable_accessibility(device: AdbDevice, debug: builtins.bool) -> builtins.bool;

async def run_doctor(
    device_serial: builtins.str | None = None, debug: builtins.bool = False
) -> None;

def _print_summary(results: builtins.list[CheckResult]) -> None;
