impl _card_platform(platform: str | None) -> str | None {
    value: any = (platform or "").lower();
    return value if value in ("android", "ios") else None;
}

impl ManagerAgent.init(
    llm: LLM,
    action_ctx: "ActionContext | None",
    state_provider: "StateProvider | None",
    save_trajectory: str = "none",
    shared_state: "MobileAgentState" = None,
    agent_config: "AgentConfig" = None,
    registry: "ToolRegistry | None" = None,
    output_model: Type[BaseModel] | None = None,
    prompt_resolver: Optional[PromptResolver] = None,
    tracing_config: "TracingConfig | None" = None,
    **kwargs,
) {
    getattr(Workflow, "__init__")(self, **kwargs);
    self.llm = llm;
    self.config = agent_config.manager;
    self.vision = self.config.vision;
    self.action_ctx = action_ctx;
    self.state_provider = state_provider;
    self.save_trajectory = save_trajectory;
    self._stream_screenshots = (
        os.environ.get("MOBILERUN_STREAM_SCREENSHOTS")
        or os.environ.get("DROIDRUN_STREAM_SCREENSHOTS")
        or ""
    ).lower()
        in ("1", "true");
    self.shared_state = shared_state;
    self.registry = registry;
    self.output_model = output_model;
    self.agent_config = agent_config;
    self.app_card_config = self.agent_config.app_cards;
    self.prompt_resolver = prompt_resolver or PromptResolver();
    self.tracing_config = tracing_config;
    self.standard_tool_names = None;
    self.app_card_provider = self._initialize_app_card_provider();

    logger.debug("ManagerAgent initialized.");
}

impl ManagerAgent._initialize_app_card_provider -> AppCardProvider {
    if not self.app_card_config.enabled {
        return DisabledAppCardProvider();
    }

    mode: any = self.app_card_config.mode.lower();

    if mode == "local" {
        return LocalAppCardProvider(app_cards_dir=self.app_card_config.app_cards_dir);
    } elif mode == "server" {
        if not self.app_card_config.server_url {
            logger.warning("Server mode but no server_url, falling back to local");
            return LocalAppCardProvider(app_cards_dir=self.app_card_config.app_cards_dir);
        }
        return ServerAppCardProvider(
            server_url=self.app_card_config.server_url,
            timeout=self.app_card_config.server_timeout,
            max_retries=self.app_card_config.server_max_retries,
        );
    } elif mode == "composite" {
        if not self.app_card_config.server_url {
            logger.warning("Composite mode but no server_url, falling back to local");
            return LocalAppCardProvider(app_cards_dir=self.app_card_config.app_cards_dir);
        }
        return CompositeAppCardProvider(
            server_url=self.app_card_config.server_url,
            app_cards_dir=self.app_card_config.app_cards_dir,
            server_timeout=self.app_card_config.server_timeout,
            server_max_retries=self.app_card_config.server_max_retries,
        );
    } else {
        logger.warning(f"Unknown app_card mode '{mode}', falling back to local");
        return LocalAppCardProvider(app_cards_dir=self.app_card_config.app_cards_dir);
    }
}

impl ManagerAgent._load_app_card -> None {
    if not self.app_card_config.enabled {
        self.shared_state.app_card = "";
        return;
    }
    try {
        self.shared_state.app_card = (
            await self.app_card_provider.load_app_card(
                package_name=self.shared_state.current_package_name,
                instruction=self.shared_state.instruction,
                platform=_card_platform(self.shared_state.platform),
            )
        );
    } except Exception as e {
        logger.warning(f"Error loading app card: {e}");
        self.shared_state.app_card = "";
    }
}

impl ManagerAgent._build_system_prompt -> str {
    error_history: any = None;
    if self.shared_state.error_flag_plan {
        k: any = self.shared_state.err_to_manager_thresh;
        error_history = [
            {"action": act, "summary": summ, "error": err_des}
            for (act, summ, err_des) in builtins.zip(
                self.shared_state.action_history[-k:],
                self.shared_state.summary_history[-k:],
                self.shared_state.error_descriptions[-k:],
                strict=True,
            )
        ];
    }
    available_secrets: any = [];
    if self.registry
        and "type_secret" in self.registry.tools
        and self.action_ctx
        and self.action_ctx.credential_manager
    {
        available_secrets = (await self.action_ctx.credential_manager.get_keys());
    }
    output_schema: any = None;
    if self.output_model is not None {
        output_schema = self.output_model.model_json_schema();
    }
    custom_tools_descriptions: any = "";
    if self.registry {
        _standard: any = self.standard_tool_names or set[any]();
        custom_tools_descriptions = self.registry.get_tool_descriptions_text(exclude=_standard);
    }

    variables: any = {
        "instruction": self.shared_state.instruction,
        "device_date": self.shared_state.device_date,
        "app_card": self.shared_state.app_card,
        "important_notes": "",
        "error_history": error_history,
        "custom_tools_descriptions": custom_tools_descriptions,
        "available_secrets": available_secrets,
        "variables": self.shared_state.custom_variables,
        "output_schema": output_schema,
        "platform": self.shared_state.platform,
    };

    custom_prompt: any = self.prompt_resolver.get_prompt("manager_system");
    if custom_prompt {
        return PromptLoader.render_template(custom_prompt, variables);
    }
    return (
        await PromptLoader.load_prompt(
            self.agent_config.get_manager_system_prompt_path(), variables
        )
    );
}

impl ManagerAgent._build_user_message_content -> str {
    parts: any = [];
    if self.shared_state.last_thought {
        parts.append(f"<thought>\n{self.shared_state.last_thought}\n</thought>\n");
    }
    if self.shared_state.last_action {
        action_str: any = json.dumps(self.shared_state.last_action);
        parts.append(f"<last_action>\n{action_str}\n</last_action>\n");
    }
    if self.shared_state.last_summary {
        parts.append(
            f"<last_action_description>\n{self.shared_state.last_summary}\n</last_action_description>\n",
        );
    }

    return "".join(parts);
}

impl ManagerAgent._build_messages_with_context(
    system_prompt: str, screenshot: bytes | None = None
) -> list[ChatMessage] {
    messages: any = [ChatMessage(role="system", content=system_prompt)];
    messages.extend(copy.deepcopy(self.shared_state.message_history));
    user_indices: any = [i for (i, msg) in enumerate(messages) if msg.role == MessageRole.USER];

    if user_indices {
        last_user_idx: any = user_indices[-1];
        current_memory: any = (self.shared_state.agent_memory or "").strip();
        if current_memory {
            messages[last_user_idx].blocks.append(
                TextBlock(text=f"\n<memory>\n{current_memory}\n</memory>\n")
            );
        }
        current_state: any = self.shared_state.formatted_device_state.strip();
        if current_state {
            messages[last_user_idx].blocks.append(
                TextBlock(text=f"\n<device_state>\n{current_state}\n</device_state>\n")
            );
        }
        if screenshot and self.vision {
            messages[last_user_idx].blocks.append(ImageBlock(image=screenshot));
        }
        if len(user_indices) >= 2 {
            second_last_idx: any = user_indices[-2];
            prev_state: any = self.shared_state.previous_formatted_device_state.strip();
            if prev_state {
                messages[second_last_idx].blocks.append(
                    TextBlock(
                        text=f"\n<previous_device_state>\n{prev_state}\n</previous_device_state>\n"
                    ),
                );
            }
        }
    }

    messages = filter_empty_messages(messages);
    return messages;
}

impl ManagerAgent._validate_and_retry(messages: list[ChatMessage], initial_response: str) -> str {
    output: any = initial_response;
    parsed: any = parse_manager_response(output);

    max_retries: any = 3;
    retry_count: any = 0;

    while retry_count < max_retries {
        validation: any = validate_manager_response(parsed);
        if validation.is_valid {
            return output;
        }

        validation_error: any = validation.error_message or "Invalid manager response.";
        error_message: any = f"{validation_error}\nRetry again.";
        retry_count += 1;
        logger.warning(
            f"Manager response invalid (retry {retry_count}/{max_retries}): {error_message}"
        );

        retry_messages: any = messages + [
            ChatMessage(role="assistant", content=output),
            ChatMessage(role="user", content=error_message),
        ];

        try {
            response: any = (
                await acall_with_retries(
                    self.llm, retry_messages, stream=self.agent_config.streaming
                )
            );
            output = response.message.content;
            parsed = parse_manager_response(output);
        } except Exception as e {
            logger.error(f"LLM retry failed: {describe_error(e)}");
            raise ManagerResponseValidationError(validation_error) from e;
        }
    }

    validation = validate_manager_response(parsed);
    if validation.is_valid {
        return output;
    }
    raise ManagerResponseValidationError(validation.error_message or "Invalid manager response.");
}

impl ManagerAgent.prepare_context(ctx: Context, ev: StartEvent) -> ManagerContextEvent {
    logger.debug("💬 Preparing manager context...");
    screenshot: any = None;
    if self.vision or self._stream_screenshots or self.save_trajectory != "none" {
        try {
            screenshot = (await self.action_ctx.driver.screenshot());

            if screenshot {
                ctx.write_event_to_stream(ScreenshotEvent(screenshot=screenshot));
                parent_span: any = trace.get_current_span();
                record_langfuse_screenshot(
                    screenshot,
                    parent_span=parent_span,
                    screenshots_enabled=`bool(
                        self.tracing_config and self.tracing_config.langfuse_screenshots
                    ),
                    vision_enabled=self.vision,
                );
                logger.debug("📸 Screenshot captured for Manager");
            }
        } except DeviceDisconnectedError {
            raise;
        } except Exception as e {
            logger.warning(f"Failed to capture screenshot: {e}");
        }
    }
    ui_state: any = (await self.state_provider.get_state());
    self.action_ctx.ui = ui_state;
    self.shared_state.previous_formatted_device_state = self.shared_state.formatted_device_state;
    self.shared_state.formatted_device_state = ui_state.formatted_text;
    self.shared_state.focused_text = ui_state.focused_text;
    self.shared_state.a11y_tree = ui_state.elements;
    self.shared_state.phone_state = ui_state.phone_state;
    self.shared_state.update_current_app(
        package_name=ui_state.phone_state.get("packageName", "Unknown"),
        activity_name=ui_state.phone_state.get("currentApp", "Unknown"),
    );
    ctx.write_event_to_stream(RecordUIStateEvent(ui_state=ui_state.elements));

    (await self._load_app_card());

    self.shared_state.screenshot = screenshot;
    user_content: any = self._build_user_message_content();

    drained: any = self.shared_state.drain_user_messages();
    if drained {
        external_block: any = "\n".join(
            f"<external_user_message>\n{m.message}\n</external_user_message>" for m in drained
        );
        user_content += "\n" + external_block + "\n";
        logger.info(f"📩 Applied {len(drained)} external user message(s)", extra={"color": "cyan"});
        ctx.write_event_to_stream(
            ExternalUserMessageAppliedEvent(
                message_ids=[m.id for m in drained],
                consumer="manager",
                step_number=self.shared_state.step_number,
            ),
        );
    }

    self.shared_state.message_history.append(ChatMessage(role="user", content=user_content));

    event: any = ManagerContextEvent();
    ctx.write_event_to_stream(event);
    return event;
}

impl ManagerAgent.get_response(ctx: Context, ev: ManagerContextEvent) -> ManagerResponseEvent {
    logger.debug("🧠 Manager thinking about the plan...");

    screenshot: any = self.shared_state.screenshot;
    system_prompt: any = (await self._build_system_prompt());

    if screenshot and self.vision {
        screenshot = (await resize_model_screenshot_async(self.state_provider, screenshot));
    }
    messages: any = self._build_messages_with_context(
        system_prompt=system_prompt, screenshot=screenshot
    );

    try {
        logger.info("📋 Manager response:", extra={"color": "cyan"});
        response: any = (
            await acall_with_retries(self.llm, messages, stream=self.agent_config.streaming)
        );
        output: any = response.message.content;
    } except Exception as e {
        error: any = describe_error(e);
        logger.error(f"LLM call failed: {error}");
        raise RuntimeError(f"Error calling LLM in manager: {error}") from e;
    }
    usage: any = None;
    try {
        usage = get_usage_from_response(self.llm.class_name(), response);
    } except Exception as e {
        logger.warning(f"Could not get usage: {e}");
    }

    output = (await self._validate_and_retry(messages, output));

    event: any = ManagerResponseEvent(response=output, usage=usage);
    ctx.write_event_to_stream(event);
    return event;
}

impl ManagerAgent.process_response(
    ctx: Context, ev: ManagerResponseEvent
) -> ManagerPlanDetailsEvent {
    logger.debug("⚙️ Processing manager response...");

    output: any = ev.response;
    parsed: any = parse_manager_response(output);
    memory_update: any = parsed.get("memory", "").strip();
    if memory_update {
        self.shared_state.append_memory(memory_update);
    }
    self.shared_state.message_history.append(ChatMessage(role="assistant", content=output));
    self.shared_state.previous_plan = self.shared_state.plan;
    self.shared_state.plan = parsed["plan"];
    self.shared_state.current_subgoal = parsed["current_subgoal"];
    self.shared_state.last_thought = parsed["thought"];
    self.shared_state.answer = parsed["answer"];

    if parsed.get("progress_summary") {
        self.shared_state.progress_summary = parsed["progress_summary"];
    }

    event: any = ManagerPlanDetailsEvent(
        plan=parsed["plan"],
        subgoal=parsed["current_subgoal"],
        thought=parsed["thought"],
        answer=parsed["answer"],
        memory_update=memory_update,
        progress_summary=parsed.get("progress_summary", ""),
        success=parsed["success"],
        full_response=output,
    );
    ctx.write_event_to_stream(event);
    return event;
}

impl ManagerAgent.finalize(ctx: Context, ev: ManagerPlanDetailsEvent) -> StopEvent {
    logger.debug("✅ Manager planning complete");

    return StopEvent(
        result={
            "plan": ev.plan,
            "current_subgoal": ev.subgoal,
            "thought": ev.thought,
            "answer": ev.answer,
            "memory_update": ev.memory_update,
            "success": ev.success,
        },
    );
}
