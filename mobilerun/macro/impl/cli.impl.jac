impl configure_logging(debug: builtins.bool = False) -> any {
    logger: any = logging.getLogger("mobilerun-macro");
    logger.handlers = [];

    handler: any = logging.StreamHandler();

    if debug {
        level: any = logging.DEBUG;
        formatter: any = logging.Formatter("%(levelname)s %(name)s %(message)s", "%H:%M:%S");
    } else {
        level = logging.INFO;
        formatter = logging.Formatter("%(message)s", "%H:%M:%S");
    }

    handler.setFormatter(formatter);
    logger.addHandler(handler);
    logger.setLevel(level);
    logger.propagate = False;

    return logger;
}

impl macro_cli -> any {}

impl replay(
    path: builtins.str,
    device: Optional[builtins.str],
    delay: builtins.float,
    start_from: builtins.int,
    max_steps: Optional[builtins.int],
    debug: builtins.bool,
    dry_run: builtins.bool,
    on_mismatch: builtins.str,
    state_timeout: builtins.float,
    state_threshold: builtins.float,
    config_path: Optional[builtins.str],
    provider: Optional[builtins.str],
    model: Optional[builtins.str],
) -> any {
    logger: any = configure_logging(debug);

    logger.info("🎬 Mobilerun Macro Replay");
    start_from_zero: any = max(0, start_from - 1);

    asyncio.run(
        _replay_with_device(
            path,
            device,
            delay,
            start_from_zero,
            max_steps,
            dry_run,
            logger,
            functools.partial(_get_device, device, dry_run, logger),
            on_mismatch,
            state_timeout,
            state_threshold,
            config_path,
            provider,
            model,
        ),
    );
}

impl _get_device(device, dry_run: builtins.bool, logger: logging.Logger) -> any {
    if device is None {
        logger.info("🔍 Finding connected device...");
        try {
            dev: any = await resolve_android_serial();
        } except Exception as e {
            if dry_run {
                logger.warning(f"⚠️  {e}");
                return None;
            }
            if isinstance(e, AndroidDeviceSelectionError) {
                raise click.ClickException(`str(e)) from None;
            }
            raise;
        }
        logger.info(f"📱 Using device: {dev}");
        return dev;
    }
    logger.info(f"📱 Using device: {device}");
    return device;
}

impl _replay_with_device(
    path: builtins.str,
    device: builtins.str,
    delay: builtins.float,
    start_from: builtins.int,
    max_steps: Optional[builtins.int],
    dry_run: builtins.bool,
    logger: logging.Logger,
    get_device,
    on_mismatch: builtins.str,
    state_timeout: builtins.float,
    state_threshold: builtins.float,
    config_path: Optional[builtins.str],
    provider: Optional[builtins.str],
    model: Optional[builtins.str],
) -> any {
    device = await get_device();
    await _replay_async(
        path,
        device,
        delay,
        start_from,
        max_steps,
        dry_run,
        logger,
        on_mismatch,
        state_timeout,
        state_threshold,
        config_path,
        provider,
        model,
    );
}

impl _replay_async(
    path: builtins.str,
    device: builtins.str,
    delay: builtins.float,
    start_from: builtins.int,
    max_steps: Optional[builtins.int],
    dry_run: builtins.bool,
    logger: logging.Logger,
    on_mismatch: builtins.str,
    state_timeout: builtins.float,
    state_threshold: builtins.float,
    config_path: Optional[builtins.str],
    provider: Optional[builtins.str],
    model: Optional[builtins.str],
) -> any {
    try {
        resolved_path: any = PathResolver.resolve(path, must_exist=True);

        if resolved_path.is_file() {
            logger.info(f"📄 Loading macro from file: {resolved_path}");
            player: any = MacroPlayer(
                device_serial=device,
                delay_between_actions=delay,
                on_mismatch=on_mismatch,
                state_timeout=state_timeout,
                state_threshold=state_threshold,
                config_path=config_path,
                provider=provider,
                model=model,
            );
            macro_data: any = player.load_macro_from_file(`str(resolved_path));
        } elif resolved_path.is_dir() {
            logger.info(f"📁 Loading macro from folder: {resolved_path}");
            player = MacroPlayer(
                device_serial=device,
                delay_between_actions=delay,
                on_mismatch=on_mismatch,
                state_timeout=state_timeout,
                state_threshold=state_threshold,
                config_path=config_path,
                provider=provider,
                model=model,
            );
            macro_data = player.load_macro_from_folder(`str(resolved_path));
        } else {
            logger.error(f"❌ Invalid path: {resolved_path}");
            return;
        }

        if not macro_data {
            logger.error("❌ Failed to load macro data");
            return;
        }
        description: any = macro_data.get("description", "No description");
        total_actions: any = macro_data.get("total_actions", 0);
        version: any = macro_data.get("macro_schema_version", macro_data.get("version", "unknown"));

        logger.info("📋 Macro Information:");
        logger.info(f"   Description: {description}");
        logger.info(f"   Version: {version}");
        logger.info(f"   Total actions: {total_actions}");
        logger.info("   Device: " + format(device or "not selected", ""));
        logger.info(f"   Delay between actions: {delay}s");
        logger.info(f"   State threshold: {state_threshold}");
        logger.info(f"   State timeout: {state_timeout}s");
        logger.info(f"   On mismatch: {on_mismatch}");

        if start_from > 0 {
            logger.info(f"   Starting from step: {start_from + 1}");
        }
        if max_steps {
            logger.info(f"   Maximum steps: {max_steps}");
        }

        if dry_run {
            logger.info("🔍 DRY RUN MODE - Actions will be shown but not executed");
            await _show_dry_run(macro_data, start_from, max_steps, logger);
        } else {
            logger.info("▶️  Starting macro replay...");
            success: any = await player.replay_macro(
                macro_data, start_from_step=start_from, max_steps=max_steps
            );

            if success {
                logger.info("🎉 Macro replay completed successfully!");
            } else {
                logger.error("💥 Macro replay completed with errors");
            }
        }
    } except Exception as e {
        logger.error(f"💥 Error: {e}");
        if logger.isEnabledFor(logging.DEBUG) {
            import traceback;

            logger.debug(traceback.format_exc());
        }
    }
}

impl _show_dry_run(
    macro_data: builtins.dict,
    start_from: builtins.int,
    max_steps: Optional[builtins.int],
    logger: logging.Logger,
) -> any {
    actions: any = macro_data.get("actions", []);
    if start_from > 0 {
        actions = actions[start_from:];
    }
    if max_steps {
        actions = actions[:max_steps];
    }

    logger.info(f"📋 Found {len(actions)} actions to execute:");

    table: any = Table(title="Actions to Execute");
    table.add_column("Step", style="cyan");
    table.add_column("Type", style="green");
    table.add_column("Details", style="white");
    table.add_column("Description", style="yellow");

    for (i, action) in enumerate(actions, start_from + 1) {
        action_type: any = action.get("action_type", action.get("type", "unknown"));
        details: any = "";

        if action_type == "tap" {
            x: any;
            y: any;
            (x, y) = (action.get("x", 0), action.get("y", 0));
            element_text: any = action.get("element_text", "");
            details = f"({x}, {y}) - '{element_text}'";
        } elif action_type == "swipe" {
            start_x: any;
            start_y: any;
            (start_x, start_y) = (action.get("start_x", 0), action.get("start_y", 0));
            end_x: any;
            end_y: any;
            (end_x, end_y) = (action.get("end_x", 0), action.get("end_y", 0));
            details = f"({start_x}, {start_y}) → ({end_x}, {end_y})";
        } elif action_type == "input_text" {
            text: any = action.get("text", "");
            details = f"'{text}'";
        } elif action_type == "key_press" {
            key_name: any = action.get("key_name", "UNKNOWN");
            details = f"{key_name}";
        } elif action_type == "button_press" {
            button: any = action.get("button", "unknown");
            details = f"{button}";
        } elif action_type == "wait" {
            duration: any = action.get("duration", 1.0);
            details = f"{duration}s";
        }

        description: any = action.get("description", "");
        table.add_row(
            `str(i),
            action_type,
            details,
            description[:50] + "..." if len(description) > 50 else description,
        );
    }
    console.print(table);
}

impl `list(directory: builtins.str, debug: builtins.bool) -> any {
    logger: any = configure_logging(debug);
    resolved_dir: any = PathResolver.resolve(directory, must_exist=True);
    logger.info(f"📁 Scanning directory: {resolved_dir}");

    try {
        folders: any = [];
        for item in resolved_dir.iterdir() {
            if item.is_dir() {
                macro_file: any = item / "macro.json";
                if macro_file.exists() {
                    try {
                        macro_data: any = Trajectory.load_macro_sequence(`str(item));
                        description: any = macro_data.get("description", "No description");
                        total_actions: any = macro_data.get("total_actions", 0);
                        folders.append((item.name, description, total_actions));
                    } except Exception as e {
                        logger.debug(f"Error loading macro from {item.name}: {e}");
                        folders.append((item.name, "Error loading", 0));
                    }
                }
            }
        }

        if not folders {
            logger.info("📭 No trajectory folders found");
            return;
        }

        logger.info(f"🎯 Found {len(folders)} trajectory(s):");

        table: any = Table(title=f"Available Trajectories in {directory}");
        table.add_column("Folder", style="cyan");
        table.add_column("Description", style="white");
        table.add_column("Actions", style="green");

        for (folder, description, actions) in sorted(folders) {
            table.add_row(
                folder,
                description[:80] + "..." if len(description) > 80 else description,
                `str(actions),
            );
        }
        console.print(table);
        logger.info(
            f"💡 Use 'mobilerun macro replay {resolved_dir}/<folder>' to replay a trajectory"
        );
    } except Exception as e {
        logger.error(f"💥 Error: {e}");
        if logger.isEnabledFor(logging.DEBUG) {
            import traceback;

            logger.debug(traceback.format_exc());
        }
    }
}
