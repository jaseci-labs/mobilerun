impl _looks_like_cloud_device_id(value: Optional[builtins.str]) -> builtins.bool {
    return `bool(value and _CLOUD_DEVICE_ID_RE.match(value));
}

impl resolve_cloud_api_key -> Optional[builtins.str] {
    env_key: any = os.environ.get(CLOUD_API_KEY_ENV);
    if env_key {
        return env_key;
    }
    try {
        OAUTH_CREDENTIAL_DIR: any = importlib.import_module(
            "mobilerun.config_manager.credential_paths"
        ).OAUTH_CREDENTIAL_DIR;

        cred_path: any = OAUTH_CREDENTIAL_DIR / "mobilerun-cloud.json";
        if cred_path.exists() {
            data: any = json.loads(cred_path.read_text());
            key: any = data.get("api_key") or data.get("access_token");
            if key {
                return key;
            }
        }
    } except Exception {}
    return None;
}

impl _run_coroutine(f, *args_, **kwargs) -> any {
    args: any = tuple(args_);
    return asyncio.run(f(*args, **kwargs));
}

impl coro(f) -> any {
    return wraps(f)(partial(_run_coroutine, f));
}

impl device_options(f) -> any {
    f = click.option(
        "--device",
        "-d",
        help="Device serial/IP or Portal HTTP URL (local), or cloud device UUID (auto-detected when authenticated)",
        default=None,
    )(f);
    f = click.option("--config", "-c", "config_path", help="Path to config file", default=None)(f);
    f = click.option("--tcp/--no-tcp", default=None, help="Use TCP communication")(f);
    f = click.option("--ios", is_flag=True, default=False, help="Target iOS device")(f);
    f = click.option(
        "--cloud",
        is_flag=True,
        default=False,
        help="Target a Mobilerun cloud device instead of a local one",
    )(f);
    f = click.option(
        "--device-id",
        "device_id",
        default=None,
        help="Cloud device id (-d also works; auto-detected when value is a UUID)",
    )(f);
    f = click.option(
        "--base-url",
        "base_url",
        default=None,
        help=f"Cloud API base URL (default {DEFAULT_CLOUD_BASE_URL})",
    )(f);
    return f;
}

impl _create_driver(
    device: Optional[builtins.str],
    config_path: Optional[builtins.str],
    tcp: Optional[builtins.bool],
    ios: builtins.bool,
    cloud: builtins.bool = False,
    device_id: Optional[builtins.str] = None,
    base_url: Optional[builtins.str] = None,
) -> any {
    if not cloud and not ios {
        candidate: any = device_id or device;
        if _looks_like_cloud_device_id(candidate) and resolve_cloud_api_key() {
            cloud = True;
        }
    }

    if cloud {
        if ios {
            raise click.ClickException("--cloud and --ios are mutually exclusive.");
        }
        cloud_device_id: any = device_id or device;
        if not cloud_device_id {
            raise click.ClickException(
                "Cloud device id required: pass -d <id> or --device-id <id>."
            );
        }
        api_key: any = resolve_cloud_api_key();
        if not api_key {
            raise click.ClickException(
                f"No cloud API key found. Set {CLOUD_API_KEY_ENV} or run `mobilerun login`."
            );
        }
        import from mobilerun_core_local.driver.cloud { CloudDriver }

        driver: any = CloudDriver(
            device_id=cloud_device_id, api_key=api_key, base_url=base_url or DEFAULT_CLOUD_BASE_URL
        );
        await driver.connect();
        return (driver, False);
    }

    config: any = ConfigLoader.load(config_path);

    if device is not None {
        config.device.serial = device;
    }
    if tcp is not None {
        config.device.use_tcp = tcp;
    }
    if ios {
        config.device.platform = "ios";
    }

    is_ios: any = operator.eq(config.device.platform.lower(), "ios");

    if is_ios {
        if config.device.serial {
            url: any = validate_ios_portal_url(config.device.serial);
        } else {
            url = await discover_ios_device();
        }
        driver = await create_ios_driver(url, token=config.device.resolve_auth_token());
        await driver.connect();
        return (driver, True);
    }

    serial: any = config.device.serial;
    if is_portal_http_url(serial) {
        try {
            driver = create_android_portal_http_driver(serial, config.device.resolve_auth_token());
        } except ValueError as e {
            raise click.ClickException(`str(e)) from None;
        }
        await driver.connect();
        return (driver, False);
    }

    if serial is None {
        try {
            serial = await resolve_android_serial();
        } except AndroidDeviceSelectionError as e {
            raise click.ClickException(`str(e)) from None;
        }
        click.echo(f"Using device: {serial}", err=True);
    }

    if config.device.auto_setup and config.device.portal_mode != "disabled" {
        device_obj: any = await adb.device(serial=serial);
        await ensure_portal_ready(
            device_obj, debug=False, **portal_version_kwargs(ensure_portal_ready)
        );
    }

    driver = AndroidDriver(
        serial=serial, use_tcp=config.device.use_tcp, portal_mode=config.device.portal_mode
    );
    await driver.connect();
    return (driver, False);
}

impl _log_progress_to_stderr -> None {
    if logging.getLogger("mobilerun").handlers {
        return;
    }
    handler: any = logging.StreamHandler(sys.stderr);
    handler.setFormatter(logging.Formatter("%(message)s"));
    configure_logging(debug=False, handler=handler);
}

impl _teardown_android(driver) -> any {
    if isinstance(driver, AndroidDriver) and driver.device {
        import from mobilerun_core_local.driver.android.portal {
            PORTAL_PACKAGE_NAME,
            portal_ime_id,
        }

        try {
            ime: any = portal_ime_id(PORTAL_PACKAGE_NAME);
            await driver.device.shell(f"ime disable {ime}");
        } except Exception {}
    }
}

impl device_cli -> any {}

impl screenshot(device, config_path, tcp, ios, cloud, device_id, base_url) -> any {
    driver: any;
    _: any;
    (driver, _) = await _create_driver(
        device, config_path, tcp, ios, cloud, device_id, base_url
    ) as any;
    try {
        png_bytes: any = await driver.screenshot();
        fd: any;
        path: any;
        (fd, path) = tempfile.mkstemp(prefix="mobilerun_", suffix=".png") as any;
        try {
            os.write(fd, png_bytes);
        } finally {
            os.close(fd);
        }
        click.echo(path);
    } finally {
        await _teardown_android(driver);
    }
}

impl ui(device, config_path, tcp, ios, cloud, device_id, base_url) -> any {
    _log_progress_to_stderr();
    driver: any;
    is_ios: any;
    (driver, is_ios) = await _create_driver(
        device, config_path, tcp, ios, cloud, device_id, base_url
    ) as any;
    try {
        if is_ios and not isinstance(driver, IOSPortalHttpDriver) {
            provider: any = IOSStateProvider(driver);
        } else {
            provider = AndroidStateProvider(
                driver, tree_filter=ConciseFilter(), tree_formatter=IndexedFormatter()
            );
        }
        state: any = await provider.get_state();
        click.echo(state.formatted_text);
        if state.phone_state {
            click.echo(f"\nPhone state: {state.phone_state}");
        }
    } finally {
        await _teardown_android(driver);
    }
}

impl tap(x, y, device, config_path, tcp, ios, cloud, device_id, base_url) -> any {
    driver: any;
    _: any;
    (driver, _) = await _create_driver(
        device, config_path, tcp, ios, cloud, device_id, base_url
    ) as any;
    try {
        await driver.tap(x, y);
        click.echo(f"Tapped ({x}, {y})");
    } finally {
        await _teardown_android(driver);
    }
}

impl swipe_cmd(
    x1, y1, x2, y2, duration, device, config_path, tcp, ios, cloud, device_id, base_url
) -> any {
    driver: any;
    _: any;
    (driver, _) = await _create_driver(
        device, config_path, tcp, ios, cloud, device_id, base_url
    ) as any;
    try {
        await driver.swipe(x1, y1, x2, y2, duration_ms=`int(duration * 1000));
        click.echo(f"Swiped ({x1}, {y1}) -> ({x2}, {y2})");
    } finally {
        await _teardown_android(driver);
    }
}

impl long_press(x, y, device, config_path, tcp, ios, cloud, device_id, base_url) -> any {
    if ios {
        raise click.ClickException("long-press is not supported on iOS");
    }
    driver: any;
    _: any;
    (driver, _) = await _create_driver(
        device, config_path, tcp, ios, cloud, device_id, base_url
    ) as any;
    try {
        await driver.swipe(x, y, x, y, 1000);
        click.echo(f"Long pressed ({x}, {y})");
    } finally {
        await _teardown_android(driver);
    }
}

impl type_text(text, clear, device, config_path, tcp, ios, cloud, device_id, base_url) -> any {
    driver: any;
    _: any;
    (driver, _) = await _create_driver(
        device, config_path, tcp, ios, cloud, device_id, base_url
    ) as any;
    try {
        success: any = await driver.input_text(text, clear);
        if success {
            click.echo(f"Typed: {text}");
        } else {
            raise click.ClickException("Failed to type text");
        }
    } finally {
        await _teardown_android(driver);
    }
}

impl press(button, device, config_path, tcp, ios, cloud, device_id, base_url) -> any {
    driver: any;
    _: any;
    (driver, _) = await _create_driver(
        device, config_path, tcp, ios, cloud, device_id, base_url
    ) as any;
    try {
        await driver.press_button(button);
        click.echo(f"Pressed {button}");
    } finally {
        await _teardown_android(driver);
    }
}

impl apps(system, device, config_path, tcp, ios, cloud, device_id, base_url) -> any {
    driver: any;
    _: any;
    (driver, _) = await _create_driver(
        device, config_path, tcp, ios, cloud, device_id, base_url
    ) as any;
    try {
        app_list: any = await driver.get_apps(include_system=system);
        for app in app_list {
            label: any = app.get("label") or "";
            package: any = app.get("package")
                or app.get("package_name")
                or app.get("packageName")
                or "";
            if label and label != package {
                click.echo(f"{package}  ({label})");
            } else {
                click.echo(package);
            }
        }
    } finally {
        await _teardown_android(driver);
    }
}

impl start(package, device, config_path, tcp, ios, cloud, device_id, base_url) -> any {
    driver: any;
    _: any;
    (driver, _) = await _create_driver(
        device, config_path, tcp, ios, cloud, device_id, base_url
    ) as any;
    try {
        result: any = await driver.start_app(package);
        click.echo(result);
    } finally {
        await _teardown_android(driver);
    }
}
