"""Device driver compat surface for Mobilerun.

All driver implementations live in ``mobilerun-core-local`` (cloud ones
behind its ``[cloud]`` extra). Framework code imports them from there
directly; this package is kept only so the historical public
``mobilerun.tools.driver`` import path keeps working for external consumers.
"""

import from mobilerun_core_local.driver.android { AndroidDriver }

import from mobilerun_core_local.driver.base { DeviceDisconnectedError, DeviceDriver }

import from mobilerun_core_local.driver.cloud { CloudDriver }

import from mobilerun_core_local.driver.ios { IOSDriver }

import from mobilerun_core_local.driver.recording { RecordingDriver }

import from mobilerun_core_local.driver.stealth { StealthDriver }

import from mobilerun_core_local.driver.visual_remote { VisualRemoteDriver }

glob __all__: any = [
    "DeviceDisconnectedError",
    "DeviceDriver",
    "AndroidDriver",
    "CloudDriver",
    "IOSDriver",
    "RecordingDriver",
    "StealthDriver",
    "VisualRemoteDriver",
];
