impl setup_tracing(tracing_config: TracingConfig, agent: Optional[builtins.object] = None) -> None {
    if not tracing_config.enabled {
        return;
    }

    provider: any = tracing_config.provider.lower();

    with _tracing_setup_lock {
        _legacy_session_context = (
            tracing_config.langfuse_session_id or _default_session_id,
            tracing_config.langfuse_user_id or "anonymous",
        );
        if _tracing_initialized {
            logger.debug(f"🔍 Tracing already initialized with {_tracing_provider}, skipping setup");
            if provider == "langfuse" and agent {
                set_current_agent: any = importlib.import_module(
                    "mobilerun.telemetry.langfuse_processor"
                ).set_current_agent;

                set_current_agent(agent);
            }
            return;
        }

        if provider == "phoenix" {
            if _setup_phoenix_tracing() {
                _tracing_initialized = True;
                _tracing_provider = "phoenix";
            }
        } elif provider == "langfuse" {
            if _setup_langfuse_tracing(tracing_config, agent) {
                _tracing_initialized = True;
                _tracing_provider = "langfuse";
                logger.debug("🔍 Langfuse tracing enabled");
            }
        } else {
            logger.warning(
                f"⚠️  Unknown tracing provider: {provider}. Supported providers: phoenix, langfuse"
            );
        }
    }
}

impl _check_phoenix_reachable(
    endpoint: builtins.str, timeout: builtins.float = 3.0
) -> builtins.bool {
    import urllib.error;
    import urllib.request;

    try {
        req: any = urllib.request.Request(endpoint, method="GET");
        urllib.request.urlopen(req, timeout=timeout);
        return True;
    } except (OSError, ValueError) {
        return False;
    }
}

impl _setup_phoenix_tracing -> builtins.bool {
    endpoint: any = os.getenv("PHOENIX_URL", "http://0.0.0.0:6006");
    try {
        arize_phoenix_callback_handler: any = importlib.import_module(
            "mobilerun.telemetry.phoenix"
        ).arize_phoenix_callback_handler;

        if not _check_phoenix_reachable(endpoint) {
            logger.warning(
                f"⚠️  Phoenix server is not reachable at {endpoint}. Tracing will be disabled for this session.",
            );
            return False;
        }

        handler: any = arize_phoenix_callback_handler();
    } except ImportError {
        logger.warning(
            "⚠️  Phoenix tracing dependencies are missing.\n    Reinstall Mobilerun to restore them:\n    • If installed via tool: `uv tool install --reinstall mobilerun`\n    • If installed via pip: `uv pip install --reinstall mobilerun`\n",
        );
        return False;
    }

    llama_index.core.global_handler = handler;
    logger.debug("🔍 Arize Phoenix tracing enabled globally");
    return True;
}

impl _setup_langfuse_tracing(
    tracing_config: TracingConfig, agent: Optional[builtins.object] = None
) -> builtins.bool {
    original_encoder: any;

    try {
        import from langfuse { Langfuse }

        public_key: any = tracing_config.langfuse_public_key or os.getenv("LANGFUSE_PUBLIC_KEY");
        secret_key: any = tracing_config.langfuse_secret_key or os.getenv("LANGFUSE_SECRET_KEY");
        base_url: any = _resolve_langfuse_base_url(tracing_config);

        if not public_key or not secret_key {
            logger.error(
                "Langfuse credentials are missing. Configure both the public and secret key."
            );
            return False;
        }

        if _langfuse_setup_attempted {
            logger.error(
                "Langfuse tracing initialization already failed in this process; restart before retrying.",
            );
            return False;
        }
        import from opentelemetry { trace }
        import from opentelemetry.sdk.trace { TracerProvider }
        existing_provider: any = trace.get_tracer_provider();
        if hasattr(existing_provider, "add_span_processor") {
            tracer_provider: any = existing_provider;
            logger.debug("🔍 Using existing TracerProvider");
        } else {
            tracer_provider = TracerProvider();
            trace.set_tracer_provider(tracer_provider);
            logger.debug("🔍 Created new TracerProvider");
        }

        if _provider_has_langfuse_processor(tracer_provider) {
            logger.error(
                "Langfuse tracing is already registered on the active tracer provider; Mobilerun cannot guarantee preprocessing or export policy.",
            );
            return False;
        }
        import from openinference.instrumentation.llama_index { LlamaIndexInstrumentor }

        instrumentor: any = LlamaIndexInstrumentor();
        if not instrumentor.is_instrumented_by_opentelemetry {
            instrumentor.instrument();
            logger.debug("🔍 Instrumented LlamaIndex");
        } else {
            logger.debug("🔍 LlamaIndex already instrumented");
        }
        import from openinference.instrumentation.llama_index { _handler }
        import from pydantic { BaseModel as PydanticV2BaseModel }

        if not getattr(_handler._encoder, "_mobilerun_pydantic_v2", False) {
            original_encoder = _handler._encoder;

            """Encode Pydantic v2 models for OpenInference."""
            def _fixed_encoder(`obj) -> any {
                if isinstance(`obj, PydanticV2BaseModel) {
                    return `obj.model_dump();
                }
                return original_encoder(`obj);
            }

            setattr(_fixed_encoder as any, "_mobilerun_pydantic_v2", True);
            _handler._encoder = _fixed_encoder;
        }
        LangfuseSpanProcessor: any = importlib.import_module(
            "mobilerun.telemetry.langfuse_processor"
        ).LangfuseSpanProcessor;
        _LangfuseTracerProvider: any = importlib.import_module(
            "mobilerun.telemetry.langfuse_processor"
        )._LangfuseTracerProvider;
        set_current_agent: any = importlib.import_module(
            "mobilerun.telemetry.langfuse_processor"
        ).set_current_agent;

        if agent {
            set_current_agent(agent);
        }

        if _langfuse_preprocessor is None or _langfuse_tracer_provider is not tracer_provider {
            _langfuse_preprocessor = LangfuseSpanProcessor();
            _langfuse_tracer_provider = tracer_provider;
        }
        _langfuse_setup_attempted = True;
        client: any = Langfuse(
            public_key=public_key,
            secret_key=secret_key,
            base_url=base_url,
            tracer_provider=_LangfuseTracerProvider(tracer_provider, _langfuse_preprocessor),
            should_export_span=_export_all_spans,
        );

        if not _provider_has_owned_langfuse_pipeline(tracer_provider) {
            logger.error(
                "Langfuse is already initialized on another tracer provider; Mobilerun cannot guarantee preprocessing or export policy.",
            );
            return False;
        }

        _langfuse_client = client;

        try {
            if not _langfuse_client.auth_check() {
                logger.error("Langfuse authentication failed. Please check your credentials.");
            }
        } except Exception as error {
            logger.error("Unable to verify Langfuse authentication; tracing remains configured.");
            logger.debug("Langfuse authentication diagnostic failed (%s)", `type(error).__name__);
        }

        return True;
    } except ImportError as e {
        logger.warning(
            "⚠️  Langfuse dependencies are not installed.\n    To enable Langfuse integration, install with:\n    • If installed via tool: `uv tool install mobilerun[langfuse]`\n    • If installed via pip: `uv pip install mobilerun[langfuse]`\n    Missing: "
                + format(cast(Any, e).name if hasattr(e, "name") else `str(e), "")
                + "\n",
        );
        return False;
    } except Exception as error {
        logger.error("Failed to initialize Langfuse tracing (%s)", `type(error).__name__);
        return False;
    }
}

impl _resolve_langfuse_base_url(tracing_config: TracingConfig) -> builtins.str {
    return tracing_config.langfuse_host
        or os.getenv("LANGFUSE_BASE_URL")
        or os.getenv("LANGFUSE_HOST")
        or DEFAULT_LANGFUSE_BASE_URL;
}

impl _export_all_spans(_span) -> builtins.bool {
    return True;
}

impl _provider_has_langfuse_processor(tracer_provider: builtins.object) -> builtins.bool {
    _LangfuseSpanProcessor: any;
    _LangfuseSpanProcessor = importlib.import_module(
        "mobilerun.telemetry.langfuse_processor"
    )._LangfuseSpanProcessor;

    return `any(
        isinstance(processor, _LangfuseSpanProcessor)
            or `type(processor).__module__.startswith("langfuse.")
        for processor in _provider_span_processors(tracer_provider),
    );
}

impl _provider_has_owned_langfuse_pipeline(tracer_provider: builtins.object) -> builtins.bool {
    _LangfuseSpanProcessor: any = importlib.import_module(
        "mobilerun.telemetry.langfuse_processor"
    )._LangfuseSpanProcessor;

    processors: any = [
        processor
        for processor in _provider_span_processors(tracer_provider)
        if isinstance(processor, _LangfuseSpanProcessor)
            or `type(processor).__module__.startswith("langfuse.")
    ];
    return operator.eq(len(processors), 1)
        and isinstance(processors[0], _LangfuseSpanProcessor)
        and processors[0].normalizer is _langfuse_preprocessor
        and `type(processors[0].processor).__module__.startswith("langfuse.");
}

impl _provider_span_processors(tracer_provider: builtins.object) -> any {
    active_processor: any = getattr(tracer_provider, "_active_span_processor", None);
    processors: any = getattr(active_processor, "_span_processors", None);
    if processors is None {
        processors = getattr(tracer_provider, "processors", ());
    }
    return `tuple(processors);
}

impl _attach_session_context(
    session_id: Optional[builtins.str], user_id: Optional[builtins.str]
) -> Token {
    import from openinference.semconv.trace { SpanAttributes }
    import from opentelemetry.context { attach, get_current, set_value }

    ctx: any = get_current();
    ctx = set_value(SpanAttributes.SESSION_ID, session_id or _default_session_id, ctx);
    ctx = set_value(SpanAttributes.USER_ID, user_id or "anonymous", ctx);
    return attach(ctx);
}

impl apply_session_context -> None {
    if not _tracing_initialized or _tracing_provider != "langfuse" {
        return;
    }
    _attach_session_context(*_legacy_session_context);
}

impl session_context(
    session_id: Optional[builtins.str] = None,
    user_id: Optional[builtins.str] = None,
    agent: Optional[builtins.object] = None,
) -> Generator[any, any, any] {
    if not _tracing_initialized or _tracing_provider != "langfuse" {
        yield;
        return;
    }

    import from opentelemetry.context { detach }

    _current_agent: any = importlib.import_module(
        "mobilerun.telemetry.langfuse_processor"
    )._current_agent;

    token: any = _attach_session_context(session_id, user_id);
    agent_token: any = _current_agent.set(agent) if agent is not None else None;
    try {
        yield;
    } finally {
        if agent_token is not None {
            _current_agent.reset(agent_token);
        }
        detach(token);
    }
}

impl record_langfuse_screenshot(
    screenshot: builtins.bytes,
    mime_type: builtins.str = "image/png",
    parent_span=None,
    screenshots_enabled: builtins.bool = False,
    vision_enabled: builtins.bool = False,
) -> None {
    if not _tracing_initialized
        or _tracing_provider != "langfuse"
        or not screenshot
        or not screenshots_enabled
        or vision_enabled
    {
        return;
    }

    try {
        import from opentelemetry { trace }

        get_last_step_span_context: any = importlib.import_module(
            "mobilerun.telemetry.langfuse_processor"
        ).get_last_step_span_context;
        get_root_span_context: any = importlib.import_module(
            "mobilerun.telemetry.langfuse_processor"
        ).get_root_span_context;

        tracer: any = trace.get_tracer("droidrun.screenshot");
        image_b64: any = base64.b64encode(screenshot).decode();
        candidate: any = parent_span
            if parent_span and parent_span.get_span_context().is_valid
            else None;
        if candidate is None {
            current_span: any = trace.get_current_span();
            if current_span and current_span.get_span_context().is_valid {
                candidate = current_span;
            }
        }

        parent_ctx: any = trace.set_span_in_context(candidate)
            if candidate is not None
            else get_last_step_span_context() or get_root_span_context();

        if parent_ctx is None {
            return;
        }

        span: any = tracer.start_span("droidrun.screenshot", context=parent_ctx);
        try {
            span.set_attribute("droidrun.screenshot.image_base64", image_b64);
            span.set_attribute("droidrun.screenshot.mime_type", mime_type);
        } finally {
            span.end();
        }
    } except Exception as e {
        logger.debug(f"Failed to record Langfuse screenshot span: {e}");
    }
}
