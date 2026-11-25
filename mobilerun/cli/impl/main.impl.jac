impl _validate_oauth_timeout(
    _ctx: click.Context, _param: click.Parameter, value: builtins.float
) -> builtins.float {
    if not math.isfinite(value) or value <= 0 {
        raise click.BadParameter("must be a finite number greater than zero");
    }
    return value;
}

impl _force_screenshot_only_vision(config: MobileConfig) -> None {
    config.agent.vision_only = True;
    config.agent.manager.vision = True;
    config.agent.executor.vision = True;
    config.agent.fast_agent.vision = True;
}

impl _setup_cli_logging(debug: builtins.bool) -> None {
    handler: any = CLILogHandler();
    handler.setFormatter(
        logging.Formatter("%(levelname)s %(name)s %(message)s", "%H:%M:%S")
            if debug
            else logging.Formatter("%(message)s"),
    );
    configure_logging(debug=debug, handler=handler);
}

impl _run_coroutine(f, *args_, **kwargs) -> any {
    args: any = tuple(args_);
    return asyncio.run(f(*args, **kwargs));
}

impl coro(f) -> any {
    return wraps(f)(partial(_run_coroutine, f));
}

impl run_command(
    command: builtins.str,
    config_path: builtins.str | None = None,
    device: builtins.str | None = None,
    agent: builtins.str | None = None,
    provider: builtins.str | None = None,
    model: builtins.str | None = None,
    steps: builtins.int | None = None,
    base_url: builtins.str | None = None,
    api_base: builtins.str | None = None,
    vision: builtins.bool | None = None,
    vision_only: builtins.bool | None = None,
    manager_vision: builtins.bool | None = None,
    executor_vision: builtins.bool | None = None,
    fast_agent_vision: builtins.bool | None = None,
    reasoning: builtins.bool | None = None,
    stream: builtins.bool | None = None,
    tracing: builtins.bool | None = None,
    debug: builtins.bool | None = None,
    tcp: builtins.bool | None = None,
    control_backend: builtins.str | None = None,
    device_id: builtins.str | None = None,
    save_trajectory: builtins.str | None = None,
    ios: builtins.bool = False,
    temperature: builtins.float | None = None,
    **kwargs,
) -> builtins.bool {
    config: any = ConfigLoader.load(config_path);
    if config.logging.rich_text {
        cloud_text: any = Text();
        cloud_text.append("✨ Try Mobilerun Cloud: ", style="bold cyan");
        cloud_text.append("https://cloud.mobilerun.ai/sign-in", style="bold blue underline");
        cloud_panel: any = Panel(cloud_text, border_style="cyan", padding=(0, 1));
        console.print(cloud_panel);
    } else {
        console.print("\n✨ Try Mobilerun Cloud: https://cloud.mobilerun.ai/sign-in\n");
    }
    debug_mode: any = debug if debug is not None else config.logging.debug;
    _setup_cli_logging(debug_mode);
    logger: any = logging.getLogger("mobilerun");
    droid_agent: any = None;

    try {
        logger.info(f"🚀 Starting: {command}");
        print_telemetry_message(config_enabled=config.telemetry.enabled);
        if vision_only is not None {
            config.agent.vision_only = vision_only;
        }

        if config.agent.vision_only {
            _force_screenshot_only_vision(config);
            logger.debug("CLI override: vision_only=True");
        } elif vision is not None {
            config.agent.manager.vision = vision;
            config.agent.executor.vision = vision;
            config.agent.fast_agent.vision = vision;
            logger.debug(f"CLI override: vision={vision} (all agents)");
        } else {
            if manager_vision is not None {
                config.agent.manager.vision = manager_vision;
            }
            if executor_vision is not None {
                config.agent.executor.vision = executor_vision;
            }
            if fast_agent_vision is not None {
                config.agent.fast_agent.vision = fast_agent_vision;
            }
        }
        if agent is not None {
            config.agent.name = agent;
        }
        if steps is not None {
            config.agent.max_steps = steps;
        }
        if reasoning is not None {
            config.agent.reasoning = reasoning;
        }
        if stream is not None {
            config.agent.streaming = stream;
        }
        if device is not None {
            config.device.serial = device;
        }
        if tcp is not None {
            config.device.use_tcp = tcp;
        }
        if control_backend is not None {
            config.device.control_backend = control_backend;
        }
        if device_id is not None {
            config.device.device_id = device_id;
        }

        if (config.device.control_backend or "").strip().lower() == VISUAL_REMOTE_CONNECTION {
            _force_screenshot_only_vision(config);
            logger.debug("Control backend visual-remote forces screenshot-only vision");
        }
        if debug is not None {
            config.logging.debug = debug;
        }
        if save_trajectory is not None {
            config.logging.save_trajectory = save_trajectory;
        }
        if tracing is not None {
            config.tracing.enabled = tracing;
        }
        if ios {
            config.device.platform = "ios";
            if (config.device.control_backend or "").lower()
                == VISUAL_REMOTE_CONNECTION
            {} elif config.device.serial {
                config.device.serial = validate_ios_portal_url(config.device.serial);
            } else {
                logger.info("🔍 Searching for iOS portal...");
                config.device.serial = await discover_ios_device();
            }
        }

        mode: any = "planning with reasoning" if config.agent.reasoning else "direct execution";
        logger.info(f"🤖 Agent mode: {mode}");
        logger.info(
            f"👁️  Vision settings: Manager={config.agent.manager.vision}, Executor={config.agent.executor.vision}, FastAgent={config.agent.fast_agent.vision}",
        );

        if config.tracing.enabled {
            logger.info("🔍 Tracing enabled");
        }
        droid_agent_kwargs: any = {"runtype": "cli"};
        llm: any = None;

        if provider or model {
            assert provider
                and model, "Either both provider and model must be provided or none of them";
            llm_kwargs: any = {};
            if temperature is not None {
                llm_kwargs["temperature"] = temperature;
            }
            if base_url is not None {
                llm_kwargs["base_url"] = base_url;
            }
            if api_base is not None {
                llm_kwargs["api_base"] = api_base;
            }
            llm = load_llm(provider, model=model, **llm_kwargs, **kwargs);
        } else {
            if temperature is not None {
                droid_agent_kwargs["temperature"] = temperature;
            }
            if base_url is not None {
                droid_agent_kwargs["base_url"] = base_url;
            }
            if api_base is not None {
                droid_agent_kwargs["api_base"] = api_base;
            }
        }

        droid_agent = MobileAgent(
            goal=command, llms=llm, config=config, timeout=1000, **droid_agent_kwargs
        );

        logger.debug("▶️  Starting agent execution...");
        logger.debug("Press Ctrl+C to stop");

        event_handler: any = EventHandler();

        try {
            handler: any = droid_agent.run();

            async for event in handler.stream_events() {
                event_handler.handle(event);
            }
            result: any = await handler;
            return result.success;
        } except KeyboardInterrupt {
            logger.info("⏹️ Stopped by user");
            return False;
        } except Exception as e {
            err_desc: any = describe_error(e) or `type(e).__name__;
            logger.error(f"💥 Error: {err_desc}");
            if config.logging.debug {
                import traceback;

                logger.debug(traceback.format_exc());
            }
            return False;
        }
    } except Exception as e {
        err_desc = describe_error(e) or `type(e).__name__;
        logger.error(f"💥 Setup error: {err_desc}");
        if debug_mode {
            import traceback;

            logger.debug(traceback.format_exc());
        }
        return False;
    } finally {
        await _cleanup_android_keyboard(config, getattr(droid_agent, "android_serial", None));
    }
}

impl _cleanup_android_keyboard(config: MobileConfig, serial: builtins.str | None = None) -> None {
    platform: any = (config.device.platform or "").lower();
    control_backend: any = (config.device.control_backend or "").lower();
    if platform == "ios" or control_backend == VISUAL_REMOTE_CONNECTION {
        return;
    }
    serial = serial or config.device.serial;
    if not serial or is_portal_http_url(serial) {
        return;
    }

    try {
        device_obj: any = await adb.device(serial);
        if device_obj {
            import from mobilerun_core_local.driver.android.portal {
                PORTAL_PACKAGE_NAME,
                portal_ime_id,
            }

            ime: any = portal_ime_id(PORTAL_PACKAGE_NAME);
            await device_obj.shell(f"ime disable {ime}");
        }
    } except Exception {
        click.echo("Failed to disable Mobilerun keyboard");
    }
}

impl _print_version(ctx, param, value) -> any {
    if not value or ctx.resilient_parsing {
        return;
    }
    version: any = None;
    try {
        version = importlib.metadata.version("mobilerun");
    } except Exception {}

    if not version {
        try {
            pkg_version: any = importlib.import_module("mobilerun").__version__;

            version = pkg_version;
        } except Exception {}
    }

    if not version {
        try {
            repo_root: any = Path(__file__).resolve().parents[2];
            pyproject: any = repo_root / "pyproject.toml";
            if pyproject.exists() {
                with pyproject.open("rb") as f {
                    data: any = tomllib.load(f);
                    version = data.get("project", {}).get("version");
                }
            }
        } except Exception {
            version = None;
        }
    }

    if not version {
        version = "unknown";
    }
    click.echo(f"v{version}");
    ctx.exit();
}

impl cli -> any {}

impl _print_oauth_login_success(
    provider_label: builtins.str, credential_path: builtins.str
) -> None {
    console.print(f"[green]{provider_label} login succeeded.[/]");
    console.print(f"[blue]Credentials saved to:[/] {Path(credential_path).expanduser()}");
}

impl _run_openai_oauth_login(
    credential_path: builtins.str, model: builtins.str | None, **kwargs
) -> None {
    run_openai_oauth_login(credential_path=credential_path, model=model, **kwargs);
    _print_oauth_login_success("OpenAI", credential_path);
}

impl _run_gemini_oauth_login(
    credential_path: builtins.str, model: builtins.str | None, **kwargs
) -> None {
    run_gemini_oauth_login(credential_path=credential_path, model=model, **kwargs);
    _print_oauth_login_success("Gemini", credential_path);
}

impl _run_anthropic_oauth_login(credential_path: builtins.str, **kwargs) -> None {
    console.print("[blue]Starting Anthropic login...[/]");
    run_anthropic_setup_token_oauth(credential_path=credential_path, **kwargs);
    _print_oauth_login_success("Anthropic", credential_path);
}

impl _run_grok_oauth_login(
    credential_path: builtins.str, model: builtins.str | None = None, **kwargs
) -> None {
    run_grok_oauth_login(credential_path=credential_path, model=model, **kwargs);
    _print_oauth_login_success("XAI", credential_path);
}

impl run(
    command: builtins.str,
    config: builtins.str | None,
    device: builtins.str | None,
    agent: builtins.str | None,
    provider: builtins.str | None,
    model: builtins.str | None,
    steps: builtins.int | None,
    base_url: builtins.str | None,
    api_base: builtins.str | None,
    temperature: builtins.float | None,
    vision: builtins.bool | None,
    vision_only: builtins.bool | None,
    reasoning: builtins.bool | None,
    stream: builtins.bool | None,
    tracing: builtins.bool | None,
    debug: builtins.bool | None,
    tcp: builtins.bool | None,
    control_backend: builtins.str | None,
    device_id: builtins.str | None,
    save_trajectory: builtins.str | None,
    ios: builtins.bool,
) -> any {
    success: any = await run_command(
        command=command,
        config_path=config,
        device=device,
        agent=agent,
        provider=provider,
        model=model,
        steps=steps,
        base_url=base_url,
        api_base=api_base,
        vision=vision,
        vision_only=vision_only,
        reasoning=reasoning,
        stream=stream,
        tracing=tracing,
        debug=debug,
        tcp=tcp,
        control_backend=control_backend,
        device_id=device_id,
        temperature=temperature,
        save_trajectory=save_trajectory,
        ios=ios,
    );
    sys.exit(0 if success else 1);
}

impl _list_cloud_devices(
    base_url: builtins.str | None,
    *,
    silent_if_no_key: builtins.bool = False,
    raise_on_error: builtins.bool = False,
    silent_errors: builtins.bool = False,
) -> builtins.int {
    api_key = resolve_cloud_api_key();
    if not api_key {
        if silent_if_no_key {
            return 0;
        }
        message: any = f"No cloud API key found. Set {CLOUD_API_KEY_ENV} or run `mobilerun login`.";
        if raise_on_error {
            raise click.ClickException(message);
        }
        console.print(f"[red]{message}[/]");
        return 0;
    }

    import from mobilerun_sdk { AsyncMobilerun }

    client: any = AsyncMobilerun(
        api_key=api_key, base_url=base_url or DEFAULT_CLOUD_BASE_URL, timeout=30.0
    );
    try {
        resp: any = await client.devices.list();
    } except Exception as e {
        if silent_errors {
            return 0;
        }
        if raise_on_error {
            raise click.ClickException(f"Error listing cloud devices: {e}") from e;
        }
        console.print(f"[red]Error listing cloud devices: {e}[/]");
        return 0;
    }

    items: any = getattr(resp, "items", None) or [];
    if not items {
        console.print("[yellow]No cloud devices found.[/]");
        return 0;
    }

    console.print(f"[green]Found {len(items)} cloud device(s):[/]");
    for item in items {
        data: any = item.model_dump() if hasattr(item, "model_dump") else `dict(item);
        device_id: any = data.get("id", "");
        name: any = data.get("name", "");
        state: any = data.get("state", "");
        dtype: any = data.get("type", "");
        state_color: any = "green" if state == "ready" else "yellow";
        console.print(
            f"  • [bold]{device_id}[/]  {name}  \\[[{state_color}]{state}[/]]  [dim]{dtype}[/]"
        );
    }
    return len(items);
}

impl devices(cloud: builtins.bool, base_url: builtins.str | None) -> any {
    if cloud {
        await _list_cloud_devices(base_url, raise_on_error=True);
        return;
    }
    try {
        local: any = await adb.list();
        if not local {
            console.print("[yellow]No local devices connected.[/]");
        } else {
            console.print(f"[green]Found {len(local)} local device(s):[/]");
            for device in local {
                console.print(f"  • [bold]{device.serial}[/]");
            }
        }
    } except Exception as e {
        console.print(f"[red]Error listing local devices: {e}[/]");
    }
    if resolve_cloud_api_key() {
        console.print();
        await _list_cloud_devices(base_url, silent_if_no_key=True, silent_errors=True);
    }
}

impl login(auth_url: builtins.str | None, client_id: builtins.str) -> any {
    import webbrowser;

    deviceauth: any = importlib.import_module("mobilerun.cli.deviceauth");

    auth_url = auth_url or os.getenv("MOBILERUN_AUTH_URL") or DEFAULT_AUTH_URL;

    try {
        code: any = deviceauth.request_code(auth_url, client_id);
    } except Exception as e {
        raise click.ClickException(f"request device code: {e}") from e;
    }

    console.print(f"Visit: [bold]{code.verification_uri}[/]");
    console.print(f"Code:  [bold cyan]{code.user_code}[/]");
    if code.verification_uri_complete {
        console.print(f"[dim](Opening {code.verification_uri_complete} ...)[/]");
        try {
            webbrowser.open(code.verification_uri_complete);
        } except Exception {}
    }
    console.print(f"[dim]Waiting for authorization (expires in {code.expires_in}s)...[/]");

    try {
        token: any = deviceauth.poll_token(auth_url, client_id, code);
    } except deviceauth.DeviceAuthError as e {
        raise click.ClickException(f"authorization failed: {e}") from e;
    } except KeyboardInterrupt {
        raise click.ClickException("login cancelled") from None;
    }

    path: any = deviceauth.save_token(token, auth_url);
    email: any = None;
    try {
        info: any = deviceauth.fetch_session(auth_url, token);
        if info {
            email = info.get("user", {}).get("email");
        }
    } except Exception {}
    who: any = f" as {email}" if email else "";
    console.print(f"[green]Logged in{who}.[/] Token saved to {path}");
}

impl logout -> any {
    deviceauth: any = importlib.import_module("mobilerun.cli.deviceauth");

    if deviceauth.clear_credentials() {
        console.print("[green]Logged out.[/]");
    } else {
        console.print("[yellow]Not logged in.[/]");
    }
}

impl whoami -> any {
    deviceauth: any = importlib.import_module("mobilerun.cli.deviceauth");

    creds: any = deviceauth.load_credentials();
    token: any = (creds or {}).get("access_token");
    auth_url: any = (creds or {}).get("auth_url") or DEFAULT_AUTH_URL;
    if not token {
        raise click.ClickException("Not logged in (run `mobilerun login`).");
    }
    try {
        info: any = deviceauth.fetch_session(auth_url, token);
    } except Exception as e {
        raise click.ClickException(f"session check failed: {e}") from e;
    }
    if info is None {
        raise click.ClickException("Session not recognized (run `mobilerun login` again).");
    }
    user: any = info.get("user", {});
    console.print(
        format(user.get("email", "?"), "") + "  (id: " + format(user.get("id", "?"), "") + ")"
    );
}

impl connect(serial: builtins.str) -> any {
    try {
        device = await adb.connect(serial);
        if device.count("already connected") {
            console.print(f"[green]Successfully connected to {serial}[/]");
        } else {
            console.print(f"[red]Failed to connect to {serial}: {device}[/]");
        }
    } except Exception as e {
        console.print(f"[red]Error connecting to device: {e}[/]");
    }
}

impl disconnect(serial: builtins.str) -> any {
    try {
        success: any = await adb.disconnect(serial, raise_error=True);
        if success {
            console.print(f"[green]Successfully disconnected from {serial}[/]");
        } else {
            console.print(f"[yellow]Device {serial} was not connected[/]");
        }
    } except Exception as e {
        console.print(f"[red]Error disconnecting from device: {e}[/]");
    }
}

impl _wait_for_portal_service(
    device_obj, timeout: builtins.float = 30.0, interval: builtins.float = 1.0
) -> builtins.bool {
    uri: any = portal_content_uri(PORTAL_PACKAGE_NAME, "ping");
    loop: any = asyncio.get_running_loop();
    deadline: any = loop.time() + timeout;
    while loop.time() < deadline {
        try {
            result: any = await device_obj.shell(f"content query --uri {uri}");
            if "\"status\":\"success\"" in result {
                return True;
            }
            if not await check_portal_accessibility(device_obj) {
                await enable_portal_accessibility(device_obj);
            }
        } except Exception {}
        await asyncio.sleep(interval);
    }
    return False;
}

impl _setup_portal(
    path: builtins.str | None,
    device: builtins.str | None,
    debug: builtins.bool,
    latest: builtins.bool = False,
    specific_version: builtins.str | None = None,
    in_place: builtins.bool = False,
) -> any {
    try {
        if not device {
            try {
                device = await resolve_android_serial();
            } except AndroidDeviceSelectionError as e {
                console.print(f"[bold red]Error:[/] {e}");
                return;
            }
            console.print(f"[blue]Using device:[/] {device}");
        }

        device_obj: any = await adb.device(device);
        if not device_obj {
            console.print(f"[bold red]Error:[/] Could not get device object for {device}");
            return;
        }
        if path {
            console.print(f"[bold blue]Using provided APK:[/] {path}");
            apk_context: any = nullcontext(path);
        } elif specific_version {
            version: any = specific_version.lstrip("v");
            version = f"v{version}";
            download_base: any = DOWNLOAD_BASE;
            apk_context = download_versioned_portal_apk(version, download_base, debug);
        } elif latest {
            console.print("[bold blue]Downloading latest Portal APK...[/]");
            apk_context = download_portal_apk(debug);
        } else {
            success: any = await setup_portal(
                device_obj, debug, **portal_version_kwargs(setup_portal, in_place=in_place)
            );
            if success {
                console.print(
                    "\n[bold green]Setup complete![/] The Mobilerun Portal is now installed and ready to use.",
                );
            } else {
                console.print("[bold red]Setup failed.[/] Run 'mobilerun doctor' for diagnostics.");
            }
            return;
        }
        with apk_context as apk_path {
            if not os.path.exists(apk_path) {
                console.print(f"[bold red]Error:[/] APK file not found at {apk_path}");
                return;
            }

            console.print(f"[bold blue]Step 1/2: Installing APK:[/] {apk_path}");
            try {
                await device_obj.install(
                    apk_path, nolaunch=True, uninstall=True, flags=["-g"], silent=not debug
                );
            } except Exception as e {
                console.print(f"[bold red]Installation failed:[/] {e}");
                return;
            }

            console.print("[bold green]Installation successful![/]");

            console.print("[bold blue]Step 2/2: Enabling accessibility service[/]");

            try {
                await enable_portal_accessibility(device_obj);
                if not await _wait_for_portal_service(device_obj) {
                    raise RuntimeError("the service did not respond in time");
                }

                console.print("[green]Accessibility service enabled successfully![/]");
                console.print(
                    "\n[bold green]Setup complete![/] The Mobilerun Portal is now installed and ready to use.",
                );
            } except Exception as e {
                console.print(
                    f"[yellow]Could not automatically enable accessibility service: {e}[/]"
                );
                console.print(
                    "[yellow]Opening accessibility settings for manual configuration...[/]"
                );

                await device_obj.shell("am start -a android.settings.ACCESSIBILITY_SETTINGS");

                console.print("\n[yellow]Please complete the following steps on your device:[/]");
                console.print(
                    f"1. Find [bold]{PORTAL_PACKAGE_NAME}[/] in the accessibility services list"
                );
                console.print("2. Tap on the service name");
                console.print("3. Toggle the switch to [bold]ON[/] to enable the service");
                console.print("4. Accept any permission dialogs that appear");

                console.print(
                    "\n[bold green]APK installation complete![/] Please manually enable the accessibility service using the steps above.",
                );
            }
        }
    } except Exception as e {
        console.print(f"[bold red]Error:[/] {e}");

        if debug {
            import traceback;

            traceback.print_exc();
        }
    }
}

impl setup(
    path: builtins.str | None,
    device: builtins.str | None,
    portal_version: builtins.str | None,
    latest: builtins.bool,
    debug: builtins.bool,
) -> any {
    await _setup_portal(path, device, debug, latest, portal_version);
}

impl ping(
    device: builtins.str | None, tcp: builtins.bool | None, debug: builtins.bool | None
) -> any {
    debug_mode: any = debug if debug is not None else False;
    use_tcp_mode: any = tcp if tcp is not None else False;

    try {
        if is_portal_http_url(device) {
            token: any = ConfigLoader.load(None).device.resolve_auth_token();
            driver: any = create_android_portal_http_driver(device, token);
            await driver.connect();
            await driver.get_ui_tree();
            console.print(
                "[bold green]Portal HTTP is reachable and serving the UI tree. You're good to go![/]",
            );
            return;
        }

        device_obj: any = await adb.device(device);
        if not device_obj {
            console.print(f"[bold red]Error:[/] Could not find device {device}");
            return;
        }

        await ping_portal(device_obj, debug_mode);

        if use_tcp_mode {
            await ping_portal_tcp(device_obj, debug_mode);
        } else {
            await ping_portal_content(device_obj, debug_mode);
        }

        console.print("[bold green]Portal is installed and accessible. You're good to go![/]");
    } except Exception as e {
        console.print(f"[bold red]Error:[/] {e}");
        if debug_mode {
            import traceback;

            traceback.print_exc();
        }
    }
}

impl doctor(device: builtins.str | None, debug: builtins.bool | None) -> any {
    run_doctor: any = importlib.import_module("mobilerun.cli.doctor").run_doctor;

    await run_doctor(device, debug if debug is not None else False);
}

impl configure(
    ctx: click.Context,
    provider: builtins.str | None,
    auth_mode: builtins.str | None,
    model: builtins.str | None,
    api_key: builtins.str | None,
    base_url: builtins.str | None,
) -> any {
    if ctx.invoked_subcommand is not None {
        return;
    }
    run_configure_wizard(
        console,
        ConfigureWizardCallbacks(
            run_openai_oauth_login=_run_openai_oauth_login,
            run_anthropic_oauth_login=_run_anthropic_oauth_login,
            run_gemini_oauth_login=_run_gemini_oauth_login,
            run_grok_oauth_login=_run_grok_oauth_login,
        ),
        provider=provider,
        auth_mode=auth_mode,
        model=model,
        api_key=api_key,
        base_url=base_url,
    );
}

impl configure_openai(
    credential_path: builtins.str,
    model: builtins.str | None,
    timeout: builtins.float,
    callback_host: builtins.str,
    callback_port: builtins.int,
    callback_path: builtins.str,
    open_browser: builtins.bool,
) -> any {
    _run_openai_oauth_login(
        credential_path=credential_path,
        model=model,
        timeout=timeout,
        callback_host=callback_host,
        callback_port=callback_port,
        callback_path=callback_path,
        open_browser=open_browser,
    );
}

impl configure_anthropic(
    credential_path: builtins.str,
    token: builtins.str | None,
    timeout: builtins.float,
    open_browser: builtins.bool,
) -> any {
    if token {
        save_anthropic_setup_token(credential_path, token);
        _print_oauth_login_success("Anthropic", credential_path);
    } else {
        _run_anthropic_oauth_login(
            credential_path=credential_path, timeout=timeout, open_browser=open_browser
        );
    }
}

impl configure_gemini(
    credential_path: builtins.str,
    model: builtins.str | None,
    timeout: builtins.float,
    callback_host: builtins.str,
    callback_port: builtins.int,
    callback_path: builtins.str,
    open_browser: builtins.bool,
) -> any {
    _run_gemini_oauth_login(
        credential_path=credential_path,
        model=model,
        timeout=timeout,
        callback_host=callback_host,
        callback_port=callback_port,
        callback_path=callback_path,
        open_browser=open_browser,
    );
}

impl configure_xai(
    credential_path: builtins.str,
    model: builtins.str | None,
    timeout: builtins.float,
    open_browser: builtins.bool,
    device_code: builtins.bool,
) -> any {
    _run_grok_oauth_login(
        credential_path=credential_path,
        model=model,
        timeout=timeout,
        open_browser=open_browser,
        device_code=device_code,
    );
}

impl `test(
    command: builtins.str,
    config_path: builtins.str | None = None,
    device: builtins.str | None = None,
    steps: builtins.int | None = None,
    vision: builtins.bool | None = None,
    reasoning: builtins.bool | None = None,
    tracing: builtins.bool | None = None,
    debug: builtins.bool | None = None,
    use_tcp: builtins.bool | None = None,
    save_trajectory: builtins.str | None = None,
    temperature: builtins.float | None = None,
    ios: builtins.bool = False,
) -> any {
    config: any = ConfigLoader.load(config_path);
    debug_mode: any = debug if debug is not None else config.logging.debug;
    _setup_cli_logging(debug_mode);
    logger: any = logging.getLogger("mobilerun");

    try {
        logger.info(f"🚀 Starting: {command}");
        print_telemetry_message(config_enabled=config.telemetry.enabled);
        if vision is not None {
            config.agent.manager.vision = vision;
            config.agent.executor.vision = vision;
            config.agent.fast_agent.vision = vision;
            logger.debug(f"CLI override: vision={vision} (all agents)");
        }
        if steps is not None {
            config.agent.max_steps = steps;
        }
        if reasoning is not None {
            config.agent.reasoning = reasoning;
        }
        if device is not None {
            config.device.serial = device;
        }
        if use_tcp is not None {
            config.device.use_tcp = use_tcp;
        }
        if debug is not None {
            config.logging.debug = debug;
        }
        if save_trajectory is not None {
            config.logging.save_trajectory = save_trajectory;
        }
        if tracing is not None {
            config.tracing.enabled = tracing;
        }
        if ios {
            config.device.platform = "ios";
        }

        mode: any = "planning with reasoning" if config.agent.reasoning else "direct execution";
        logger.info(f"🤖 Agent mode: {mode}");
        logger.info(
            f"👁️  Vision settings: Manager={config.agent.manager.vision}, Executor={config.agent.executor.vision}, FastAgent={config.agent.fast_agent.vision}",
        );

        if config.tracing.enabled {
            logger.info("🔍 Tracing enabled");
        }
        droid_agent_kwargs: any = {};
        if temperature is not None {
            droid_agent_kwargs["temperature"] = temperature;
        }

        droid_agent: any = MobileAgent(
            goal=command, config=config, timeout=1000, **droid_agent_kwargs
        );

        logger.debug("▶️  Starting agent execution...");
        logger.debug("Press Ctrl+C to stop");

        event_handler: any = EventHandler();

        try {
            handler: any = droid_agent.run();

            async for event in handler.stream_events() {
                event_handler.handle(event);
            }
            result: any = await handler;
        } except KeyboardInterrupt {
            logger.info("⏹️ Stopped by user");
        } except Exception as e {
            logger.error(f"💥 Error: {describe_error(e)}");
            if config.logging.debug {
                import traceback;

                logger.debug(traceback.format_exc());
            }
        }
    } except Exception as e {
        logger.error(f"💥 Setup error: {e}");
        if debug_mode {
            import traceback;

            logger.debug(traceback.format_exc());
        }
    }
}
