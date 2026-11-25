impl AndroidDeviceSelectionError.__repr__ -> str {
    return (getattr(builtins.super(AndroidDeviceSelectionError, self), "__repr__") as any)();
}

impl AndroidDeviceSelectionError.__eq__(other: any) -> bool {
    return self is other;
}

impl AndroidDeviceSelectionError.__hash__ -> int {
    return id(self);
}

impl is_portal_http_url(device: builtins.str | None) -> builtins.bool {
    return `bool(device) and device.lower().startswith(("http://", "https://"));
}

impl create_android_portal_http_driver(
    url: builtins.str, token: builtins.str | None
) -> AndroidPortalHttpDriver {
    if not token {
        raise ValueError(
            "Android Portal HTTP needs the Portal auth token. Copy it from the Portal app and set MOBILERUN_DEVICE_TOKEN or device.auth_token.",
        );
    }
    return AndroidPortalHttpDriver(url, token);
}

impl resolve_android_serial(serial: builtins.str | None = None) -> builtins.str {
    if serial {
        return serial;
    }

    env_serial: any = os.environ.get("ANDROID_SERIAL", "").strip();
    if env_serial {
        return env_serial;
    }

    devices: any = await adb.list();
    online: any = [d.serial for d in devices if d.state == "device"];
    if len(online) == 1 {
        return online[0];
    }

    if not online {
        message: any = "No connected Android devices found.";
        not_ready: any = [f"{d.serial} ({d.state})" for d in devices];
        if not_ready {
            message += " Not ready: " + format(", ".join(not_ready), "") + ".";
        }
        raise AndroidDeviceSelectionError(message);
    }

    raise AndroidDeviceSelectionError(
        "Multiple Android devices connected: "
            + format(", ".join(online), "")
            + ". Pass -d/--device or set ANDROID_SERIAL.",
    );
}
