"""StateProvider — orchestrates fetching and parsing device state.

Fetches raw data from a ``DeviceDriver``, applies tree filters/formatters,
and produces a ``UIState`` snapshot.
"""

import builtins;

import operator;

import from __future__ { annotations }

import decimal as _jacm;

import asyncio;

import logging;

import time;

import from copy { copy, deepcopy }

import from types { SimpleNamespace }

import from typing { TYPE_CHECKING, Any, Awaitable, Callable, Dict, List, Optional }

import httpx;

import from mobilerun_core_local.driver.base { DeviceDisconnectedError }

glob logger: any;

glob _RETRY_DELAYS: any;

glob _MAX_RETRIES: any;

glob _RECOVERY_AFTER_ATTEMPT: any;

glob _MAX_TIMEOUT_ATTEMPTS: any;

glob _SLOW_FETCH_NOTICE_S: any;

glob _A11Y_SERVICE_NOT_AVAILABLE: any;

with entry {
    logger = logging.getLogger("mobilerun");
    _RETRY_DELAYS = [1.0, 2.0, 3.0, 5.0, 8.0, 10.0];
    _MAX_RETRIES = 7;
    _RECOVERY_AFTER_ATTEMPT = 5;
    _MAX_TIMEOUT_ATTEMPTS = 2;
    _SLOW_FETCH_NOTICE_S = 3.0;
    _A11Y_SERVICE_NOT_AVAILABLE = "Accessibility service not available";
}

"""True when the device accepted the request but did not answer in time.

    Connect and pool timeouts are excluded: those requests never reached the
    device, so retrying them does not queue work behind a busy one.
    """
def _is_timeout(error: BaseException) -> bool;

"""Await *fetch*, logging once at INFO if it runs past the notice delay."""
async def _fetch_with_notice(
    fetch: Callable[[], Awaitable[Dict[str, Any]]], notice: bool
) -> Dict[str, Any];

glob max_retries_default_: any;

glob recovery_after_default_: any;

with entry {
    max_retries_default_ = _MAX_RETRIES;
    recovery_after_default_ = _RECOVERY_AFTER_ATTEMPT;
}

"""Fetch raw device state with retries, backoff, and mid-retry recovery.

    Args:
        fetch: Async callable that returns the raw state dict from Portal.
        recovery: Optional async callable invoked once after *recovery_after*
            consecutive failures (e.g. restart accessibility service), or
            after the first failure if Portal's service is not available,
            or before the single retry of a timed-out fetch.
        max_retries: Total number of attempts before giving up. Timeouts
            stop after ``_MAX_TIMEOUT_ATTEMPTS`` timed-out attempts.
        retry_delays: Per-attempt delays. If shorter than max_retries - 1,
            the last value is reused for remaining delays.
        recovery_after: Trigger *recovery* after this many failures.

    Returns:
        The raw state dict (guaranteed to contain ``a11y_tree``,
        ``phone_state``, ``device_context``).

    Raises:
        DeviceDisconnectedError: Re-raised immediately.
        Exception: After all retries are exhausted.
    """
async def fetch_state_with_retry(
    fetch: Callable[[], Awaitable[Dict[str, Any]]],
    recovery: Optional[Callable[[], Awaitable[None]]] = None,
    max_retries: int = max_retries_default_,
    retry_delays: Optional[List[float]] = None,
    recovery_after: int = recovery_after_default_,
) -> Dict[str, Any];

"""Base class — subclass to support different platforms."""
obj StateProvider {
    has driver: any;

    static has supported: any = set[any]();

    static has screenshot_matches_input_coords: any = False;

    static has resize_model_screenshot: any = False;

    def init(driver: "DeviceDriver");

    def get_state -> UIState;

    """Read the final observation; subclasses may make this narrower."""
    def get_final_state -> UIState;

    def __repr__ -> str;

    def __eq__(other: any) -> bool;

    def __hash__ -> int;
}

"""True when screenshots attached to LLM messages must be resized (with
    the labeled grid) into the coordinate space the provider declared.

    Falls back to the legacy ``requires_coordinate_tools`` contract: injected
    screenshot-only providers that predate ``resize_model_screenshot`` are
    still treated as screenshot-coordinate mode by the tool registry, prompts,
    and validation, so they must keep receiving resized screenshots too.
    """
def should_resize_model_screenshot(state_provider: Any) -> bool;

"""Resize a screenshot to the exact model-facing dims the provider declared.

    The provider stores ``model_screenshot_width/height`` (resolved from the
    active vision model's effective image size) on each ``get_state``. Resizing
    to those exact dims keeps the image the model grounds on equal to the
    declared coordinate space. Falls back to the legacy max-side resize when no
    dims are available (e.g. injected screenshot-only providers)."""
def resize_model_screenshot_with_grid(state_provider: Any, screenshot: bytes) -> bytes;

"""Resize when required, snapshotting model geometry before offloading."""
async def resize_model_screenshot_async(state_provider: Any, screenshot: bytes) -> bytes;

"""Fetches state from an Android device via ``driver.get_ui_tree()``.

    Includes retry logic with exponential backoff and mid-retry recovery
    (accessibility service restart) for robustness against intermittent
    Portal/a11y failures.
    """
obj AndroidStateProvider(StateProvider) {
    has tree_filter: any,
        tree_formatter: any,
        use_normalized: any,
        _ui_cls: any,
        vision_enabled: any,
        vision_resize_policy: any,
        model_screenshot_width: any,
        model_screenshot_height: any,
        screenshot_matches_input_coords: any,
        _vision_contract_intent: any,
        resize_model_screenshot: any,
        requires_active_contract_for_coords: any;

    static has supported: any = {"element_index", "convert_point"};

    def init(
        driver: "DeviceDriver",
        tree_filter: "TreeFilter",
        tree_formatter: "TreeFormatter",
        use_normalized: bool = False,
        stealth: bool = False,
        ui_cls: "type[UIState] | None" = None,
        vision_enabled: bool = False,
        vision_resize_policy: Any = None,
    );

    """Return Portal recovery, or None when there is no ADB device."""
    def _portal_recovery -> Optional[Callable[[], Awaitable[None]]];

    """Restart Portal's accessibility service, TCP server and keyboard."""
    def _recover_portal -> None;

    def get_state -> UIState;

    """Finalization must not restart accessibility after a failed read."""
    def get_final_state -> UIState;

    def _state_from_data_async(combined_data: dict) -> UIState;

    def _state_from_data(combined_data: dict) -> UIState;

    def __repr__ -> str;

    def __eq__(other: any) -> bool;

    def __hash__ -> int;
}
