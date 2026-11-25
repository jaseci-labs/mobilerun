import builtins;

import operator;

import importlib;

import functools;

import asyncio;

import logging;

import os;

import time;

import traceback;

import from typing { Any, Awaitable, Type, Union }

import from async_adbutils { adb }

import from llama_index.core.llms.llm { LLM }

import from llama_index.core.workflow { Context, StartEvent, StopEvent, Workflow, step }

import from mobilerun_core_local.driver.android { AndroidDriver }

import from mobilerun_core_local.driver.android.portal { ensure_portal_ready }

import from mobilerun_core_local.driver.base { DeviceDisconnectedError }

import from mobilerun_core_local.driver.ios {
    IOSPortalHttpDriver,
    create_ios_driver,
    discover_ios_device,
}

import from mobilerun_core_local.driver.recording { RecordingDriver }

import from mobilerun_core_local.driver.stealth { StealthDriver }

import from mobilerun_core_local.driver.visual_remote {
    VISUAL_REMOTE_CONNECTION,
    VISUAL_REMOTE_DEFAULT_URL,
    VisualRemoteDriver,
}

import from opentelemetry { trace }

import from pydantic { BaseModel }

import from workflows.events { Event }

import from workflows.handler { WorkflowHandler }

glob logger: any = logging.getLogger("mobilerun");

glob _COORDINATE_TOOL_NAMES: any = {"click_at", "click_area", "long_press_at"};

glob _FINALIZE_BUDGET_SECONDS: any = 60.0;

glob _FINALIZE_SCHEDULING_RESERVE_SECONDS: any = 1.0;

glob _FINALIZE_OBSERVATION_SECONDS: any = 15.0;

glob _FINALIZE_TELEMETRY_SECONDS: any = 10.0;

glob _FINALIZE_TRAJECTORY_SECONDS: any = 30.0;

glob _FINALIZE_MCP_SECONDS: any = 3.0;

glob _FINALIZE_CLEANUP_MAX_FRACTION: any = 0.5;

glob _WORKFLOW_DEADLINE_KEY: any = "mobile_agent_workflow_deadline";

glob _ABANDONED_FINALIZE_TASKS: builtins.set[asyncio.Task[Any]] = set[any]();

glob DroidAgent: any;

def _reap_abandoned_finalize_task(task: asyncio.Task[Any]) -> None {
    _ABANDONED_FINALIZE_TASKS.discard(task);
    try {
        task.result();
    } except (asyncio.CancelledError, Exception) {}
}

async def _capped_finalize_stage(
    name: builtins.str, awaitable: Awaitable[Any], cap: builtins.float
) -> Any {
    try {
        async with asyncio.timeout(cap) {
            return await awaitable;
        }
    } except TimeoutError {
        logger.warning("Final %s background cleanup timed out", name);
        raise;
    }
}

async def _run_finalize_stage(
    name: builtins.str,
    awaitable: Awaitable[Any],
    deadline: builtins.float,
    cap: builtins.float,
    *,
    continue_in_background: builtins.bool = False,
) -> builtins.tuple[builtins.bool, Any] {
    operation: any = _capped_finalize_stage(name, awaitable, cap)
        if continue_in_background
        else awaitable;
    task: any = asyncio.create_task(operation, name=f"mobile-agent-finalize-{name}");
    try {
        remaining: any = min(cap, deadline - time.monotonic());
        if remaining <= 0 {
            logger.debug("Skipping final %s: epilog budget exhausted", name);
            return (False, None);
        }
        (done, _) = await asyncio.wait({task}, timeout=remaining) as any;
        if not done {
            logger.warning("Final %s timed out", name);
            return (False, None);
        }
        try {
            return (True, task.result());
        } except asyncio.CancelledError {
            logger.warning("Final %s was cancelled", name);
            return (False, None);
        } except Exception as exc {
            logger.warning("Final %s failed: %s", name, exc);
            return (False, None);
        }
    } finally {
        if not task.done() {
            if not continue_in_background {
                task.cancel();
            }
            _ABANDONED_FINALIZE_TASKS.add(task);
            task.add_done_callback(_reap_abandoned_finalize_task);
        }
    }
}

async def _extract_structured_output(
    structured_agent: StructuredOutputAgent, ctx: Context
) -> StopEvent {
    return await structured_agent.extract_structured_output(ctx, StartEvent());
}

def _structured_output_extraction(
    structured_agent: StructuredOutputAgent, ctx: Context
) -> Awaitable[StopEvent] {
    extract: any = clean_span("StructuredOutputAgent.extract_structured_output")(
        functools.partial(_extract_structured_output, structured_agent, ctx)
    );
    return clean_span("StructuredOutputAgent.run")(extract)();
}

def _normalize_control_backend(control_backend: builtins.str | None) -> builtins.str | None {
    if control_backend is None {
        return None;
    }
    normalized: any = control_backend.strip().lower();
    return normalized or None;
}

def _force_screenshot_only_vision(agent_config: AgentConfig) -> None {
    agent_config.vision_only = True;
    agent_config.manager.vision = True;
    agent_config.executor.vision = True;
    agent_config.fast_agent.vision = True;
}

def _effective_disabled_tools(
    disabled_tools: builtins.list[builtins.str],
    state_provider,
    vision_enabled: builtins.bool = False,
    explicit: builtins.bool = False,
) -> builtins.list[builtins.str] {
    requires_coords: any = getattr(state_provider, "requires_coordinate_tools", False);
    if requires_coords {
        if explicit {
            disabled_set: any = `set(disabled_tools);
            blocked: any = sorted(disabled_set & _COORDINATE_TOOL_NAMES);
            if blocked {
                if `set(DEFAULT_DISABLED_TOOLS) < disabled_set {
                    logger.warning(
                        "Legacy disabled_tools list %s contains coordinate tools that the active state provider requires; stripping them to allow startup. Consider setting tools.disabled_tools to null (framework default) and listing only the extras you actually want disabled.",
                        disabled_tools,
                    );
                } else {
                    raise ValueError(
                        f"Cannot disable coordinate tools {blocked} when the state provider requires them (vision_only=True or visual remote control_backend). Remove these from tools.disabled_tools.",
                    );
                }
            }
        }
        return [name for name in disabled_tools if name not in _COORDINATE_TOOL_NAMES];
    }
    coords_align: any = getattr(state_provider, "screenshot_matches_input_coords", False);
    if vision_enabled and not explicit and coords_align {
        return [name for name in disabled_tools if name != "click_at"];
    }
    return disabled_tools;
}

"""
    A wrapper class that coordinates between agents to achieve a user's goal.

    Reasoning modes:
    - reasoning=False: Uses FastAgent directly for immediate execution
    - reasoning=True: Uses ManagerAgent (planning) + ExecutorAgent (actions)
    """
class MobileAgent(Workflow) {
    has _tracing_session_id: builtins.str | None = None;

    has _tracing_user_id: builtins.str | None = None;

    static def _configure_default_logging(debug: builtins.bool = False) -> any {
        has_real_handler: any = `any(
            not isinstance(h, logging.NullHandler) for h in logger.handlers
        );
        if not has_real_handler {
            handler: any = CLILogHandler();
            handler.setFormatter(
                logging.Formatter("%(asctime)s %(levelname)s: %(message)s", "%H:%M:%S")
                    if debug
                    else logging.Formatter("%(message)s"),
            );
            configure_logging(debug=debug, handler=handler);
        } elif debug {
            logger.setLevel(logging.DEBUG);
        }
    }

    def init(
        goal: builtins.str,
        config: MobileConfig | None = None,
        llms: builtins.dict[builtins.str, LLM] | LLM | None = None,
        custom_tools: builtins.dict = None,
        credentials: Union[builtins.dict, "CredentialManager", None] = None,
        variables: builtins.dict | None = None,
        output_model: Type[BaseModel] | None = None,
        prompts: builtins.dict[builtins.str, builtins.str] | None = None,
        driver: "DeviceDriver | None" = None,
        state_provider: "StateProvider | None" = None,
        timeout: builtins.int = 1000,
        *args_,
        **kwargs,
    ) {
        args: any = tuple(args_);
        self._configure_default_logging(debug=`bool(config and config.logging.debug));
        self.user_id = kwargs.pop("user_id", None);
        self.runtype = kwargs.pop("runtype", "developer");
        self.shared_state = MobileAgentState(
            instruction=goal, err_to_manager_thresh=2, user_id=self.user_id, runtype=self.runtype
        );
        self.output_model = output_model;
        self.prompt_resolver = PromptResolver(custom_prompts=prompts);
        if variables {
            self.shared_state.custom_variables = variables;
        }
        credentials_source: any = credentials
            if credentials is not None
            else config.credentials if config else None;

        if isinstance(credentials_source, CredentialManager) {
            self.credential_manager = credentials_source;
        } elif credentials_source is not None {
            cm: any = FileCredentialManager(credentials_source);
            self.credential_manager = cm if cm.secrets else None;
        } else {
            self.credential_manager = None;
        }

        self.resolved_device_config = config.device if config else DeviceConfig();

        self.config = MobileConfig(
            agent=config.agent if config else AgentConfig(),
            device=self.resolved_device_config,
            tools=config.tools if config else ToolsConfig(),
            logging=config.logging if config else LoggingConfig(),
            tracing=config.tracing if config else TracingConfig(),
            telemetry=config.telemetry if config else TelemetryConfig(),
            llm_profiles=config.llm_profiles if config else {},
            credentials=config.credentials if config else CredentialsConfig(),
            external_agents=config.external_agents if config else {},
            mcp=config.mcp if config else MCPConfig(),
        );
        self.shared_state.telemetry_config_enabled = self.config.telemetry.enabled;
        control_backend: any = _normalize_control_backend(
            self.resolved_device_config.control_backend
        );
        if self.config.agent.vision_only
            or control_backend == VISUAL_REMOTE_CONNECTION
            or getattr(state_provider, "requires_coordinate_tools", False)
        {
            _force_screenshot_only_vision(self.config.agent);
        }
        self._injected_driver = driver;
        self._injected_state_provider = state_provider;
        self.driver = None;
        self.android_serial = None;
        self.registry = None;
        self.action_ctx = None;
        self.state_provider = None;

        getattr(Workflow, "__init__")(self, *args, timeout=timeout, **kwargs);

        self._tracing_session_id = self.config.tracing.langfuse_session_id;
        self._tracing_user_id = self.config.tracing.langfuse_user_id;
        setup_tracing(self.config.tracing, agent=self);
        _BUILTIN_AGENT_NAMES: any = {"mobilerun", "droidrun"};
        self._using_external_agent = self.config.agent.name not in _BUILTIN_AGENT_NAMES;

        self._stream_screenshots = (
            os.environ.get("MOBILERUN_STREAM_SCREENSHOTS")
            or os.environ.get("DROIDRUN_STREAM_SCREENSHOTS")
            or ""
        ).lower()
            in ("1", "true");

        self.timeout = timeout;
        self.user_custom_tools = custom_tools or {};
        self.mcp_manager = None;
        if not self._using_external_agent {
            if llms is None {
                if config is None {
                    raise ValueError(
                        "Either 'llms' or 'config' must be provided. If llms is not provided, config is required to load LLMs from profiles.",
                    );
                }

                logger.debug("🔄 Loading LLMs from config (llms not provided)...");

                llms = load_agent_llms(config=self.config, output_model=output_model, **kwargs);
            }
            if isinstance(llms, `dict) {
                llms = merge_llms_with_config(
                    self.config, llms, output_model=output_model, **kwargs
                );
            } elif isinstance(llms, LLM) {} else {
                raise ValueError(f"Invalid LLM type: {`type(llms)}");
            }

            if isinstance(llms, `dict) {
                self.manager_llm = llms.get("manager");
                self.executor_llm = llms.get("executor");
                self.fast_agent_llm = llms.get("fast_agent");
                self.app_opener_llm = llms.get("app_opener");
                self.structured_output_llm = llms.get("structured_output", self.fast_agent_llm);
            } else {
                self.manager_llm = llms;
                self.executor_llm = llms;
                self.fast_agent_llm = llms;
                self.app_opener_llm = llms;
                self.structured_output_llm = llms;
            }
        } else {
            logger.debug(f"🔄 Using external agent: {self.config.agent.name}");
            self.manager_llm = None;
            self.executor_llm = None;
            self.fast_agent_llm = None;
            self.app_opener_llm = None;
            self.structured_output_llm = None;
        }

        self.trajectory = None;
        self.trajectory_writer = None;
        self.macro_recorder = None;
        if self._using_external_agent {
            self.manager_agent = None;
            self.executor_agent = None;
        } elif self.config.agent.reasoning {
            if self.config.agent.manager.stateless {
                ManagerClass: any = StatelessManagerAgent;
            } else {
                ManagerClass = ManagerAgent;
            }
            self.manager_agent = ManagerClass(
                llm=self.manager_llm,
                action_ctx=None,
                state_provider=None,
                save_trajectory=self.config.logging.save_trajectory,
                shared_state=self.shared_state,
                agent_config=self.config.agent,
                registry=None,
                output_model=self.output_model,
                prompt_resolver=self.prompt_resolver,
                tracing_config=self.config.tracing,
                timeout=self.timeout,
            );
            self.executor_agent = ExecutorAgent(
                llm=self.executor_llm,
                registry=None,
                action_ctx=None,
                shared_state=self.shared_state,
                agent_config=self.config.agent,
                prompt_resolver=self.prompt_resolver,
                timeout=self.timeout,
            );
        } else {
            self.manager_agent = None;
            self.executor_agent = None;
        }
        self._init_prompts = prompts;
        self._init_timeout = timeout;

        logger.debug("✅ MobileAgent initialized successfully.");
    }

    def run(*args__, **kwargs) -> Awaitable[ResultEvent] | WorkflowHandler {
        args: any = tuple(args__);
        with session_context(self._tracing_session_id, self._tracing_user_id, agent=self) {
            return getattr(Workflow, "run")(self, *args, **kwargs);
        }
    }

    async def _initialize_workflow_deadline(ctx: Context) -> None {
        runtime_timeout: any = self._timeout;
        workflow_deadline: any = time.monotonic() + runtime_timeout
            if runtime_timeout is not None
            else None;
        (await ctx.store.set(_WORKFLOW_DEADLINE_KEY, workflow_deadline));
    }

    async def _initialize_run_trajectory -> None {
        if self._using_external_agent or self.config.logging.save_trajectory == "none" {
            self.trajectory = None;
            self.trajectory_writer = None;
            self.macro_recorder = None;
            return;
        }

        self.trajectory = Trajectory(
            goal=self.shared_state.instruction, base_path=self.config.logging.trajectory_path
        );
        self.trajectory_writer = TrajectoryWriter(queue_size=300);
        self.macro_recorder = MacroRecorder();
        (await self.trajectory_writer.start());
    }

    @step
    async def start_handler(ctx: Context, ev: StartEvent) -> FastAgentExecuteEvent
        | ManagerInputEvent
        | FinalizeEvent {
        (await self._initialize_workflow_deadline(ctx));
        logger.info(f"🚀 Running MobileAgent to achieve goal: {self.shared_state.instruction}");
        ctx.write_event_to_stream(ev);
        (await self._initialize_run_trajectory());
        if self._using_external_agent {
            agent_name: any = self.config.agent.name;
            agent_module: any = load_agent(agent_name);
            if not agent_module {
                list_agents: any = importlib.import_module("mobilerun.agent.external").list_agents;

                available: any = list_agents();
                if available {
                    agents_str: any = ", ".join(available);
                    raise ValueError(
                        f"Failed to load external agent '{agent_name}'.\nAvailable agents: {agents_str}",
                    );
                }
                raise ValueError(
                    f"External agent '{agent_name}' not found.\nNo external agents are currently installed.\nRun: mobilerun run --help  to see available agents.",
                );
            }
            agent_config: any = self.config.external_agents.get(agent_name) or {};
            final_config: any = {**agent_module["config"], **agent_config};
            device_serial: any = self.resolved_device_config.serial;
            if is_portal_http_url(device_serial) {
                raise ValueError(
                    "External agents need an ADB device; a Portal HTTP URL is not supported."
                );
            }
            if device_serial is None {
                device_serial = (await resolve_android_serial());
                logger.info(f"📱 Using device: {device_serial}");
            }

            adb_device: any = (await adb.device(serial=device_serial));
            self.android_serial = device_serial;

            logger.info(f"🤖 Using external agent: {agent_name}");

            result: any = (
                await agent_module["run"](
                    device=adb_device,
                    instruction=self.shared_state.instruction,
                    config=final_config,
                    max_steps=self.config.agent.max_steps,
                )
            );
            return (FinalizeEvent(success=result["success"], reason=result["reason"]));
        }
        if self.config.agent.reasoning {
            vision_enabled: any = self.config.agent.vision_only
                or self.config.agent.manager.vision
                or self.config.agent.executor.vision;
        } else {
            vision_enabled = self.config.agent.vision_only or self.config.agent.fast_agent.vision;
        }
        if self.config.agent.reasoning {
            vision_llms: any = [
                llm
                for (use, llm) in (
                    (
                        self.config.agent.vision_only or self.config.agent.manager.vision,
                        self.manager_llm,
                    ),
                    (
                        self.config.agent.vision_only or self.config.agent.executor.vision,
                        self.executor_llm,
                    ),
                )
                if use and llm is not None
            ];
        } elif (self.config.agent.vision_only or self.config.agent.fast_agent.vision)
            and self.fast_agent_llm is not None
        {
            vision_llms = [self.fast_agent_llm];
        } else {
            vision_llms = [];
        }
        vision_resize_policy: any = VisionResizePolicy.from_llms(
            vision_llms, max_side_cap=self.config.agent.model_screenshot_max_side
        );
        if self.config.agent.reasoning {
            active_action_vision: any = self.config.agent.manager.vision
                and self.config.agent.executor.vision;
        } else {
            active_action_vision = self.config.agent.fast_agent.vision;
        }
        action_agent_has_vision: any = self.config.agent.vision_only or active_action_vision;
        coordinate_llm: any = self.executor_llm
            if self.config.agent.reasoning
            else self.fast_agent_llm;
        coordinate_agent_vision: any = self.config.agent.vision_only
            or (
                self.config.agent.executor.vision
                    if self.config.agent.reasoning
                    else self.config.agent.fast_agent.vision
            );
        use_normalized: any = self.config.agent.use_normalized_coordinates
            or coordinate_agent_vision
                and model_uses_normalized_coordinates(
                    `str(getattr(coordinate_llm, "model", "") or "")
                );

        is_ios: any = operator.eq(self.resolved_device_config.platform.lower(), "ios");
        control_backend: any = _normalize_control_backend(
            self.resolved_device_config.control_backend
        );
        if control_backend and control_backend != VISUAL_REMOTE_CONNECTION {
            raise ValueError(
                f"Unsupported device control backend '{self.resolved_device_config.control_backend}'. Supported: {VISUAL_REMOTE_CONNECTION}. Omit control backend for the platform default.",
            );
        }
        is_visual_remote: any = operator.eq(control_backend, VISUAL_REMOTE_CONNECTION);

        if self._injected_driver is not None {
            driver: any = self._injected_driver;
        } elif is_visual_remote {
            visual_remote_url: any = self.resolved_device_config.serial
                or VISUAL_REMOTE_DEFAULT_URL;
            driver = VisualRemoteDriver(
                url=visual_remote_url, device_id=self.resolved_device_config.device_id
            );
            (await driver.connect());
        } elif is_ios {
            ios_url: any = self.resolved_device_config.serial;
            if not ios_url {
                ios_url = (await discover_ios_device());
            }
            driver = (
                await create_ios_driver(
                    ios_url, token=self.resolved_device_config.resolve_auth_token()
                )
            );
            (await driver.connect());
        } elif is_portal_http_url(self.resolved_device_config.serial) {
            driver = create_android_portal_http_driver(
                self.resolved_device_config.serial, self.resolved_device_config.resolve_auth_token()
            );
            (await driver.connect());
        } else {
            device_serial = self.resolved_device_config.serial;
            if device_serial is None {
                device_serial = (await resolve_android_serial());
                logger.info(f"📱 Using device: {device_serial}");
            }

            self.android_serial = device_serial;
            if self.config.device.auto_setup
                and self.resolved_device_config.portal_mode != "disabled"
            {
                device_obj: any = (await adb.device(serial=device_serial));
                (
                    await ensure_portal_ready(
                        device_obj,
                        debug=self.config.logging.debug,
                        **portal_version_kwargs(ensure_portal_ready),
                    )
                );
            }

            driver = AndroidDriver(
                serial=device_serial,
                use_tcp=self.resolved_device_config.use_tcp,
                portal_mode=self.resolved_device_config.portal_mode,
            );
            (await driver.connect());
        }
        is_ios_portal_http: any = isinstance(driver, IOSPortalHttpDriver);
        stealth_enabled: any = self.config.tools and self.config.tools.stealth;
        if stealth_enabled and not is_ios and not is_visual_remote {
            driver = StealthDriver(driver);
        }
        if self.config.logging.save_trajectory != "none" {
            if not isinstance(driver, RecordingDriver) {
                driver = RecordingDriver(driver);
            }
        }

        self.driver = driver;
        self.shared_state.platform = driver.platform;
        if self._injected_state_provider is not None {
            self.state_provider = self._injected_state_provider;
        } elif self.config.agent.vision_only or is_visual_remote {
            self.state_provider = ScreenshotOnlyStateProvider(
                driver, vision_resize_policy=vision_resize_policy, use_normalized=use_normalized
            );
        } elif is_ios_portal_http {
            tree_filter: any = ConciseFilter() if vision_enabled else DetailedFilter();
            self.state_provider = AndroidStateProvider(
                driver,
                tree_filter=tree_filter,
                tree_formatter=IndexedFormatter(),
                use_normalized=use_normalized,
                stealth=False,
                vision_enabled=vision_enabled,
                vision_resize_policy=vision_resize_policy,
            );
        } elif is_ios {
            self.state_provider = IOSStateProvider(
                driver,
                use_normalized=use_normalized,
                vision_enabled=vision_enabled,
                vision_resize_policy=vision_resize_policy,
            );
        } else {
            tree_filter = ConciseFilter() if vision_enabled else DetailedFilter();
            tree_formatter: any = IndexedFormatter();
            self.state_provider = AndroidStateProvider(
                driver,
                tree_filter=tree_filter,
                tree_formatter=tree_formatter,
                use_normalized=use_normalized,
                stealth=stealth_enabled,
                vision_enabled=vision_enabled,
                vision_resize_policy=vision_resize_policy,
            );
        }

        if getattr(self.state_provider, "use_normalized", False) {
            logger.info("📐 Coordinates: normalized 0-1000");
        }
        (registry, standard_tool_names) = (
            await build_tool_registry(
                supported_buttons=driver.supported_buttons,
                credential_manager=self.credential_manager,
                platform="ios" if driver.platform.lower() == "ios" else "android",
                exact_app_launch=is_visual_remote,
                screenshot_only=getattr(self.state_provider, "requires_coordinate_tools", False),
                normalized_coordinates=getattr(self.state_provider, "use_normalized", False),
            )
        ) as any;
        if self.user_custom_tools {
            registry.register_from_dict(self.user_custom_tools);
        }
        if self.config.mcp and self.config.mcp.enabled {
            self.mcp_manager = MCPClientManager(self.config.mcp);
            (await self.mcp_manager.discover_tools());
            mcp_tools: any = mcp_to_mobilerun_tools(self.mcp_manager);
            if mcp_tools {
                registry.register_from_dict(mcp_tools);
            }
        }
        capabilities: any = driver.supported | self.state_provider.supported;
        registry.disable_unsupported(capabilities);
        user_disabled: any = self.config.tools.disabled_tools if self.config.tools else None;
        explicit_disabled: any = user_disabled is not None;
        disabled_tools: any = `list(user_disabled if explicit_disabled else DEFAULT_DISABLED_TOOLS);
        disabled_tools = _effective_disabled_tools(
            disabled_tools,
            self.state_provider,
            vision_enabled=action_agent_has_vision,
            explicit=explicit_disabled,
        );
        if disabled_tools {
            registry.disable(disabled_tools);
        }

        self.registry = registry;
        self.standard_tool_names = standard_tool_names;
        self.action_ctx = ActionContext(
            driver=driver,
            ui=None,
            shared_state=self.shared_state,
            state_provider=self.state_provider,
            app_opener_llm=self.app_opener_llm,
            credential_manager=self.credential_manager,
            streaming=self.config.agent.streaming,
            macro_recorder=self.macro_recorder,
        );
        if self.config.agent.reasoning and self.executor_agent {
            self.manager_agent.action_ctx = self.action_ctx;
            self.manager_agent.state_provider = self.state_provider;
            self.manager_agent.registry = self.registry;
            self.manager_agent.save_trajectory = self.config.logging.save_trajectory;
            self.manager_agent.standard_tool_names = self.standard_tool_names;
            self.executor_agent.registry = self.registry;
            self.executor_agent.action_ctx = self.action_ctx;
        }
        try {
            self.shared_state.device_date = (await driver.get_date());
        } except NotImplementedError {
            self.shared_state.device_date = "";
        }
        capture(
            MobileAgentInitEvent(
                goal=self.shared_state.instruction,
                llms={
                    "manager": self.manager_llm.class_name() if self.manager_llm else "None",
                    "executor": self.executor_llm.class_name() if self.executor_llm else "None",
                    "fast_agent": self.fast_agent_llm.class_name()
                        if self.fast_agent_llm
                        else "None",
                    "app_opener": self.app_opener_llm.class_name()
                        if self.app_opener_llm
                        else "None",
                },
                tools=",".join(sorted(standard_tool_names)),
                max_steps=self.config.agent.max_steps,
                timeout=self._init_timeout,
                vision={
                    "manager": self.config.agent.manager.vision,
                    "executor": self.config.agent.executor.vision,
                    "fast_agent": self.config.agent.fast_agent.vision,
                },
                reasoning=self.config.agent.reasoning,
                enable_tracing=self.config.tracing.enabled,
                debug=self.config.logging.debug,
                save_trajectories=self.config.logging.save_trajectory,
                runtype=self.runtype,
                custom_prompts=self._init_prompts,
            ),
            self.user_id,
            config_enabled=self.shared_state.telemetry_config_enabled,
        );

        if self.config.logging.save_trajectory != "none" {
            self.trajectory_writer.write(self.trajectory, stage="init");
        }

        if not self.config.agent.reasoning {
            logger.debug(
                f"🔄 Direct execution mode - executing goal: {self.shared_state.instruction}"
            );
            event: any = FastAgentExecuteEvent(instruction=self.shared_state.instruction);
            ctx.write_event_to_stream(event);
            return event;
        }

        logger.debug("🧠 Reasoning mode - initializing Manager/Executor workflow");
        event = ManagerInputEvent();
        ctx.write_event_to_stream(event);
        return event;
    }

    def send_user_message(message: builtins.str) -> QueuedUserMessage {
        queued: any = self.shared_state.queue_user_message(message);
        logger.info(
            f"📩 External user message queued [id={queued.id}] (queue length: {len(self.shared_state.pending_user_messages)})",
            extra={"color": "cyan"},
        );
        return queued;
    }

    """Execute a single task using FastAgent."""
    @step
    async def execute_task(ctx: Context, ev: FastAgentExecuteEvent) -> FastAgentResultEvent {
        logger.debug(f"🔧 Executing task: {ev.instruction}");

        try {
            agent: any = FastAgent(
                llm=self.fast_agent_llm,
                agent_config=self.config.agent,
                registry=self.registry,
                action_ctx=self.action_ctx,
                state_provider=self.state_provider,
                save_trajectory=self.config.logging.save_trajectory,
                debug=self.config.logging.debug,
                shared_state=self.shared_state,
                output_model=self.output_model,
                prompt_resolver=self.prompt_resolver,
                timeout=self.timeout,
                tracing_config=self.config.tracing,
            );

            handler: any = agent.run(input=ev.instruction);

            async for nested_ev in (handler.stream_events()) {
                self.handle_stream_event(nested_ev, ctx);

                if isinstance(nested_ev, FastAgentOutputEvent) {
                    if self.config.logging.save_trajectory != "none" {
                        self.trajectory_writer.write(
                            self.trajectory,
                            stage=f"fast_agent_step_{self.shared_state.step_number}",
                        );
                    }
                }
            }

            result: any = (await handler);

            return FastAgentResultEvent(
                success=result.get("success", False),
                reason=result["reason"],
                instruction=ev.instruction,
            );
        } except DeviceDisconnectedError as e {
            logger.error(f"Device disconnected: {e}");
            return FastAgentResultEvent(
                success=False, reason=f"Device disconnected: {e}", instruction=ev.instruction
            );
        } except Exception as e {
            error: any = describe_error(e);
            logger.error(f"Error during task execution: {error}");
            if self.config.logging.debug {
                logger.error(traceback.format_exc());
            }
            return FastAgentResultEvent(
                success=False, reason=f"Error: {error}", instruction=ev.instruction
            );
        }
    }

    @step
    async def handle_fast_agent_result(ctx: Context, ev: FastAgentResultEvent) -> FinalizeEvent {
        try {
            return FinalizeEvent(success=ev.success, reason=ev.reason);
        } except Exception as e {
            error: any = describe_error(e);
            logger.error(f"❌ Error during MobileAgent execution: {error}");
            if self.config.logging.debug {
                logger.error(traceback.format_exc());
            }
            return FinalizeEvent(success=False, reason=error);
        }
    }

    """Run Manager planning phase."""
    @step
    async def run_manager(ctx: Context, ev: ManagerInputEvent) -> ManagerPlanEvent | FinalizeEvent {
        if self.shared_state.step_number >= self.config.agent.max_steps {
            logger.warning(f"⚠️ Reached maximum steps ({self.config.agent.max_steps})");
            pending: any = self.shared_state.drain_user_messages();
            if pending {
                logger.warning(f"⚠️ Dropping {len(pending)} external user message(s) at max steps");
                ctx.write_event_to_stream(
                    ExternalUserMessageDroppedEvent(
                        message_ids=[m.id for m in pending],
                        reason="max_steps_reached",
                        step_number=self.shared_state.step_number,
                    ),
                );
            }
            return FinalizeEvent(
                success=False, reason=f"Reached maximum steps ({self.config.agent.max_steps})"
            );
        }

        self.shared_state.step_number += 1;
        logger.info(f"🔄 Step {self.shared_state.step_number}/{self.config.agent.max_steps}");

        try {
            handler: any = self.manager_agent.run();

            async for nested_ev in (handler.stream_events()) {
                self.handle_stream_event(nested_ev, ctx);
            }

            result: any = (await handler);
        } except DeviceDisconnectedError as e {
            logger.error(f"Device disconnected: {e}");
            return FinalizeEvent(success=False, reason=f"Device disconnected: {e}");
        } except ManagerResponseValidationError as e {
            logger.error(f"Manager response validation failed: {e}");
            return FinalizeEvent(success=False, reason=`str(e));
        }

        event: any = ManagerPlanEvent(
            plan=result["plan"],
            current_subgoal=result["current_subgoal"],
            thought=result["thought"],
            answer=result.get("answer", ""),
            success=result.get("success"),
        );
        ctx.write_event_to_stream(event);
        return event;
    }

    """Process Manager output and decide next step."""
    @step
    async def handle_manager_plan(ctx: Context, ev: ManagerPlanEvent) -> ExecutorInputEvent
        | FinalizeEvent
        | ManagerInputEvent {
        if ev.answer.strip() {
            if self.shared_state.pending_user_messages {
                logger.info(
                    "⏸️ Manager tried to finish but external messages pending, looping back to Manager",
                    extra={"color": "cyan"},
                );
                return ManagerInputEvent();
            }
            success: any = ev.success if ev.success is not None else False;
            self.shared_state.progress_summary = f"Answer: {ev.answer}";
            return FinalizeEvent(success=success, reason=ev.answer);
        }

        logger.debug(f"▶️  Proceeding to Executor with subgoal: {ev.current_subgoal}");
        return ExecutorInputEvent(current_subgoal=ev.current_subgoal);
    }

    """Run Executor action phase."""
    @step
    async def run_executor(ctx: Context, ev: ExecutorInputEvent) -> ExecutorResultEvent {
        logger.debug("⚡ Running Executor for action...");

        handler: any = self.executor_agent.run(subgoal=ev.current_subgoal);

        async for nested_ev in (handler.stream_events()) {
            self.handle_stream_event(nested_ev, ctx);
        }

        result: any = (await handler);
        self.shared_state.action_history.append(result["action"]);
        self.shared_state.summary_history.append(result["summary"]);
        self.shared_state.action_outcomes.append(result["outcome"]);
        self.shared_state.error_descriptions.append(result["error"]);
        self.shared_state.last_action = result["action"];
        self.shared_state.last_summary = result["summary"];

        return ExecutorResultEvent(
            action=result["action"],
            outcome=result["outcome"],
            error=result["error"],
            summary=result["summary"],
        );
    }

    """Process Executor result and continue."""
    @step
    async def handle_executor_result(ctx: Context, ev: ExecutorResultEvent) -> ManagerInputEvent {
        err_thresh: any = self.shared_state.err_to_manager_thresh;

        if len(self.shared_state.action_outcomes) >= err_thresh {
            latest: any = self.shared_state.action_outcomes[-err_thresh:];
            error_count: any = sum(1 for o in latest if not o);
            if error_count == err_thresh {
                logger.warning(f"⚠️ Error escalation: {err_thresh} consecutive errors");
                self.shared_state.error_flag_plan = True;
            } else {
                if self.shared_state.error_flag_plan {
                    logger.debug("✅ Error resolved - resetting error flag");
                }
                self.shared_state.error_flag_plan = False;
            }
        }

        if self.config.logging.save_trajectory != "none" {
            self.trajectory_writer.write(
                self.trajectory, stage=f"step_{self.shared_state.step_number}"
            );
        }

        return ManagerInputEvent();
    }

    @step
    async def finalize(ctx: Context, ev: FinalizeEvent) -> ResultEvent {
        result: any = ResultEvent(
            success=ev.success,
            reason=ev.reason,
            steps=self.shared_state.step_number,
            structured_output=None,
        );
        now: any = time.monotonic();
        workflow_deadline: any = (await ctx.store.get(_WORKFLOW_DEADLINE_KEY, default=None));
        workflow_limit: any = workflow_deadline - _FINALIZE_SCHEDULING_RESERVE_SECONDS
            if workflow_deadline is not None
            else `float("inf");
        deadline: any = min(now + _FINALIZE_BUDGET_SECONDS, workflow_limit);
        saves_trajectory: any = operator.ne(self.config.logging.save_trajectory, "none");
        has_mcp: any = self.mcp_manager is not None;
        available: any = max(0.0, deadline - now);
        cleanup_reserve: any = 0.0;
        if saves_trajectory {
            cleanup_demand: any = _FINALIZE_TRAJECTORY_SECONDS
                + (_FINALIZE_MCP_SECONDS if has_mcp else 0.0);
            cleanup_reserve = min(cleanup_demand, available * _FINALIZE_CLEANUP_MAX_FRACTION);
        } elif has_mcp {
            cleanup_reserve = min(
                _FINALIZE_MCP_SECONDS, available * _FINALIZE_CLEANUP_MAX_FRACTION
            );
        }
        pre_cleanup_deadline: any = deadline - cleanup_reserve;

        self.shared_state.workflow_completed = True;
        ctx.write_event_to_stream(ev);
        if self.output_model is not None and ev.reason {
            logger.debug("🔄 Running structured output extraction...");
            try {
                structured_agent: any = StructuredOutputAgent(
                    llm=self.structured_output_llm,
                    pydantic_model=self.output_model,
                    answer_text=ev.reason,
                );
                (completed, extraction_event) = (
                    await _run_finalize_stage(
                        "structured-output",
                        _structured_output_extraction(structured_agent, ctx),
                        pre_cleanup_deadline,
                        cap=_FINALIZE_BUDGET_SECONDS,
                    )
                ) as any;
                if completed and extraction_event.result["success"] {
                    result.structured_output = extraction_event.result["structured_output"];
                    logger.debug("✅ Structured output added to final result");
                }
            } except Exception as exc {
                logger.warning("Final structured output failed: %s", exc);
            }
        }

        (
            await _run_finalize_stage(
                "telemetry-flush",
                self._flush_final_telemetry(ev),
                pre_cleanup_deadline,
                cap=_FINALIZE_TELEMETRY_SECONDS,
            )
        );
        vision_any: any = self.config.agent.manager.vision
            or self.config.agent.executor.vision
            or self.config.agent.fast_agent.vision;
        if vision_any or self._stream_screenshots or self.config.logging.save_trajectory != "none" {
            observation_deadline: any = min(
                pre_cleanup_deadline, time.monotonic() + _FINALIZE_OBSERVATION_SECONDS
            );
            try {
                screenshot_operation: any = self.action_ctx.driver.screenshot();
                (completed, screenshot) = (
                    await _run_finalize_stage(
                        "screenshot",
                        screenshot_operation,
                        observation_deadline,
                        cap=_FINALIZE_OBSERVATION_SECONDS,
                    )
                ) as any;
            } except Exception as exc {
                logger.warning("Failed to start final screenshot: %s", exc);
                (completed, screenshot) = (False, None);
            }
            if completed and screenshot {
                try {
                    ctx.write_event_to_stream(ScreenshotEvent(screenshot=screenshot));
                    record_langfuse_screenshot(
                        screenshot,
                        parent_span=trace.get_current_span(),
                        screenshots_enabled=self.config.tracing.langfuse_screenshots,
                        vision_enabled=vision_any,
                    );
                    logger.debug("📸 Final screenshot captured");
                } except Exception as exc {
                    logger.warning("Failed to publish final screenshot: %s", exc);
                }
            }

            try {
                final_state: any = getattr(
                    self.state_provider, "get_final_state", self.state_provider.get_state
                );
                (completed, ui_state) = (
                    await _run_finalize_stage(
                        "ui-state",
                        final_state(),
                        observation_deadline,
                        cap=_FINALIZE_OBSERVATION_SECONDS,
                    )
                ) as any;
            } except Exception as exc {
                logger.warning("Failed to start final UI state: %s", exc);
                (completed, ui_state) = (False, None);
            }
            if completed and ui_state is not None {
                try {
                    ctx.write_event_to_stream(RecordUIStateEvent(ui_state=ui_state.elements));
                    logger.debug("📋 Final UI state captured");
                } except Exception as exc {
                    logger.warning("Failed to publish final UI state: %s", exc);
                }
            }
        }
        if saves_trajectory {
            trajectory_written: any = False;
            try {
                if self.macro_recorder and self.macro_recorder.actions {
                    self.trajectory.macro = `list(self.macro_recorder.actions);
                } elif isinstance(self.driver, RecordingDriver) {
                    self.trajectory.macro = `list(self.driver.log);
                }
                self.trajectory_writer.write_final(
                    self.trajectory, self.config.logging.trajectory_gifs
                );
                trajectory_written = True;
            } except Exception as exc {
                logger.warning("Final trajectory persistence failed: %s", exc);
            } finally {
                try {
                    mcp_reserve: any = min(
                        _FINALIZE_MCP_SECONDS, max(0.0, deadline - time.monotonic()) / 2
                    )
                        if has_mcp
                        else 0.0;
                    (completed, _) = (
                        await _run_finalize_stage(
                            "trajectory-stop",
                            self.trajectory_writer.stop(),
                            deadline - mcp_reserve,
                            cap=_FINALIZE_TRAJECTORY_SECONDS,
                            continue_in_background=True,
                        )
                    ) as any;
                    if trajectory_written and completed {
                        logger.info(f"📁 Trajectory saved: {self.trajectory.trajectory_folder}");
                    }
                } except Exception as exc {
                    logger.warning("Final trajectory shutdown failed: %s", exc);
                }
            }
        }
        if has_mcp {
            try {
                (
                    await _run_finalize_stage(
                        "mcp-disconnect",
                        self.mcp_manager.disconnect_all(),
                        deadline,
                        cap=_FINALIZE_MCP_SECONDS,
                        continue_in_background=True,
                    )
                );
            } except Exception as exc {
                logger.warning("MCP cleanup setup failed: %s", exc);
            }
        }

        return result;
    }

    async def _flush_final_telemetry(ev: FinalizeEvent) -> None {
        try {
            capture(
                MobileAgentFinalizeEvent(
                    success=ev.success,
                    reason=ev.reason,
                    steps=self.shared_state.step_number,
                    unique_packages_count=len(self.shared_state.visited_packages),
                    unique_activities_count=len(self.shared_state.visited_activities),
                ),
                self.user_id,
                config_enabled=self.shared_state.telemetry_config_enabled,
            );
        } except Exception as exc {
            logger.warning("Final telemetry capture failed: %s", exc);
        }
        (await flush(config_enabled=self.shared_state.telemetry_config_enabled));
    }

    def handle_stream_event(ev: Event, ctx: Context) -> any {
        if not isinstance(ev, StopEvent) {
            ctx.write_event_to_stream(ev);

            if self.trajectory {
                if isinstance(ev, ScreenshotEvent) {
                    self.trajectory.screenshot_queue.append(ev.screenshot);
                    self.trajectory.screenshot_count += 1;
                } elif isinstance(ev, RecordUIStateEvent) {
                    self.trajectory.ui_states.append(ev.ui_state);
                } else {
                    self.trajectory.events.append(ev);
                }
            }
        }
    }
}

with entry {
    DroidAgent = MobileAgent;
}
