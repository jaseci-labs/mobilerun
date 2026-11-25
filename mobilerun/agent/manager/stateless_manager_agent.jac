import from __future__ { annotations }

import builtins;

import logging;

import from typing { TYPE_CHECKING, Optional, Type }

import from llama_index.core.llms.llm { LLM }

import from llama_index.core.workflow { Context, StartEvent, StopEvent, Workflow, step }

import from mobilerun_core_local.driver.base { DeviceDisconnectedError }

import from opentelemetry { trace }

import from pydantic { BaseModel }

glob logger: any;

with entry {
    logger = logging.getLogger("mobilerun");
}

class StatelessManagerAgent(Workflow) {
    def init(
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
    );

    def _build_action_history -> list[dict];

    async def _build_prompt -> str;

    async def _validate_and_retry(messages: list[dict], initial_response: str) -> str;

    @step
    async def prepare_context(ctx: Context, ev: StartEvent) -> ManagerContextEvent;

    @step
    async def get_response(ctx: Context, ev: ManagerContextEvent) -> ManagerResponseEvent;

    @step
    async def process_response(ctx: Context, ev: ManagerResponseEvent) -> ManagerPlanDetailsEvent;

    @step
    async def finalize(ctx: Context, ev: ManagerPlanDetailsEvent) -> StopEvent;
}
