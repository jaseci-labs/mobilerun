"""Action functions for device interaction.

Each function receives ``ctx: ActionContext`` as a keyword argument and
interacts with the device via ``ctx.driver``, resolves UI elements via
``ctx.ui``, and accesses shared state via ``ctx.shared_state``.
"""

import builtins;

import operator;

import asyncio;

import logging;

import from typing { TYPE_CHECKING, List }

glob logger: any;

glob _MACRO_FOCUS_SETTLE_SECONDS: any;

with entry {
    logger = logging.getLogger("mobilerun");

    _MACRO_FOCUS_SETTLE_SECONDS = 0.5;
}

def _uses_screenshot_only_coordinates(ctx: "ActionContext") -> builtins.bool;

def _screenshot_only_coordinate_error(ctx: "ActionContext") -> builtins.str;

def _validate_screenshot_only_point(
    x: builtins.int | builtins.float, y: builtins.int | builtins.float, *, ctx: "ActionContext"
) -> None;

"""Return the (width, height) coordinate space the model was shown.

    Only applies when the provider declared a scaled coordinate contract
    (``resize_model_screenshot``) outside screenshot-only mode: the UIState
    keeps native screen dimensions while the model sees and answers in the
    ``native / coordinate_scale`` display space.
    """
def _model_space_dimensions(ctx: "ActionContext") -> builtins.tuple[builtins.float, builtins.float]
    | None;

def _validate_model_space_point(
    x: builtins.int | builtins.float, y: builtins.int | builtins.float, *, ctx: "ActionContext"
) -> None;

"""Reject coordinate actions when the provider requires the vision
    coordinate contract but it is not active for the current state.

    Some providers (e.g. iOS) can only map model coordinates to the tap input
    space while the contract is active. Without it, refuse the action so the
    model retries or uses an element-index ``click`` instead of tapping the
    wrong location."""
def _require_active_coordinate_contract(ctx: "ActionContext") -> None;

def _validate_normalized_point(
    x: builtins.int | builtins.float, y: builtins.int | builtins.float, *, ctx: "ActionContext"
) -> None;

def _convert_action_point(
    x: builtins.int | builtins.float, y: builtins.int | builtins.float, *, ctx: "ActionContext"
) -> builtins.tuple[builtins.int, builtins.int];

def _summary_point(
    x: builtins.int | builtins.float,
    y: builtins.int | builtins.float,
    abs_x: builtins.int,
    abs_y: builtins.int,
    *,
    ctx: "ActionContext",
) -> builtins.str;

def _element_summary_point(
    x: builtins.int, y: builtins.int, *, ctx: "ActionContext"
) -> builtins.str;

def _macro_recorder(ctx: "ActionContext") -> any;

def _record_macro_action(ctx: "ActionContext", action: builtins.dict, *, pre_ui=None) -> None;

async def _macro_pre_ui(ctx: "ActionContext") -> any;

async def _macro_pre_ui_after_focus_tap(ctx: "ActionContext") -> any;

def _driver_log_length(ctx: "ActionContext") -> builtins.int | None;

def _record_driver_log_delta(
    ctx: "ActionContext", before: builtins.int | None, *, pre_ui=None
) -> None;

"""Click the element with the given index."""
async def click(index: builtins.int, *, ctx: "ActionContext") -> ActionResult;

"""Long press the element with the given index."""
async def long_press(index: builtins.int, *, ctx: "ActionContext") -> ActionResult;

"""Long press at screen coordinates."""
async def long_press_at(x: builtins.int, y: builtins.int, *, ctx: "ActionContext") -> ActionResult;

"""Click at screen coordinates."""
async def click_at(x: builtins.int, y: builtins.int, *, ctx: "ActionContext") -> ActionResult;

"""Click center of area."""
async def click_area(
    x1: builtins.int, y1: builtins.int, x2: builtins.int, y2: builtins.int, *, ctx: "ActionContext"
) -> ActionResult;

"""Type text into an indexed element or the currently focused input."""
async def type_text(
    text: builtins.str,
    index: builtins.int | None = None,
    clear: builtins.bool = False,
    *,
    ctx: "ActionContext",
) -> ActionResult;

"""Type text into the currently focused input."""
async def type_text_direct(
    text: builtins.str, clear: builtins.bool = False, *, ctx: "ActionContext"
) -> ActionResult;

"""Press a system button (back, home, or enter)."""
async def system_button(button: builtins.str, *, ctx: "ActionContext") -> ActionResult;

"""Swipe from one coordinate to another."""
async def swipe(
    coordinate: List[builtins.int],
    coordinate2: List[builtins.int],
    duration: builtins.float = 1.0,
    *,
    ctx: "ActionContext",
) -> ActionResult;

"""Open an app by its name."""
async def open_app(text: builtins.str, *, ctx: "ActionContext") -> ActionResult;

"""Open an app by exact package name, app id, or iOS bundle identifier."""
async def open_bundle_id(
    bundle_id: builtins.str | None = None,
    app_id: builtins.str | None = None,
    *,
    ctx: "ActionContext",
) -> ActionResult;

"""Wait for a specified duration in seconds."""
async def `wait(duration: builtins.float = 1.0, *, ctx: "ActionContext") -> ActionResult;

"""Mark the task as complete.

    Accepts both ``reason`` and ``message`` — FastAgent XML prompt uses
    ``message``, action signature uses ``reason``.
    """
async def complete(
    success: builtins.bool,
    reason: builtins.str = "",
    message: builtins.str = "",
    *,
    ctx: "ActionContext",
) -> ActionResult;

"""Type a secret credential into an input field without exposing the value."""
async def type_secret(
    secret_id: builtins.str, index: builtins.int, *, ctx: "ActionContext"
) -> ActionResult;
