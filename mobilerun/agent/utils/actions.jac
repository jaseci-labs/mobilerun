import builtins;

import operator;

import asyncio;

import logging;

import from typing { List }

glob logger: any = logging.getLogger("mobilerun");

glob _MACRO_FOCUS_SETTLE_SECONDS: any = 0.5;

def _uses_screenshot_only_coordinates(ctx: "ActionContext") -> builtins.bool;

def _screenshot_only_coordinate_error(ctx: "ActionContext") -> builtins.str;

def _validate_screenshot_only_point(
    x: builtins.int | builtins.float, y: builtins.int | builtins.float, *, ctx: "ActionContext"
) -> None;

def _model_space_dimensions(ctx: "ActionContext") -> builtins.tuple[builtins.float, builtins.float]
    | None;

def _validate_model_space_point(
    x: builtins.int | builtins.float, y: builtins.int | builtins.float, *, ctx: "ActionContext"
) -> None;

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

async def click(index: builtins.int, *, ctx: "ActionContext") -> ActionResult;

async def long_press(index: builtins.int, *, ctx: "ActionContext") -> ActionResult;

async def long_press_at(x: builtins.int, y: builtins.int, *, ctx: "ActionContext") -> ActionResult;

async def click_at(x: builtins.int, y: builtins.int, *, ctx: "ActionContext") -> ActionResult;

async def click_area(
    x1: builtins.int, y1: builtins.int, x2: builtins.int, y2: builtins.int, *, ctx: "ActionContext"
) -> ActionResult;

async def type_text(
    text: builtins.str,
    index: builtins.int | None = None,
    clear: builtins.bool = False,
    *,
    ctx: "ActionContext",
) -> ActionResult;

async def type_text_direct(
    text: builtins.str, clear: builtins.bool = False, *, ctx: "ActionContext"
) -> ActionResult;

async def system_button(button: builtins.str, *, ctx: "ActionContext") -> ActionResult;

async def swipe(
    coordinate: List[builtins.int],
    coordinate2: List[builtins.int],
    duration: builtins.float = 1.0,
    *,
    ctx: "ActionContext",
) -> ActionResult;

async def open_app(text: builtins.str, *, ctx: "ActionContext") -> ActionResult;

async def open_bundle_id(
    bundle_id: builtins.str | None = None,
    app_id: builtins.str | None = None,
    *,
    ctx: "ActionContext",
) -> ActionResult;

async def `wait(duration: builtins.float = 1.0, *, ctx: "ActionContext") -> ActionResult;

async def complete(
    success: builtins.bool,
    reason: builtins.str = "",
    message: builtins.str = "",
    *,
    ctx: "ActionContext",
) -> ActionResult;

async def type_secret(
    secret_id: builtins.str, index: builtins.int, *, ctx: "ActionContext"
) -> ActionResult;
