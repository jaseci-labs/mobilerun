import from __future__ { annotations }

import builtins;

import copy;

import json;

import logging;

import os;

import from typing { TYPE_CHECKING, Optional, Type }

import from llama_index.core.base.llms.types { ChatMessage, ImageBlock, MessageRole, TextBlock }

import from llama_index.core.llms.llm { LLM }

import from llama_index.core.workflow { Context, StartEvent, StopEvent, Workflow, step }

import from mobilerun_core_local.driver.base { DeviceDisconnectedError }

import from opentelemetry { trace }

import from pydantic { BaseModel }

glob logger: any = logging.getLogger("mobilerun");

def _card_platform(platform: str | None) -> str | None;

"""
    Planning and reasoning agent that decides what to do next.

    The Manager:
    1. Analyzes current device state and action history
    2. Creates plans with specific subgoals
    3. Tracks progress and completed steps
    4. Decides when tasks are complete or need to provide answers
    """
class ManagerAgent(Workflow) {
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

    def _initialize_app_card_provider -> AppCardProvider;

    async def _load_app_card -> None;

    async def _build_system_prompt -> str;

    def _build_user_message_content -> str;

    def _build_messages_with_context(
        system_prompt: str, screenshot: bytes | None = None
    ) -> list[ChatMessage];

    async def _validate_and_retry(messages: list[ChatMessage], initial_response: str) -> str;

    """Gather context and prepare manager prompt."""
    @step
    async def prepare_context(ctx: Context, ev: StartEvent) -> ManagerContextEvent;

    """Get LLM response."""
    @step
    async def get_response(ctx: Context, ev: ManagerContextEvent) -> ManagerResponseEvent;

    """Parse LLM response and update state."""
    @step
    async def process_response(ctx: Context, ev: ManagerResponseEvent) -> ManagerPlanDetailsEvent;

    @step
    async def finalize(ctx: Context, ev: ManagerPlanDetailsEvent) -> StopEvent;
}
