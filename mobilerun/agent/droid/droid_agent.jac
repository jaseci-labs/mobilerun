import builtins;

import operator;

import importlib;

import functools;

import asyncio;

import logging;

import os;

import time;

import traceback;

import from typing { TYPE_CHECKING, Any, Awaitable, Type, Union, cast }

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

def _reap_abandoned_finalize_task(task: asyncio.Task[Any]) -> None;

async def _capped_finalize_stage(
    name: builtins.str, awaitable: Awaitable[Any], cap: builtins.float
) -> Any;

async def _run_finalize_stage(
    name: builtins.str,
    awaitable: Awaitable[Any],
    deadline: builtins.float,
    cap: builtins.float,
    *,
    continue_in_background: builtins.bool = False,
) -> builtins.tuple[builtins.bool, Any];

async def _extract_structured_output(
    structured_agent: StructuredOutputAgent, ctx: Context
) -> StopEvent;

def _structured_output_extraction(
    structured_agent: StructuredOutputAgent, ctx: Context
) -> Awaitable[StopEvent];

def _normalize_control_backend(control_backend: builtins.str | None) -> builtins.str | None;

def _force_screenshot_only_vision(agent_config: AgentConfig) -> None;

def _effective_disabled_tools(
    disabled_tools: builtins.list[builtins.str],
    state_provider,
    vision_enabled: builtins.bool = False,
    explicit: builtins.bool = False,
) -> builtins.list[builtins.str];

"""
    A wrapper class that coordinates between agents to achieve a user's goal.

    Reasoning modes:
    - reasoning=False: Uses FastAgent directly for immediate execution
    - reasoning=True: Uses ManagerAgent (planning) + ExecutorAgent (actions)
    """
class MobileAgent(Workflow) {
    has _tracing_session_id: builtins.str | None = None;

    has _tracing_user_id: builtins.str | None = None;

    static def _configure_default_logging(debug: builtins.bool = False) -> any;

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
    );

    def run(*args__, **kwargs) -> Awaitable[ResultEvent] | WorkflowHandler;

    async def _initialize_workflow_deadline(ctx: Context) -> None;

    async def _initialize_run_trajectory -> None;

    @step
    async def start_handler(ctx: Context, ev: StartEvent) -> FastAgentExecuteEvent
        | ManagerInputEvent
        | FinalizeEvent;

    def send_user_message(message: builtins.str) -> QueuedUserMessage;

    """Execute a single task using FastAgent."""
    @step
    async def execute_task(ctx: Context, ev: FastAgentExecuteEvent) -> FastAgentResultEvent;

    @step
    async def handle_fast_agent_result(ctx: Context, ev: FastAgentResultEvent) -> FinalizeEvent;

    """Run Manager planning phase."""
    @step
    async def run_manager(ctx: Context, ev: ManagerInputEvent) -> ManagerPlanEvent | FinalizeEvent;

    """Process Manager output and decide next step."""
    @step
    async def handle_manager_plan(ctx: Context, ev: ManagerPlanEvent) -> ExecutorInputEvent
        | FinalizeEvent
        | ManagerInputEvent;

    """Run Executor action phase."""
    @step
    async def run_executor(ctx: Context, ev: ExecutorInputEvent) -> ExecutorResultEvent;

    """Process Executor result and continue."""
    @step
    async def handle_executor_result(ctx: Context, ev: ExecutorResultEvent) -> ManagerInputEvent;

    @step
    async def finalize(ctx: Context, ev: FinalizeEvent) -> ResultEvent;

    async def _flush_final_telemetry(ev: FinalizeEvent) -> None;

    def handle_stream_event(ev: Event, ctx: Context) -> any;
}

with entry {
    DroidAgent = MobileAgent;
}
