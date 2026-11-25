import builtins;

import asyncio;

import logging;

import os;

import from pathlib { Path }

import from threading { Lock }

import from uuid { UUID, uuid4 }

import from posthog { Posthog }

glob logger: any;

glob mobilerun_logger: any;

glob PROJECT_API_KEY: any;

glob HOST: any;

glob USER_ID_PATH: any;

glob RUN_ID: any;

glob TELEMETRY_ENABLED_MESSAGE: any;

glob TELEMETRY_DISABLED_MESSAGE: any;

glob _posthog: Posthog | None;

glob _posthog_lock: any;

with entry {
    logger = logging.getLogger("mobilerun-telemetry");
    mobilerun_logger = logging.getLogger("mobilerun");

    PROJECT_API_KEY = "phc_XyD3HKIsetZeRkmnfaBughs8fXWYArSUFc30C0HmRiO";
    HOST = "https://eu.i.posthog.com";
    USER_ID_PATH = Path.home() / ".droidrun" / "user_id";
    RUN_ID = `str(uuid4());

    TELEMETRY_ENABLED_MESSAGE = "Anonymized telemetry enabled. See https://docs.mobilerun.ai/v3/guides/telemetry for more information.";
    TELEMETRY_DISABLED_MESSAGE = "🛑 Anonymized telemetry disabled. Telemetry can be controlled through Mobilerun configuration or the MOBILERUN_TELEMETRY_ENABLED environment variable.";
    _posthog = None;
    _posthog_lock = Lock();
}

def _get_posthog -> Posthog;

def is_telemetry_enabled(*, config_enabled: builtins.bool = True) -> builtins.bool;

def print_telemetry_message(*, config_enabled: builtins.bool = True) -> None;

with entry {
    print_telemetry_message();
}

def _is_valid_uuid(value: builtins.str) -> builtins.bool;

def get_user_id -> builtins.str;

def capture(
    event: TelemetryEvent,
    user_id: builtins.str | None = None,
    *,
    config_enabled: builtins.bool = True,
) -> None;

async def flush(*, config_enabled: builtins.bool = True) -> None;
