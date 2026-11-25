import builtins;

import from __future__ { annotations }

import math;

import threading;

import time;

import from collections.abc { Callable }

"""One monotonic timeout budget shared by every OAuth login stage."""
class OAuthLoginDeadline {
    has _clock: any,
        _sleeper: any,
        _timeout_message: any,
        _expires_at: any;

    def init(
        timeout_seconds: float,
        *,
        timeout_message: str = "OAuth login timed out.",
        clock: Callable[[], float] | None = None,
        sleeper: Callable[[float], None] | None = None,
        _expires_at: float | None = None,
    );

    has expires_at: float {
        getter {
            return self._expires_at;
        }
    }

    def remaining(*, cap: float | None = None) -> float;

    def check -> None;

    def sleep(delay_seconds: float) -> None;

    """Return a view capped by a provider-issued expiry, never a reset budget."""
    def limited_to(timeout_seconds: float) -> OAuthLoginDeadline;
}

"""Launch a browser without letting OS integration consume the login budget."""
def open_browser_async(url: str, opener: Callable[[str], object]) -> None;
