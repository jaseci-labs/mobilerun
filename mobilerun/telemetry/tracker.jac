import builtins;

import asyncio;

import logging;

import os;

import from pathlib { Path }

import from threading { Lock }

import from uuid { UUID, uuid4 }

import from posthog { Posthog }

glob logger: any = logging.getLogger("mobilerun-telemetry");

glob mobilerun_logger: any = logging.getLogger("mobilerun");

glob PROJECT_API_KEY: any = "phc_XyD3HKIsetZeRkmnfaBughs8fXWYArSUFc30C0HmRiO";

glob HOST: any = "https://eu.i.posthog.com";

glob USER_ID_PATH: any = Path.home() / ".droidrun" / "user_id";

glob RUN_ID: any = `str(uuid4());

glob TELEMETRY_ENABLED_MESSAGE: any = "Anonymized telemetry enabled. See https://docs.mobilerun.ai/v3/guides/telemetry for more information.";

glob TELEMETRY_DISABLED_MESSAGE: any = "🛑 Anonymized telemetry disabled. Telemetry can be controlled through Mobilerun configuration or the MOBILERUN_TELEMETRY_ENABLED environment variable.";

glob _posthog: Posthog | None = None;

glob _posthog_lock: any = Lock();

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
