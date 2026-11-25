import builtins;

import operator;

import from __future__ { annotations }

import asyncio;

import logging;

import time;

import from copy { copy, deepcopy }

import from types { SimpleNamespace }

import from typing { TYPE_CHECKING, Any, Awaitable, Callable, Dict, List, Optional }

import httpx;

import from mobilerun_core_local.driver.base { DeviceDisconnectedError }

glob logger: any = logging.getLogger("mobilerun");

glob _RETRY_DELAYS: any = [1.0, 2.0, 3.0, 5.0, 8.0, 10.0];

glob _MAX_RETRIES: any = 7;

glob _RECOVERY_AFTER_ATTEMPT: any = 5;

glob _MAX_TIMEOUT_ATTEMPTS: any = 2;

glob _SLOW_FETCH_NOTICE_S: any = 3.0;

glob _A11Y_SERVICE_NOT_AVAILABLE: any = "Accessibility service not available";

def _is_timeout(error: BaseException) -> bool;

async def _fetch_with_notice(
    fetch: Callable[[], Awaitable[Dict[str, Any]]], notice: bool
) -> Dict[str, Any];

glob max_retries_default_: any;

glob recovery_after_default_: any;

with entry {
    max_retries_default_ = _MAX_RETRIES;
    recovery_after_default_ = _RECOVERY_AFTER_ATTEMPT;
}

async def fetch_state_with_retry(
    fetch: Callable[[], Awaitable[Dict[str, Any]]],
    recovery: Optional[Callable[[], Awaitable[None]]] = None,
    max_retries: int = max_retries_default_,
    retry_delays: Optional[List[float]] = None,
    recovery_after: int = recovery_after_default_,
) -> Dict[str, Any];

"""Base class — subclass to support different platforms."""
class StateProvider {
    has driver: any;

    static has supported: any = set[any]();

    static has screenshot_matches_input_coords: any = False;

    static has resize_model_screenshot: any = False;

    def init(driver: "DeviceDriver");

    async def get_state -> UIState;

    async def get_final_state -> UIState;
}

def should_resize_model_screenshot(state_provider: Any) -> bool;

def resize_model_screenshot_with_grid(state_provider: Any, screenshot: bytes) -> bytes;

async def resize_model_screenshot_async(state_provider: Any, screenshot: bytes) -> bytes;

"""Fetches state from an Android device via ``driver.get_ui_tree()``.

    Includes retry logic with exponential backoff and mid-retry recovery
    (accessibility service restart) for robustness against intermittent
    Portal/a11y failures.
    """
class AndroidStateProvider(StateProvider) {
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

    def _portal_recovery -> Optional[Callable[[], Awaitable[None]]];

    async def _recover_portal -> None;

    async def get_state -> UIState;

    async def get_final_state -> UIState;

    async def _state_from_data_async(combined_data: dict) -> UIState;

    def _state_from_data(combined_data: dict) -> UIState;
}
