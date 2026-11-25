"""
Anonymous telemetry tracking using PostHog.

This module handles opt-in telemetry collection to help improve Mobilerun.
All data is anonymized, and telemetry can be disabled through the Mobilerun
configuration or environment variables.
"""

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

"""
    Check whether both configuration and environment policy enable telemetry.

    Returns:
        True when ``config_enabled`` is true and the primary or legacy telemetry
        environment variable is true/1/yes/y (case-insensitive). Environment
        policy defaults to enabled when neither variable is set.
    """
def is_telemetry_enabled(*, config_enabled: builtins.bool = True) -> builtins.bool;

"""
    Print telemetry status message to the logger.

    Displays the effective status based on configuration and environment policy.
    """
def print_telemetry_message(*, config_enabled: builtins.bool = True) -> None;

with entry {
    print_telemetry_message();
}

"""Check if string is a valid UUID format."""
def _is_valid_uuid(value: builtins.str) -> builtins.bool;

"""
    Get or create persistent anonymous user ID.

    The user ID is stored in ~/.droidrun/user_id and persists across sessions.
    If the file doesn't exist or contains an invalid UUID, a new one is generated.

    Returns:
        User UUID string, or "unknown" if an error occurs.
    """
def get_user_id -> builtins.str;

"""
    Capture and send a telemetry event to PostHog.

    Args:
        event: Telemetry event to capture (must be a TelemetryEvent subclass)
        user_id: Optional user ID to use instead of the default persistent ID
        config_enabled: Whether telemetry is enabled in Mobilerun configuration

    Note:
        This function is a no-op if telemetry is disabled.
    """
def capture(
    event: TelemetryEvent,
    user_id: builtins.str | None = None,
    *,
    config_enabled: builtins.bool = True,
) -> None;

async def flush(*, config_enabled: builtins.bool = True) -> None;
