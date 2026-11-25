impl _is_timeout(error: BaseException) -> bool {
    return isinstance(error, (TimeoutError, httpx.ReadTimeout));
}

impl _fetch_with_notice(
    fetch: Callable[[], Awaitable[Dict[str, Any]]], notice: bool
) -> Dict[str, Any] {
    if not notice {
        return await fetch();
    }
    task: any = asyncio.ensure_future(fetch());
    try {
        done: any;
        _: any;
        (done, _) = await asyncio.wait({task}, timeout=_SLOW_FETCH_NOTICE_S) as any;
    } except BaseException {
        task.cancel();
        raise;
    }
    if not done {
        logger.info("Waiting for the UI state from the device...");
    }
    return await task;
}

impl fetch_state_with_retry(
    fetch: Callable[[], Awaitable[Dict[str, Any]]],
    recovery: Optional[Callable[[], Awaitable[None]]] = None,
    max_retries: int = max_retries_default_,
    retry_delays: Optional[List[float]] = None,
    recovery_after: int = recovery_after_default_,
) -> Dict[str, Any] {
    delays: any = retry_delays or _RETRY_DELAYS;
    last_error: Optional[Exception] = None;
    recovery_attempted: any = False;
    slow_notice_logged: any = False;
    timeouts: any = 0;
    attempts: any = 0;

    is_debug: any = logger.isEnabledFor(logging.DEBUG);

    for attempt in range(max_retries) {
        try {
            attempts = attempt + 1;
            logger.debug(f"Getting state (attempt {attempts}/{max_retries})");

            t0: any = time.monotonic();
            try {
                combined_data: any = await _fetch_with_notice(fetch, not slow_notice_logged);
            } finally {
                if time.monotonic() - t0 >= _SLOW_FETCH_NOTICE_S {
                    slow_notice_logged = True;
                }
            }

            if is_debug {
                elapsed: any = (time.monotonic() - t0) * 1000;
                logger.debug(f"State fetched in {elapsed:.0f}ms");
            }

            if "error" in combined_data {
                raise Exception(f"Portal returned error: {combined_data}");
            }

            required_keys: any = ["a11y_tree", "phone_state", "device_context"];
            missing: any = [k for k in required_keys if k not in combined_data];
            if missing {
                raise Exception("Missing data in state: " + format(", ".join(missing), ""));
            }

            return combined_data;
        } except DeviceDisconnectedError {
            raise;
        } except Exception as e {
            last_error = e;
            timed_out: any = _is_timeout(e);
            if timed_out {
                timeouts += 1;
            }
            is_last: any = operator.ge(attempt, max_retries - 1)
                or operator.ge(timeouts, _MAX_TIMEOUT_ATTEMPTS);
            delay: any = delays[attempt] if attempt < len(delays) else delays[-1];

            err_desc: any = `str(e) or `type(e).__name__;
            suffix: any = f" (retrying in {delay:.0f}s)" if not is_last else "";
            logger.warning(f"get_state attempt {attempt + 1} failed: {err_desc}{suffix}");
            service_gone: any = _A11Y_SERVICE_NOT_AVAILABLE in err_desc;
            if not recovery_attempted
                and recovery is not None
                and (attempt + 1 >= recovery_after or service_gone or timed_out)
                and not is_last
            {
                recovery_attempted = True;
                if service_gone {
                    logger.info("Portal accessibility service is off, re-enabling it...");
                } else {
                    logger.info("State retrieval failing, attempting recovery...");
                }
                try {
                    await recovery();
                    logger.info("Recovery action completed");
                } except Exception as rec_err {
                    logger.warning(f"Recovery action failed: {rec_err}");
                }
            }

            if is_last {
                break;
            }
            await asyncio.sleep(delay);
        }
    }

    last_desc: any = `str(last_error) or `type(last_error).__name__;
    error_msg: any = f"Failed to get state after {attempts} attempts: {last_desc}";
    logger.error(error_msg);
    raise Exception(error_msg) from last_error;
}

impl StateProvider.init(driver: "DeviceDriver") {
    self.driver = driver;
}

impl StateProvider.get_state -> UIState {
    raise NotImplementedError();
}

impl StateProvider.get_final_state -> UIState {
    return (await self.get_state());
}

impl StateProvider.__repr__ -> str {
    return (getattr(builtins.object, "__repr__") as any)(self);
}

impl StateProvider.__eq__(other: any) -> bool {
    return self is other;
}

impl StateProvider.__hash__ -> int {
    return id(self);
}

impl should_resize_model_screenshot(state_provider: Any) -> bool {
    return `bool(
        getattr(state_provider, "resize_model_screenshot", False)
            or getattr(state_provider, "requires_coordinate_tools", False),
    );
}

impl resize_model_screenshot_with_grid(state_provider: Any, screenshot: bytes) -> bytes {
    width: any = getattr(state_provider, "model_screenshot_width", None);
    height: any = getattr(state_provider, "model_screenshot_height", None);
    divisions: any = 10 if getattr(state_provider, "model_screenshot_grid", True) else 0;
    if width and height {
        return resize_image_to_dimensions_with_grid(screenshot, width, height, divisions=divisions);
    }
    return resize_image_to_max_side_with_grid(screenshot, divisions=divisions);
}

impl resize_model_screenshot_async(state_provider: Any, screenshot: bytes) -> bytes {
    if not should_resize_model_screenshot(state_provider) {
        return screenshot;
    }

    geometry: any = SimpleNamespace(
        model_screenshot_width=getattr(state_provider, "model_screenshot_width", None),
        model_screenshot_height=getattr(state_provider, "model_screenshot_height", None),
        model_screenshot_grid=getattr(state_provider, "model_screenshot_grid", True),
    );
    return await asyncio.to_thread(resize_model_screenshot_with_grid, geometry, screenshot);
}

impl AndroidStateProvider.init(
    driver: "DeviceDriver",
    tree_filter: "TreeFilter",
    tree_formatter: "TreeFormatter",
    use_normalized: bool = False,
    stealth: bool = False,
    ui_cls: "type[UIState] | None" = None,
    vision_enabled: bool = False,
    vision_resize_policy: Any = None,
) {
    super.init(driver);
    self.tree_filter = tree_filter;
    self.tree_formatter = tree_formatter;
    self.use_normalized = use_normalized;
    self._ui_cls = ui_cls or (StealthUIState if stealth else UIState);
    self.vision_enabled = vision_enabled;
    self.vision_resize_policy = vision_resize_policy;
    self.model_screenshot_width = None;
    self.model_screenshot_height = None;
    self.screenshot_matches_input_coords = True;
    self._vision_contract_intent = vision_enabled and not use_normalized;
    self.resize_model_screenshot = self._vision_contract_intent;
    self.requires_active_contract_for_coords = vision_enabled;
}

impl AndroidStateProvider._portal_recovery -> Optional[Callable[[], Awaitable[None]]] {
    import from mobilerun_core_local.driver.android { AndroidDriver }

    if isinstance(self.driver, AndroidDriver) and self.driver.device is not None {
        return self._recover_portal;
    }
    return None;
}

impl AndroidStateProvider._recover_portal -> None {
    device: any = self.driver.device;

    import from mobilerun_core_local.driver.android.portal {
        PORTAL_PACKAGE_NAME,
        portal_a11y_service,
        portal_content_uri,
    }

    a11y: any = portal_a11y_service(PORTAL_PACKAGE_NAME);
    logger.debug("Restarting Portal accessibility service...");
    (await device.shell("settings put secure accessibility_enabled 0"));
    (await asyncio.sleep(0.5));
    (await device.shell(f"settings put secure enabled_accessibility_services {a11y}"));
    (await device.shell("settings put secure accessibility_enabled 1"));
    portal: any = self.driver.portal;
    if portal is not None and portal.tcp_available {
        logger.debug("Restarting Portal TCP socket server...");
        toggle_uri: any = portal_content_uri(PORTAL_PACKAGE_NAME, "toggle_socket_server");
        try {
            (await device.shell(f"content insert --uri {toggle_uri} --bind enabled:b:false"));
            (await asyncio.sleep(0.3));
            (await device.shell(f"content insert --uri {toggle_uri} --bind enabled:b:true"));
            new_token: any = (await portal._fetch_auth_token());
            if new_token {
                portal._auth_token = new_token;
                logger.debug("Auth token refreshed after TCP server restart");
            }
        } except Exception as e {
            logger.debug(f"TCP server restart failed: {e}");
        }
    }
    if getattr(self.driver, "_portal_keyboard_available", False) {
        import from mobilerun_core_local.driver.android.portal { setup_keyboard }

        try {
            (await setup_keyboard(device));
        } except Exception as e {
            logger.debug(f"Portal keyboard restore failed: {e}");
        }
    }

    (await asyncio.sleep(1.5));
}

impl AndroidStateProvider.get_state -> UIState {
    combined_data: any = (
        await fetch_state_with_retry(
            fetch=self.driver.get_ui_tree, recovery=self._portal_recovery()
        )
    );
    return (await self._state_from_data_async(combined_data));
}

impl AndroidStateProvider.get_final_state -> UIState {
    combined_data: any = (await self.driver.get_ui_tree());
    return (await self._state_from_data_async(combined_data));
}

impl AndroidStateProvider._state_from_data_async(combined_data: dict) -> UIState {
    processor: any;
    processor = copy(self);
    processor.tree_filter = deepcopy(self.tree_filter);
    processor.tree_formatter = deepcopy(self.tree_formatter);
    processor.vision_resize_policy = deepcopy(self.vision_resize_policy);

    def process -> tuple[UIState, bool] {
        state: any = processor._state_from_data(combined_data);
        return (state, processor.resize_model_screenshot);
    }

    state: any;
    resize: any;
    (state, resize) = (await asyncio.to_thread(process)) as any;
    self.resize_model_screenshot = resize;
    self.model_screenshot_width = state.model_screenshot_width;
    self.model_screenshot_height = state.model_screenshot_height;
    self.tree_formatter.screen_width = state.screen_width;
    self.tree_formatter.screen_height = state.screen_height;
    self.tree_formatter.use_normalized = state.use_normalized;
    self.tree_formatter.display_scale_x = state.coordinate_scale_x;
    self.tree_formatter.display_scale_y = state.coordinate_scale_y;
    return state;
}

impl AndroidStateProvider._state_from_data(combined_data: dict) -> UIState {
    device_context: any = combined_data["device_context"];
    screen_bounds: any = device_context.get("screen_bounds", {});
    screen_width: any = screen_bounds.get("width");
    screen_height: any = screen_bounds.get("height");

    filtered: any = self.tree_filter.filter(combined_data["a11y_tree"], device_context);

    coordinate_scale_x: any = 1.0;
    coordinate_scale_y: any = 1.0;
    display_width: any = None;
    display_height: any = None;
    if self._vision_contract_intent and screen_width and screen_height {
        if self.vision_resize_policy is not None {
            (display_width, display_height) = self.vision_resize_policy.effective_dims(
                screen_width, screen_height
            ) as any;
        } else {
            (display_width, display_height) = fit_dimensions_to_max_side(
                screen_width, screen_height
            ) as any;
        }
        coordinate_scale_x = screen_width / display_width;
        coordinate_scale_y = screen_height / display_height;
    }
    if self._vision_contract_intent {
        self.resize_model_screenshot = `bool(display_width and display_height);
    }
    self.model_screenshot_width = display_width;
    self.model_screenshot_height = display_height;

    self.tree_formatter.screen_width = screen_width;
    self.tree_formatter.screen_height = screen_height;
    self.tree_formatter.use_normalized = self.use_normalized;
    self.tree_formatter.display_scale_x = coordinate_scale_x;
    self.tree_formatter.display_scale_y = coordinate_scale_y;

    formatted_text: any;
    focused_text: any;
    elements: any;
    phone_state: any;
    (formatted_text, focused_text, elements, phone_state) = self.tree_formatter.format(
        filtered, combined_data["phone_state"]
    ) as any;

    if self.use_normalized and self.vision_enabled and screen_width and screen_height {
        formatted_text += f"\n\n{NORMALIZED_STATE_NOTE}";
    }
    if display_width and display_height {
        scaled_note: any = f" — the {screen_width}x{screen_height} device screen scaled down"
            if (display_width, display_height) != (screen_width, screen_height)
            else "";
        formatted_text += f"\n\nAll coordinates in this device state (element bounds above, and any x/y you provide to coordinate actions) are in a {display_width}x{display_height} coordinate space{scaled_note}. When a screenshot is provided it matches this {display_width}x{display_height} space and carries a labeled coordinate grid for reference.";
    }

    return self._ui_cls(
        elements=elements,
        formatted_text=formatted_text,
        focused_text=focused_text,
        phone_state=phone_state,
        screen_width=screen_width,
        screen_height=screen_height,
        use_normalized=self.use_normalized,
        coordinate_scale_x=coordinate_scale_x,
        coordinate_scale_y=coordinate_scale_y,
        coordinate_contract_active=`bool(display_width and display_height)
            or `bool(self.use_normalized and screen_width and screen_height),
        model_screenshot_width=display_width,
        model_screenshot_height=display_height,
    );
}

impl AndroidStateProvider.__repr__ -> str {
    return (getattr(builtins.super(AndroidStateProvider, self), "__repr__") as any)();
}

impl AndroidStateProvider.__eq__(other: any) -> bool {
    return self is other;
}

impl AndroidStateProvider.__hash__ -> int {
    return id(self);
}
