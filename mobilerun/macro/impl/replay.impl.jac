impl MacroPlayer.init(
    device_serial: builtins.str = None,
    delay_between_actions: builtins.float = 1.0,
    on_mismatch: builtins.str = "stop",
    state_timeout: builtins.float = 5.0,
    state_threshold: builtins.float = 0.85,
    state_poll_interval: builtins.float = 0.5,
    handoff_runner=None,
    provider: Optional[builtins.str] = None,
    model: Optional[builtins.str] = None,
    config_path: Optional[builtins.str] = None,
) {
    self.device_serial = device_serial;
    self.delay_between_actions = delay_between_actions;
    self.on_mismatch = on_mismatch;
    self.state_timeout = state_timeout;
    self.state_threshold = state_threshold;
    self.state_poll_interval = state_poll_interval;
    self.handoff_runner = handoff_runner or run_agent_handoff;
    self.provider = provider;
    self.model = model;
    self.config_path = config_path;
    self.last_divergence = None;
    self.state_provider = None;
    self.driver = None;
    self.credential_manager = None;
    self._credential_load_error = None;
}

impl MacroPlayer._initialize_driver -> AndroidDriver {
    if self.driver is None {
        self.driver = AndroidDriver(serial=self.device_serial);
        (await self.driver.connect());
        logger.info(f"🤖 Initialized driver for device: {self.device_serial}");
    }
    return self.driver;
}

impl MacroPlayer.load_macro_from_file(macro_file_path: builtins.str) -> Dict[builtins.str, Any] {
    return Trajectory.load_macro_sequence(macro_file_path);
}

impl MacroPlayer.load_macro_from_folder(
    trajectory_folder: builtins.str
) -> Dict[builtins.str, Any] {
    return Trajectory.load_macro_sequence(trajectory_folder);
}

impl MacroPlayer._load_credential_manager -> any {
    if self.credential_manager is not None {
        return self.credential_manager;
    }

    ConfigLoader: any = importlib.import_module("mobilerun.config_manager.loader").ConfigLoader;
    FileCredentialManager: any = importlib.import_module(
        "mobilerun.credential_manager"
    ).FileCredentialManager;

    config_path: any = self.config_path;
    if config_path is None {
        user_config_path: any = ConfigLoader.get_user_config_path();
        if not user_config_path.exists() {
            self._credential_load_error = "no Mobilerun config file was found";
            return None;
        }
        config_path = `str(user_config_path);
    }

    try {
        config: any = ConfigLoader.load(config_path);
        credential_manager: any = FileCredentialManager(config.credentials);
    } except Exception as e {
        self._credential_load_error = `str(e);
        logger.debug("Failed to load credentials for macro replay: %s", e);
        return None;
    }

    if not credential_manager.secrets {
        self._credential_load_error = "credentials are disabled or empty";
        return None;
    }

    self.credential_manager = credential_manager;
    self._credential_load_error = None;
    return self.credential_manager;
}

impl MacroPlayer.get_current_state_snapshot -> Dict[builtins.str, Any] {
    driver: any = (await self._initialize_driver());
    if self.state_provider is None and isinstance(driver, AndroidDriver) {
        self.state_provider = AndroidStateProvider(
            driver,
            tree_filter=DetailedFilter(),
            tree_formatter=IndexedFormatter(),
            use_normalized=False,
        );
    }
    if self.state_provider is not None {
        try {
            return normalize_ui_state((await self.state_provider.get_state()));
        } except Exception as e {
            logger.debug("Falling back to raw driver state: %s", e);
        }
    }
    raw_state: any = (await driver.get_ui_tree());
    return normalize_ui_state(raw_state);
}

impl MacroPlayer.wait_for_pre_state(
    pre_state: Optional[Dict[builtins.str, Any]], step_number: builtins.int
) -> builtins.tuple[builtins.bool, Optional[Dict[builtins.str, Any]], Optional[StateMatchResult]] {
    if not pre_state {
        return (True, None, None);
    }

    deadline: any = time.monotonic() + self.state_timeout;
    last_state: any = None;
    last_result: any = None;

    while True {
        current_state: any = (await self.get_current_state_snapshot());
        result: any = compare_states(pre_state, current_state, self.state_threshold);
        if result.matches {
            return (True, current_state, result);
        }

        last_state = current_state;
        last_result = result;
        if time.monotonic() >= deadline {
            logger.error("State mismatch before step %s: %s", step_number, result.reason);
            return (False, last_state, last_result);
        }

        (await asyncio.sleep(self.state_poll_interval));
    }
}

impl MacroPlayer.replay_action(
    action: Dict[builtins.str, Any], current_state: Optional[Dict[builtins.str, Any]] = None
) -> builtins.bool {
    driver: any = (await self._initialize_driver());
    action_type: any = action.get("action_type", action.get("type", "unknown"));

    try {
        if action_type == "start_app" {
            package: any = action.get("package");
            activity: any = action.get("activity", None);
            (await driver.start_app(package, activity));
            return True;
        } elif action_type == "tap" {
            x: any = action.get("x", 0);
            y: any = action.get("y", 0);
            logger.info(f"🫰 Tapping at ({x}, {y})");
            (await driver.tap(x, y));
            return True;
        } elif action_type == "swipe" {
            start_x: any = action.get("start_x", 0);
            start_y: any = action.get("start_y", 0);
            end_x: any = action.get("end_x", 0);
            end_y: any = action.get("end_y", 0);
            duration_ms: any = action.get("duration_ms", 300);

            logger.info(
                f"👆 Swiping from ({start_x}, {start_y}) to ({end_x}, {end_y}) in {duration_ms}ms"
            );
            (await driver.swipe(start_x, start_y, end_x, end_y, duration_ms));
            (await asyncio.sleep(2));
            return True;
        } elif action_type == "drag" {
            start_x = action.get("start_x", 0);
            start_y = action.get("start_y", 0);
            end_x = action.get("end_x", 0);
            end_y = action.get("end_y", 0);
            duration: any = action.get("duration", action.get("duration_ms", 300) / 1000.0);

            logger.info(f"👆 Dragging from ({start_x}, {start_y}) to ({end_x}, {end_y})");
            (await driver.drag(start_x, start_y, end_x, end_y, duration));
            return True;
        } elif action_type == "input_text" {
            text: any = action.get("text", "");
            clear: any = action.get("clear", False);
            logger.info(f"⌨️  Inputting text: '{text}'");
            (await driver.input_text(text, clear));
            return True;
        } elif action_type == "type_secret" {
            secret_id: any = action.get("secret_id");
            clear = action.get("clear", False);
            if not secret_id {
                logger.error("❌ Secret macro action is missing secret_id");
                return False;
            }

            credential_manager: any = self._load_credential_manager();
            if credential_manager is None {
                detail: any = f": {self._credential_load_error}"
                    if self._credential_load_error
                    else "";
                logger.error(
                    "❌ Cannot replay secret '%s'; no credentials are available%s", secret_id, detail
                );
                return False;
            }

            try {
                secret_value: any = (await credential_manager.resolve_key(secret_id));
            } except Exception as e {
                logger.error("❌ Secret '%s' is not available: %s", secret_id, e);
                return False;
            }

            logger.info("⌨️  Inputting secret: '%s'", secret_id);
            (await driver.input_text(secret_value, clear));
            return True;
        } elif action_type == "key_press" {
            keycode: any = action.get("keycode", 0);
            button: any = _KEYCODE_TO_BUTTON.get(keycode);
            if button {
                logger.info(f"🔘 Pressing button: {button}");
                (await driver.press_button(button));
            } else {
                logger.warning(f"⚠️  Unknown keycode {keycode}, skipping");
            }
            return True;
        } elif action_type == "button_press" {
            button = action.get("button", "");
            logger.info(f"🔘 Pressing button: {button}");
            (await driver.press_button(button));
            return True;
        } elif action_type == "back" {
            logger.info("⬅️  Pressing back button");
            (await driver.press_button("back"));
            return True;
        } elif action_type == "wait" {
            duration = action.get("duration", 1.0);
            logger.info(f"⏳ Waiting for {duration} seconds");
            (await asyncio.sleep(duration));
            return True;
        } else {
            logger.warning(f"⚠️  Unknown action type: {action_type}");
            return False;
        }
    } except Exception as e {
        logger.error(f"❌ Error executing action {action_type}: {e}");
        return False;
    }
}

impl MacroPlayer.replay_macro(
    macro_data: Dict[builtins.str, Any],
    start_from_step: builtins.int = 0,
    max_steps: Optional[builtins.int] = None,
) -> builtins.bool {
    if not macro_data or "actions" not in macro_data {
        logger.error("❌ Invalid macro data - no actions found");
        return False;
    }
    if macro_data.get("macro_schema_version") != MACRO_SCHEMA_VERSION {
        raise ValueError(UNSUPPORTED_SCHEMA_MESSAGE);
    }

    actions: any = macro_data["actions"];
    description: any = macro_data.get("description", "Unknown macro");
    total_actions: any = len(actions);
    if start_from_step > 0 {
        actions = actions[start_from_step:];
        logger.info(f"📍 Starting from step {start_from_step + 1}");
    }

    if max_steps is not None {
        actions = actions[:max_steps];
        logger.info(f"🎯 Limiting to {max_steps} steps");
    }

    logger.info(f"🎬 Starting macro replay: '{description}'");
    logger.info(f"📊 Total actions to execute: {len(actions)} / {total_actions}");

    success_count: any = 0;
    failed_count: any = 0;

    for (i, action) in enumerate(actions, start_from_step + 1) {
        action_type: any = action.get("action_type", action.get("type", "unknown"));
        description_text: any = action.get("description", "");

        logger.info(f"\n📍 Step {i}/{total_actions}: {action_type}");
        if description_text {
            logger.info(f"   Description: {description_text}");
        }

        (state_matched, current_state, match_result) = (
            await self.wait_for_pre_state(action.get("pre_state"), i)
        ) as any;
        if not state_matched {
            self.last_divergence = {
                "step": i,
                "action_type": action_type,
                "reason": match_result.reason if match_result else "state mismatch",
                "score": match_result.score if match_result else None,
            };
            if self.on_mismatch == "agent" {
                logger.warning("🤖 Handing off to agent after macro divergence");
                return (
                    await self.handoff_runner(
                        goal=description,
                        device_serial=self.device_serial,
                        provider=self.provider,
                        model=self.model,
                        config_path=self.config_path,
                        divergence=self.last_divergence,
                        current_state=current_state or {},
                        remaining_actions=macro_data["actions"][i - 1:],
                    )
                );
            }
            return False;
        }
        success: any = (await self.replay_action(action, current_state=current_state));

        if success {
            success_count += 1;
            logger.info("   ✅ Action completed successfully");
        } else {
            failed_count += 1;
            logger.error("   ❌ Action failed");
        }
        if i < start_from_step + len(actions) {
            logger.debug(f"   ⏳ Waiting {self.delay_between_actions}s...");
            (await asyncio.sleep(self.delay_between_actions));
        }
    }
    total_executed: any = success_count + failed_count;
    success_rate: any = success_count / total_executed * 100 if total_executed > 0 else 0;

    logger.info("\n🎉 Macro replay completed!");
    logger.info(f"📊 Success: {success_count}/{total_executed} ({success_rate:.1f}%)");

    if failed_count > 0 {
        logger.warning(f"⚠️  Failed actions: {failed_count}");
    }

    return operator.eq(failed_count, 0);
}

impl replay_macro_file(
    macro_file_path: builtins.str,
    device_serial: builtins.str = None,
    delay_between_actions: builtins.float = 1.0,
    start_from_step: builtins.int = 0,
    max_steps: Optional[builtins.int] = None,
    on_mismatch: builtins.str = "stop",
    state_timeout: builtins.float = 5.0,
    state_threshold: builtins.float = 0.85,
) -> builtins.bool {
    player: any = MacroPlayer(
        device_serial=device_serial,
        delay_between_actions=delay_between_actions,
        on_mismatch=on_mismatch,
        state_timeout=state_timeout,
        state_threshold=state_threshold,
    );

    try {
        macro_data: any = player.load_macro_from_file(macro_file_path);
        return await player.replay_macro(
            macro_data, start_from_step=start_from_step, max_steps=max_steps
        );
    } except Exception as e {
        logger.error(f"❌ Error replaying macro file {macro_file_path}: {e}");
        return False;
    }
}

impl replay_macro_folder(
    trajectory_folder: builtins.str,
    device_serial: builtins.str = None,
    delay_between_actions: builtins.float = 1.0,
    start_from_step: builtins.int = 0,
    max_steps: Optional[builtins.int] = None,
    on_mismatch: builtins.str = "stop",
    state_timeout: builtins.float = 5.0,
    state_threshold: builtins.float = 0.85,
) -> builtins.bool {
    player: any = MacroPlayer(
        device_serial=device_serial,
        delay_between_actions=delay_between_actions,
        on_mismatch=on_mismatch,
        state_timeout=state_timeout,
        state_threshold=state_threshold,
    );

    try {
        macro_data: any = player.load_macro_from_folder(trajectory_folder);
        return await player.replay_macro(
            macro_data, start_from_step=start_from_step, max_steps=max_steps
        );
    } except Exception as e {
        logger.error(f"❌ Error replaying macro folder {trajectory_folder}: {e}");
        return False;
    }
}
