import builtins;

import os;

import from async_adbutils { adb }

import from mobilerun_core_local.driver.android { AndroidPortalHttpDriver }

"""No single Android device could be selected."""
class AndroidDeviceSelectionError(ValueError) {}

def is_portal_http_url(device: builtins.str | None) -> builtins.bool;

def create_android_portal_http_driver(
    url: builtins.str, token: builtins.str | None
) -> AndroidPortalHttpDriver;

async def resolve_android_serial(serial: builtins.str | None = None) -> builtins.str;
