impl ExecutorAgent.init(
    llm: LLM,
    registry: "ToolRegistry | None",
    action_ctx: "ActionContext | None",
    shared_state: "MobileAgentState",
    agent_config: AgentConfig,
    prompt_resolver: Optional[PromptResolver] = None,
    **kwargs,
) {
    getattr(Workflow, "__init__")(self, **kwargs);
    self.llm = llm;
    self.agent_config = agent_config;
    self.config = agent_config.executor;
    self.vision = agent_config.executor.vision;
    self.registry = registry;
    self.action_ctx = action_ctx;
    self.shared_state = shared_state;
    self.prompt_resolver = prompt_resolver or PromptResolver();

    logger.debug("ExecutorAgent initialized.");
}

impl ExecutorAgent.prepare_context(ctx: Context, ev: StartEvent) -> ExecutorContextEvent {
    subgoal: any = ev.get("subgoal", "");
    logger.debug(f"🧠 Executor thinking about action for: {subgoal}");
    action_history: any = [];
    if self.shared_state.action_history {
        n: any = min(5, len(self.shared_state.action_history));
        action_history = [
            {"action": act, "summary": summ, "outcome": outcome, "error": err}
            for (act, summ, outcome, err) in builtins.zip(
                self.shared_state.action_history[-n:],
                self.shared_state.summary_history[-n:],
                self.shared_state.action_outcomes[-n:],
                self.shared_state.error_descriptions[-n:],
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
    variables: any = {
        "instruction": self.shared_state.instruction,
        "app_card": self.shared_state.app_card,
        "device_state": self.shared_state.formatted_device_state,
        "plan": self.shared_state.plan,
        "subgoal": subgoal,
        "progress_status": self.shared_state.progress_summary,
        "atomic_actions": self.registry.get_signatures(exclude=self._EXCLUDE_TOOLS),
        "action_history": action_history,
        "available_secrets": available_secrets,
        "variables": self.shared_state.custom_variables,
        "platform": self.shared_state.platform,
    };

    custom_prompt: any = self.prompt_resolver.get_prompt("executor_system");
    if custom_prompt {
        prompt_text: any = PromptLoader.render_template(custom_prompt, variables);
    } else {
        prompt_text = (
            await PromptLoader.load_prompt(
                self.agent_config.get_executor_system_prompt_path(), variables
            )
        );
    }
    messages: any = [ChatMessage(role="user", blocks=[TextBlock(text=prompt_text)])];
    if self.vision {
        screenshot: any = self.shared_state.screenshot;
        if screenshot is not None {
            screenshot = (
                await resize_model_screenshot_async(self.action_ctx.state_provider, screenshot)
            );
            messages[0].blocks.append(ImageBlock(image=screenshot));
            logger.debug("📸 Using screenshot for Executor");
        } else {
            logger.warning("⚠️ Vision enabled but no screenshot available");
        }
    }
    (await ctx.store.set("executor_messages", messages));
    event: any = ExecutorContextEvent(subgoal=subgoal);
    ctx.write_event_to_stream(event);
    return event;
}

impl ExecutorAgent.get_response(ctx: Context, ev: ExecutorContextEvent) -> ExecutorResponseEvent {
    logger.debug("Executor getting LLM response...");
    messages: any = (await ctx.store.get("executor_messages"));

    try {
        logger.info("Executor response:", extra={"color": "green"});
        response: any = (
            await acall_with_retries(self.llm, messages, stream=self.agent_config.streaming)
        );
        response_text: any = `str(response);
    } except ValueError as e {
        logger.warning(f"Executor LLM returned empty response: {e}");
        error_response: any = "### Thought\nExecutor failed to respond, try again\n### Action\n{\"action\": \"invalid\"}\n### Description\nExecutor failed to respond, try again";
        event: any = ExecutorResponseEvent(response=error_response, usage=None);
        ctx.write_event_to_stream(event);
        return event;
    } except Exception as e {
        raise RuntimeError(f"Error calling LLM in executor: {describe_error(e)}") from e;
    }
    usage: any = None;
    try {
        usage = get_usage_from_response(self.llm.class_name(), response);
    } except Exception as e {
        logger.warning(f"Could not get usage: {e}");
    }

    event = ExecutorResponseEvent(response=response_text, usage=usage);
    ctx.write_event_to_stream(event);
    return event;
}

impl ExecutorAgent.process_response(
    ctx: Context, ev: ExecutorResponseEvent
) -> ExecutorActionEvent {
    logger.debug("⚙️ Processing executor response...");

    response_text: any = ev.response;

    try {
        parsed: any = parse_executor_response(response_text);
    } except Exception as e {
        logger.error(f"❌ Failed to parse executor response: {e}");
        return ExecutorActionEvent(
            action_json=json.dumps({"action": "invalid"}),
            thought=f"Failed to parse response: {`str(e)}",
            description="Invalid response format from LLM",
            full_response=response_text,
        );
    }
    self.shared_state.last_thought = parsed["thought"];

    event: any = ExecutorActionEvent(
        action_json=parsed["action"],
        thought=parsed["thought"],
        description=parsed["description"],
        full_response=response_text,
    );

    ctx.write_event_to_stream(event);
    return event;
}

impl ExecutorAgent.execute(ctx: Context, ev: ExecutorActionEvent) -> ExecutorActionResultEvent {
    logger.debug(f"⚡ Executing action: {ev.description}");

    try {
        action_dict: any = json.loads(ev.action_json);
    } except json.JSONDecodeError as e {
        logger.error(f"❌ Failed to parse action JSON: {e}");
        event: any = ExecutorActionResultEvent(
            action={"action": "invalid"},
            success=False,
            error=f"Invalid action JSON: {`str(e)}",
            summary="Failed to parse action",
            thought=ev.thought,
            full_response=ev.full_response,
        );
        ctx.write_event_to_stream(event);
        return event;
    }
    action_type: any = action_dict.get("action", "unknown");
    action_args: any = {k: v for (k, v) in action_dict.items() if k != "action"};

    result: any = (
        await self.registry.execute(action_type, action_args, self.action_ctx, workflow_ctx=ctx)
    );

    (await asyncio.sleep(self.agent_config.after_sleep_action));

    logger.debug(
        format("✅" if result.success else "❌", "")
            + " Execution complete: "
            + format(result.summary, ""),
    );

    event = ExecutorActionResultEvent(
        action=action_dict,
        success=result.success,
        error="" if result.success else result.summary,
        summary=result.summary,
        thought=ev.thought,
        full_response=ev.full_response,
    );
    ctx.write_event_to_stream(event);
    return event;
}

impl ExecutorAgent.finalize(ctx: Context, ev: ExecutorActionResultEvent) -> StopEvent {
    logger.debug("✅ Executor execution complete");

    return StopEvent(
        result={
            "action": ev.action,
            "outcome": ev.success,
            "error": ev.error,
            "summary": ev.summary,
            "thought": ev.thought,
        },
    );
}
