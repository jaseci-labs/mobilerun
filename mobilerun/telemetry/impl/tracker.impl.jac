impl _get_posthog -> Posthog {
    if _posthog is None {
        with _posthog_lock {
            if _posthog is None {
                _posthog = Posthog(project_api_key=PROJECT_API_KEY, host=HOST, disable_geoip=False);
            }
        }
    }
    return _posthog;
}

impl is_telemetry_enabled(*, config_enabled: builtins.bool = True) -> builtins.bool {
    telemetry_enabled: any = os.environ.get("MOBILERUN_TELEMETRY_ENABLED");
    if telemetry_enabled is None {
        telemetry_enabled = os.environ.get("DROIDRUN_TELEMETRY_ENABLED") or "true";
    }
    enabled: any = config_enabled and telemetry_enabled.lower() in ["true", "1", "yes", "y"];
    logger.debug(f"Telemetry enabled: {enabled}");
    return enabled;
}

impl print_telemetry_message(*, config_enabled: builtins.bool = True) -> None {
    if is_telemetry_enabled(config_enabled=config_enabled) {
        mobilerun_logger.debug(TELEMETRY_ENABLED_MESSAGE);
    } else {
        mobilerun_logger.debug(TELEMETRY_DISABLED_MESSAGE);
    }
}

impl _is_valid_uuid(value: builtins.str) -> builtins.bool {
    try {
        UUID(value);
        return True;
    } except (ValueError, AttributeError) {
        return False;
    }
}

impl get_user_id -> builtins.str {
    try {
        USER_ID_PATH.parent.mkdir(parents=True, exist_ok=True);
        if USER_ID_PATH.exists() {
            user_id: any = USER_ID_PATH.read_text().strip();
            if user_id and _is_valid_uuid(user_id) {
                logger.debug(f"User ID: {user_id}");
                return user_id;
            }
            logger.debug(f"Invalid user ID found in {USER_ID_PATH}, regenerating");
        }
        user_id = `str(uuid4());
        USER_ID_PATH.write_text(user_id);
        logger.debug(f"Generated new user ID: {user_id}");
        return user_id;
    } except Exception as e {
        logger.error(f"Error getting user ID: {e}");
        return "unknown";
    }
}

impl capture(
    event: TelemetryEvent,
    user_id: builtins.str | None = None,
    *,
    config_enabled: builtins.bool = True,
) -> None {
    if not is_telemetry_enabled(config_enabled=config_enabled) {
        logger.debug(f"Telemetry disabled, skipping capture of {event}");
        return;
    }

    try {
        event_name: any = `type(event).__name__;
        event_data: any = event.model_dump();
        properties: any = {"run_id": RUN_ID, **event_data};

        _get_posthog().capture(
            event_name, distinct_id=user_id or get_user_id(), properties=properties
        );
        logger.debug(f"Captured event: {event_name} with properties: {event}");
    } except Exception as e {
        logger.error(f"Error capturing event: {e}");
    }
}

impl flush(*, config_enabled: builtins.bool = True) -> None {
    try {
        if not is_telemetry_enabled(config_enabled=config_enabled) or _posthog is None {
            return;
        }

        await asyncio.wait_for(asyncio.to_thread(_posthog.flush), timeout=10);
    } except asyncio.TimeoutError {
        logger.warning("PostHog flush timed out after 10 seconds");
    } except Exception as e {
        logger.error(f"Error flushing data: {e}");
    }
}
