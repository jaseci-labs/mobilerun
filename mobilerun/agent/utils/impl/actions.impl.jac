impl _uses_screenshot_only_coordinates(ctx: "ActionContext") -> builtins.bool {
    return `bool(getattr(ctx.state_provider, "requires_coordinate_tools", False));
}

impl _screenshot_only_coordinate_error(ctx: "ActionContext") -> builtins.str {
    if getattr(ctx.ui, "use_normalized", False) {
        return "Coordinates must be normalized values from 0 to 1000 on both axes in screenshot-only mode. Observe the screenshot and retry with normalized coordinates.";
    }
    width: any = getattr(ctx.ui, "screen_width", None);
    height: any = getattr(ctx.ui, "screen_height", None);
    if width and height {
        return f"Coordinates must be inside the screenshot size {width}x{height} in screenshot-only mode. Observe the screenshot and retry with pixel coordinates inside the image.";
    }
    return "Coordinates must be inside the screenshot bounds in screenshot-only mode. Observe the screenshot and retry with pixel coordinates inside the image.";
}

impl _validate_screenshot_only_point(
    x: builtins.int | builtins.float, y: builtins.int | builtins.float, *, ctx: "ActionContext"
) -> None {
    if not _uses_screenshot_only_coordinates(ctx) {
        return;
    }
    try {
        width: any = `float(ctx.ui.screen_width);
        height: any = `float(ctx.ui.screen_height);
        px: any = `float(x);
        py: any = `float(y);
    } except TypeError as exc {
        raise ValueError(_screenshot_only_coordinate_error(ctx)) from exc;
    } except ValueError as exc {
        raise ValueError(_screenshot_only_coordinate_error(ctx)) from exc;
    }

    if getattr(ctx.ui, "use_normalized", False) {
        if not (0 <= px <= NORMALIZED_MAX and 0 <= py <= NORMALIZED_MAX) {
            raise ValueError(_screenshot_only_coordinate_error(ctx));
        }
        return;
    }

    out_of_range: any = operator.le(width, 0)
        or operator.le(height, 0)
        or operator.lt(px, 0)
        or operator.ge(px, width)
        or operator.lt(py, 0)
        or operator.ge(py, height);
    if out_of_range {
        raise ValueError(_screenshot_only_coordinate_error(ctx));
    }
}

impl _model_space_dimensions(ctx: "ActionContext") -> builtins.tuple[builtins.float, builtins.float]
    | None {
    if _uses_screenshot_only_coordinates(ctx) {
        return None;
    }
    if not getattr(ctx.ui, "coordinate_contract_active", False) {
        return None;
    }
    if getattr(ctx.ui, "use_normalized", False) {
        return None;
    }
    try {
        scale_x: any = `float(ctx.ui.coordinate_scale_x);
        scale_y: any = `float(ctx.ui.coordinate_scale_y);
        width: any = `float(ctx.ui.screen_width) / scale_x;
        height: any = `float(ctx.ui.screen_height) / scale_y;
    } except (TypeError, ValueError, ZeroDivisionError) {
        return None;
    }
    if width <= 0 or height <= 0 {
        return None;
    }
    return (width, height);
}

impl _validate_model_space_point(
    x: builtins.int | builtins.float, y: builtins.int | builtins.float, *, ctx: "ActionContext"
) -> None {
    dims: any = _model_space_dimensions(ctx);
    if dims is None {
        return;
    }
    width: any;
    height: any;
    (width, height) = dims as any;
    try {
        px: any = `float(x);
        py: any = `float(y);
    } except (TypeError, ValueError) as exc {
        raise ValueError(
            f"Coordinates must be numbers inside the {round(width)}x{round(height)} coordinate space of the provided device state.",
        ) from exc;
    }
    if px < 0 or px >= width or py < 0 or py >= height {
        raise ValueError(
            f"Coordinates ({x}, {y}) are outside the {round(width)}x{round(height)} coordinate space of the provided device state. Use the element bounds and screenshot shown to you and retry with coordinates inside that space.",
        );
    }
}

impl _require_active_coordinate_contract(ctx: "ActionContext") -> None {
    provider: any = ctx.state_provider;
    if not getattr(provider, "requires_active_contract_for_coords", False) {
        return;
    }
    if getattr(ctx.ui, "coordinate_contract_active", False) {
        return;
    }
    raise ValueError(
        "Coordinate actions are unavailable for this step — the screen state could not be captured fully. Use an element index with `click`, or retry to get a fresh screen state.",
    );
}

impl _validate_normalized_point(
    x: builtins.int | builtins.float, y: builtins.int | builtins.float, *, ctx: "ActionContext"
) -> None {
    if _uses_screenshot_only_coordinates(ctx) {
        return;
    }
    if not getattr(ctx.ui, "use_normalized", False) {
        return;
    }
    try {
        inside: any = operator.le(0, compared_ := `float(x))
            and operator.le(compared_, NORMALIZED_MAX)
            and (
                operator.le(0, compared__ := `float(y)) and operator.le(compared__, NORMALIZED_MAX)
            );
    } except (TypeError, ValueError) {
        inside = False;
    }
    if not inside {
        raise ValueError(
            f"Coordinates ({x}, {y}) are outside the normalized 0-1000 range of the device state. Use the element bounds shown to you and retry.",
        );
    }
}

impl _convert_action_point(
    x: builtins.int | builtins.float, y: builtins.int | builtins.float, *, ctx: "ActionContext"
) -> builtins.tuple[builtins.int, builtins.int] {
    _validate_screenshot_only_point(x, y, ctx=ctx);
    _validate_normalized_point(x, y, ctx=ctx);
    _require_active_coordinate_contract(ctx);
    _validate_model_space_point(x, y, ctx=ctx);
    abs_x: any;
    abs_y: any;
    (abs_x, abs_y) = ctx.ui.convert_point(x, y) as any;
    return (`int(round(abs_x)), `int(round(abs_y)));
}

impl _summary_point(
    x: builtins.int | builtins.float,
    y: builtins.int | builtins.float,
    abs_x: builtins.int,
    abs_y: builtins.int,
    *,
    ctx: "ActionContext",
) -> builtins.str {
    if getattr(ctx.ui, "use_normalized", False) {
        return f"({x}, {y})";
    }
    return f"({abs_x}, {abs_y})";
}

impl _element_summary_point(
    x: builtins.int, y: builtins.int, *, ctx: "ActionContext"
) -> builtins.str {
    ui: any = ctx.ui;
    if getattr(ui, "use_normalized", False) and ui.screen_width and ui.screen_height {
        (x, y) = to_normalized(x, y, ui.screen_width, ui.screen_height) as any;
    }
    return f"({x}, {y})";
}

impl _macro_recorder(ctx: "ActionContext") -> any {
    return getattr(ctx, "macro_recorder", None);
}

impl _record_macro_action(ctx: "ActionContext", action: builtins.dict, *, pre_ui=None) -> None {
    recorder: any = _macro_recorder(ctx);
    if recorder is None {
        return;
    }
    recorder.record_action(
        action, pre_ui=pre_ui if pre_ui is not None else getattr(ctx, "ui", None)
    );
}

impl _macro_pre_ui(ctx: "ActionContext") -> any {
    if _macro_recorder(ctx) is None {
        return getattr(ctx, "ui", None);
    }
    state_provider: any = getattr(ctx, "state_provider", None);
    if state_provider is None or not hasattr(state_provider, "get_state") {
        return getattr(ctx, "ui", None);
    }
    try {
        return await state_provider.get_state();
    } except Exception as e {
        logger.debug(f"Failed to refresh macro pre-state: {e}");
        return getattr(ctx, "ui", None);
    }
}

impl _macro_pre_ui_after_focus_tap(ctx: "ActionContext") -> any {
    if _macro_recorder(ctx) is not None {
        await asyncio.sleep(_MACRO_FOCUS_SETTLE_SECONDS);
    }
    return await _macro_pre_ui(ctx);
}

impl _driver_log_length(ctx: "ActionContext") -> builtins.int | None {
    log: any = getattr(getattr(ctx, "driver", None), "log", None);
    if isinstance(log, `list) {
        return len(log);
    }
    return None;
}

impl _record_driver_log_delta(
    ctx: "ActionContext", before: builtins.int | None, *, pre_ui=None
) -> None {
    if before is None {
        return;
    }
    log: any = getattr(getattr(ctx, "driver", None), "log", None);
    if not isinstance(log, `list) {
        return;
    }
    for raw_action in log[before:] {
        _record_macro_action(ctx, `dict(raw_action), pre_ui=pre_ui);
    }
}

impl click(index: builtins.int, *, ctx: "ActionContext") -> ActionResult {
    try {
        pre_ui: any = await _macro_pre_ui(ctx);
        x: any;
        y: any;
        (x, y) = ctx.ui.get_element_coords(index) as any;
        await ctx.driver.tap(x, y);
        _record_macro_action(ctx, {"action_type": "tap", "x": x, "y": y}, pre_ui=pre_ui);

        info: any = ctx.ui.get_element_info(index);
        detail_parts: any = [
            "Text: '" + format(info.get("text", "No text"), "") + "'",
            "Class: " + format(info.get("className", "Unknown class"), ""),
            "Type: " + format(info.get("type", "unknown"), ""),
        ];
        if info.get("child_texts") {
            detail_parts.append("Contains text: " + format(" | ".join(info["child_texts"]), ""));
        }
        detail_parts.append(f"Coordinates: {_element_summary_point(x, y, ctx=ctx)}");

        return ActionResult(
            success=True, summary="Clicked on " + format(" | ".join(detail_parts), "")
        );
    } except ValueError as e {
        return ActionResult(
            success=False, summary=f"Failed to click element at index {index}: {e}"
        );
    }
}

impl long_press(index: builtins.int, *, ctx: "ActionContext") -> ActionResult {
    try {
        pre_ui: any = await _macro_pre_ui(ctx);
        x: any;
        y: any;
        (x, y) = ctx.ui.get_element_coords(index) as any;
        await ctx.driver.swipe(x, y, x, y, 1000);
        _record_macro_action(
            ctx,
            {
                "action_type": "swipe",
                "start_x": x,
                "start_y": y,
                "end_x": x,
                "end_y": y,
                "duration_ms": 1000,
            },
            pre_ui=pre_ui,
        );
        return ActionResult(
            success=True,
            summary=f"Long pressed element at index {index} at {_element_summary_point(x, y, ctx=ctx)}",
        );
    } except ValueError as e {
        return ActionResult(
            success=False, summary=f"Failed to long press element at index {index}: {e}"
        );
    }
}

impl long_press_at(x: builtins.int, y: builtins.int, *, ctx: "ActionContext") -> ActionResult {
    try {
        pre_ui: any = await _macro_pre_ui(ctx);
        abs_x: any;
        abs_y: any;
        (abs_x, abs_y) = _convert_action_point(x, y, ctx=ctx) as any;
        await ctx.driver.swipe(abs_x, abs_y, abs_x, abs_y, 1000);
        _record_macro_action(
            ctx,
            {
                "action_type": "swipe",
                "start_x": abs_x,
                "start_y": abs_y,
                "end_x": abs_x,
                "end_y": abs_y,
                "duration_ms": 1000,
            },
            pre_ui=pre_ui,
        );
        return ActionResult(
            success=True, summary=f"Long pressed at {_summary_point(x, y, abs_x, abs_y, ctx=ctx)}"
        );
    } except Exception as e {
        return ActionResult(
            success=False, summary=f"Failed to long press at ({x}, {y}): {describe_error(e)}"
        );
    }
}

impl click_at(x: builtins.int, y: builtins.int, *, ctx: "ActionContext") -> ActionResult {
    try {
        pre_ui: any = await _macro_pre_ui(ctx);
        abs_x: any;
        abs_y: any;
        (abs_x, abs_y) = _convert_action_point(x, y, ctx=ctx) as any;
        await ctx.driver.tap(abs_x, abs_y);
        _record_macro_action(ctx, {"action_type": "tap", "x": abs_x, "y": abs_y}, pre_ui=pre_ui);
        return ActionResult(
            success=True, summary=f"Tapped at {_summary_point(x, y, abs_x, abs_y, ctx=ctx)}"
        );
    } except Exception as e {
        return ActionResult(
            success=False, summary=f"Failed to tap at ({x}, {y}): {describe_error(e)}"
        );
    }
}

impl click_area(
    x1: builtins.int, y1: builtins.int, x2: builtins.int, y2: builtins.int, *, ctx: "ActionContext"
) -> ActionResult {
    try {
        pre_ui: any = await _macro_pre_ui(ctx);
        _validate_screenshot_only_point(x1, y1, ctx=ctx);
        _validate_screenshot_only_point(x2, y2, ctx=ctx);
        _validate_normalized_point(x1, y1, ctx=ctx);
        _validate_normalized_point(x2, y2, ctx=ctx);
        cx: any;
        cy: any;
        (cx, cy) = ((x1 + x2) // 2, (y1 + y2) // 2);
        abs_x: any;
        abs_y: any;
        (abs_x, abs_y) = _convert_action_point(cx, cy, ctx=ctx) as any;
        await ctx.driver.tap(abs_x, abs_y);
        _record_macro_action(ctx, {"action_type": "tap", "x": abs_x, "y": abs_y}, pre_ui=pre_ui);
        return ActionResult(
            success=True,
            summary=f"Tapped center of area at {_summary_point(cx, cy, abs_x, abs_y, ctx=ctx)}",
        );
    } except Exception as e {
        return ActionResult(
            success=False, summary=f"Failed to tap area center: {describe_error(e)}"
        );
    }
}

impl type_text(
    text: builtins.str,
    index: builtins.int | None = None,
    clear: builtins.bool = False,
    *,
    ctx: "ActionContext",
) -> ActionResult {
    try {
        pre_ui: any = await _macro_pre_ui(ctx);
        if index is not None and index != -1 {
            x: any;
            y: any;
            (x, y) = ctx.ui.get_element_coords(index) as any;
            await ctx.driver.tap(x, y);
            _record_macro_action(ctx, {"action_type": "tap", "x": x, "y": y}, pre_ui=pre_ui);
            pre_ui = await _macro_pre_ui_after_focus_tap(ctx);
        }

        success: any = await ctx.driver.input_text(text, clear);
        if success {
            _record_macro_action(
                ctx, {"action_type": "input_text", "text": text, "clear": clear}, pre_ui=pre_ui
            );
            return ActionResult(success=True, summary=f"Text typed successfully (clear={clear})");
        }
        return ActionResult(success=False, summary="Failed to type text: input failed");
    } except Exception as e {
        return ActionResult(success=False, summary=f"Failed to type text: {describe_error(e)}");
    }
}

impl type_text_direct(
    text: builtins.str, clear: builtins.bool = False, *, ctx: "ActionContext"
) -> ActionResult {
    try {
        pre_ui: any = await _macro_pre_ui(ctx);
        success: any = await ctx.driver.input_text(text, clear);
        if success {
            _record_macro_action(
                ctx, {"action_type": "input_text", "text": text, "clear": clear}, pre_ui=pre_ui
            );
            return ActionResult(success=True, summary=f"Text typed successfully (clear={clear})");
        }
        return ActionResult(success=False, summary="Failed to type text: input failed");
    } except Exception as e {
        return ActionResult(success=False, summary=f"Failed to type text: {describe_error(e)}");
    }
}

impl system_button(button: builtins.str, *, ctx: "ActionContext") -> ActionResult {
    try {
        pre_ui: any = await _macro_pre_ui(ctx);
        await ctx.driver.press_button(button);
        _record_macro_action(ctx, {"action_type": "button_press", "button": button}, pre_ui=pre_ui);
        return ActionResult(success=True, summary=f"Pressed {button.upper()} button");
    } except ValueError as e {
        return ActionResult(success=False, summary=`str(e));
    } except Exception as e {
        return ActionResult(
            success=False, summary=f"Failed to press {button} button: {e.__class__.__name__}: {e}"
        );
    }
}

impl swipe(
    coordinate: List[builtins.int],
    coordinate2: List[builtins.int],
    duration: builtins.float = 1.0,
    *,
    ctx: "ActionContext",
) -> ActionResult {
    if not isinstance(coordinate, `list) or len(coordinate) != 2 {
        return ActionResult(
            success=False,
            summary=f"Failed: coordinate must be a list of 2 integers, got: {coordinate}",
        );
    }
    if not isinstance(coordinate2, `list) or len(coordinate2) != 2 {
        return ActionResult(
            success=False,
            summary=f"Failed: coordinate2 must be a list of 2 integers, got: {coordinate2}",
        );
    }

    try {
        pre_ui: any = await _macro_pre_ui(ctx);
        start_x: any;
        start_y: any;
        (start_x, start_y) = _convert_action_point(*coordinate, ctx=ctx) as any;
        end_x: any;
        end_y: any;
        (end_x, end_y) = _convert_action_point(*coordinate2, ctx=ctx) as any;
        duration_ms: any = `int(duration * 1000);
        await ctx.driver.swipe(start_x, start_y, end_x, end_y, duration_ms=duration_ms);
        _record_macro_action(
            ctx,
            {
                "action_type": "swipe",
                "start_x": start_x,
                "start_y": start_y,
                "end_x": end_x,
                "end_y": end_y,
                "duration_ms": duration_ms,
            },
            pre_ui=pre_ui,
        );
        return ActionResult(
            success=True,
            summary=f"Swiped from {_summary_point(*coordinate, start_x, start_y, ctx=ctx)} to {_summary_point(*coordinate2, end_x, end_y, ctx=ctx)}",
        );
    } except Exception as e {
        return ActionResult(success=False, summary=f"Failed to swipe: {describe_error(e)}");
    }
}

impl open_app(text: builtins.str, *, ctx: "ActionContext") -> ActionResult {
    if ctx.app_opener_llm is None {
        return ActionResult(success=False, summary="Failed: app_opener_llm not configured.");
    }

    workflow: any = AppStarter(
        driver=ctx.driver, llm=ctx.app_opener_llm, timeout=60, stream=ctx.streaming, verbose=False
    );

    pre_ui: any = await _macro_pre_ui(ctx);
    driver_log_before: any = _driver_log_length(ctx);
    result: any = await workflow.run(app_description=text);
    await asyncio.sleep(1);

    if isinstance(result, `str) and "could not open app" in result.lower() {
        return ActionResult(success=False, summary=result);
    }
    _record_driver_log_delta(ctx, driver_log_before, pre_ui=pre_ui);
    return ActionResult(success=True, summary=`str(result));
}

impl open_bundle_id(
    bundle_id: builtins.str | None = None,
    app_id: builtins.str | None = None,
    *,
    ctx: "ActionContext",
) -> ActionResult {
    identifier: any = `str(app_id or bundle_id or "").strip();
    if not identifier {
        return ActionResult(
            success=False, summary="Failed to open app: exact app identifier is required."
        );
    }

    hint: any = "Maybe you got the wrong app identifier. You could try using swipes and search to find the app.";
    try {
        pre_ui: any = await _macro_pre_ui(ctx);
        result: any = await ctx.driver.start_app(identifier);
        await asyncio.sleep(1);
        if isinstance(result, `str) and result.lower().startswith("failed") {
            return ActionResult(
                success=False, summary=f"Failed to open app '{identifier}': {result}\n{hint}"
            );
        }
        _record_macro_action(
            ctx,
            {"action_type": "start_app", "package": identifier, "activity": None},
            pre_ui=pre_ui,
        );
        return ActionResult(success=True, summary=`str(result));
    } except Exception as e {
        return ActionResult(
            success=False,
            summary=f"Failed to open app '{identifier}': {e.__class__.__name__}: {e}\n{hint}",
        );
    }
}

impl `wait(duration: builtins.float = 1.0, *, ctx: "ActionContext") -> ActionResult {
    pre_ui: any = await _macro_pre_ui(ctx);
    await asyncio.sleep(duration);
    recorder: any = _macro_recorder(ctx);
    if recorder is not None {
        recorder.record_wait(duration, pre_ui=pre_ui);
    }
    return ActionResult(success=True, summary=f"Waited for {duration} seconds");
}

impl complete(
    success: builtins.bool,
    reason: builtins.str = "",
    message: builtins.str = "",
    *,
    ctx: "ActionContext",
) -> ActionResult {
    await ctx.shared_state.complete(success, reason=reason, message=message);
    return ActionResult(success=True, summary=ctx.shared_state.answer);
}

impl type_secret(
    secret_id: builtins.str, index: builtins.int, *, ctx: "ActionContext"
) -> ActionResult {
    if ctx.credential_manager is None {
        return ActionResult(
            success=False,
            summary="Failed to type secret: Credential manager not initialized. Enable credentials in config.yaml",
        );
    }

    try {
        secret_value: any = await ctx.credential_manager.resolve_key(secret_id);
        pre_ui: any = await _macro_pre_ui(ctx);
        if index != -1 {
            x: any;
            y: any;
            (x, y) = ctx.ui.get_element_coords(index) as any;
            await ctx.driver.tap(x, y);
            _record_macro_action(ctx, {"action_type": "tap", "x": x, "y": y}, pre_ui=pre_ui);
            pre_ui = await _macro_pre_ui_after_focus_tap(ctx);
        }

        ok: any = await ctx.driver.input_text(secret_value);
        if ok {
            _record_macro_action(
                ctx,
                {"action_type": "type_secret", "secret_id": secret_id, "clear": False},
                pre_ui=pre_ui,
            );
            return ActionResult(
                success=True,
                summary=f"Successfully typed secret '{secret_id}' into element {index}",
            );
        }
        return ActionResult(
            success=False, summary=f"Failed to type secret '{secret_id}': input failed"
        );
    } except Exception as e {
        logger.error(f"Failed to type secret '{secret_id}': {e}");
        available: any = await ctx.credential_manager.get_keys() if ctx.credential_manager else [];
        return ActionResult(
            success=False,
            summary=f"Failed to type secret '{secret_id}': not found. Available: {available}",
        );
    }
}
