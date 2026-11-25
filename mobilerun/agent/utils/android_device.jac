"""Android device selection."""

import builtins;

import os;

import from async_adbutils { adb }

import from mobilerun_core_local.driver.android { AndroidPortalHttpDriver }

"""No single Android device could be selected."""
obj AndroidDeviceSelectionError(ValueError) {
    def __repr__ -> str;

    def __eq__(other: any) -> bool;

    def __hash__ -> int;
}

"""True when ``device`` is a Portal HTTP base URL rather than an ADB serial."""
def is_portal_http_url(device: builtins.str | None) -> builtins.bool;

"""Return an unconnected driver that reaches Portal over HTTP, without ADB."""
def create_android_portal_http_driver(
    url: builtins.str, token: builtins.str | None
) -> AndroidPortalHttpDriver;

"""Return ``serial``, else ``ANDROID_SERIAL``, else the only online device."""
async def resolve_android_serial(serial: builtins.str | None = None) -> builtins.str;
