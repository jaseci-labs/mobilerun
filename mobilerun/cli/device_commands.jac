"""Direct device action CLI commands.

Provides ``mobilerun device <action>`` subcommands that bypass the LLM agent
and talk directly to the device driver.
"""

import builtins;

import operator;

import importlib;

import asyncio;

import json;

import logging;

import os;

import re;

import sys;

import tempfile;

import from functools { partial, wraps }

import from typing { Optional }

import click;

import from async_adbutils { adb }

import from mobilerun_core_local.driver.android { AndroidDriver }

import from mobilerun_core_local.driver.android.portal { ensure_portal_ready }

import from mobilerun_core_local.driver.ios {
    IOSPortalHttpDriver,
    create_ios_driver,
    discover_ios_device,
    validate_ios_portal_url,
}

import from rich.console { Console }

glob console: any;

glob DEFAULT_CLOUD_BASE_URL: any;

glob CLOUD_API_KEY_ENV: any;

glob _CLOUD_DEVICE_ID_RE: any;

with entry {
    console = Console();

    DEFAULT_CLOUD_BASE_URL = "https://api.mobilerun.ai/v1";
    CLOUD_API_KEY_ENV = "MOBILERUN_CLOUD_API_KEY";
    _CLOUD_DEVICE_ID_RE = re.compile(
        "^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", re.IGNORECASE
    );
}

def _looks_like_cloud_device_id(value: Optional[builtins.str]) -> builtins.bool;

"""Resolve the Mobilerun cloud API key for ``--cloud`` commands.

    Order: the ``MOBILERUN_CLOUD_API_KEY`` env var, then the credential persisted by
    ``mobilerun login`` (``<config dir>/credentials/mobilerun-cloud.json``).
    """
def resolve_cloud_api_key -> Optional[builtins.str];

def _run_coroutine(f, *args_, **kwargs) -> any;

def coro(f) -> any;

"""Common device options for all action commands."""
def device_options(f) -> any;

"""Create and connect a device driver based on CLI options."""
async def _create_driver(
    device: Optional[builtins.str],
    config_path: Optional[builtins.str],
    tcp: Optional[builtins.bool],
    ios: builtins.bool,
    cloud: builtins.bool = False,
    device_id: Optional[builtins.str] = None,
    base_url: Optional[builtins.str] = None,
) -> any;

"""Show INFO progress (e.g. a slow UI-state fetch) on stderr.

    Without this, Python's last-resort handler drops everything below
    WARNING, so a slow device looks like a silent hang. stdout stays
    reserved for the command's output.
    """
def _log_progress_to_stderr -> None;

"""Disable Mobilerun keyboard after direct command execution."""
async def _teardown_android(driver) -> any;

"""Direct device actions (screenshot, tap, swipe, etc.)."""
@click.group()
def device_cli -> any;

"""Take a screenshot and print the saved file path to stdout."""
@getattr(device_cli as any, "command")()
@device_options
@coro
async def screenshot(device, config_path, tcp, ios, cloud, device_id, base_url) -> any;

"""Print the UI accessibility tree with element bounds for targeting."""
@getattr(device_cli as any, "command")()
@device_options
@coro
async def ui(device, config_path, tcp, ios, cloud, device_id, base_url) -> any;

"""Tap at screen coordinates."""
@getattr(device_cli as any, "command")()
@click.argument("x", type=int)
@click.argument("y", type=int)
@device_options
@coro
async def tap(x, y, device, config_path, tcp, ios, cloud, device_id, base_url) -> any;

"""Swipe from (x1, y1) to (x2, y2)."""
@getattr(device_cli as any, "command")("swipe")
@click.argument("x1", type=int)
@click.argument("y1", type=int)
@click.argument("x2", type=int)
@click.argument("y2", type=int)
@click.option("--duration", type=float, default=1.0, show_default=True, help="Duration in seconds")
@device_options
@coro
async def swipe_cmd(
    x1, y1, x2, y2, duration, device, config_path, tcp, ios, cloud, device_id, base_url
) -> any;

"""Long press at screen coordinates."""
@getattr(device_cli as any, "command")("long-press")
@click.argument("x", type=int)
@click.argument("y", type=int)
@device_options
@coro
async def long_press(x, y, device, config_path, tcp, ios, cloud, device_id, base_url) -> any;

"""Type text into the currently focused field. Use 'tap' first to focus."""
@getattr(device_cli as any, "command")("type")
@click.argument("text")
@click.option("--clear", is_flag=True, default=False, help="Clear field before typing")
@device_options
@coro
async def type_text(text, clear, device, config_path, tcp, ios, cloud, device_id, base_url) -> any;

"""Press a system button."""
@getattr(device_cli as any, "command")()
@click.argument("button", type=click.Choice(["back", "home", "enter"], case_sensitive=False))
@device_options
@coro
async def press(button, device, config_path, tcp, ios, cloud, device_id, base_url) -> any;

"""List installed apps."""
@getattr(device_cli as any, "command")()
@click.option("--system/--no-system", default=False, help="Include system apps")
@device_options
@coro
async def apps(system, device, config_path, tcp, ios, cloud, device_id, base_url) -> any;

"""Launch an app by package name."""
@getattr(device_cli as any, "command")()
@click.argument("package")
@device_options
@coro
async def start(package, device, config_path, tcp, ios, cloud, device_id, base_url) -> any;
