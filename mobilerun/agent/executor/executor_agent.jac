import from __future__ { annotations }

import builtins;

import asyncio;

import json;

import logging;

import from typing { TYPE_CHECKING, Optional }

import from llama_index.core.base.llms.types { ChatMessage, ImageBlock, TextBlock }

import from llama_index.core.llms.llm { LLM }

import from llama_index.core.workflow { Context, StartEvent, StopEvent, Workflow, step }

glob logger: any = logging.getLogger("mobilerun");

"""
    Action execution agent that performs specific actions.

    Single-turn agent: receives subgoal, selects action, executes it.
    Uses ChatMessage objects directly for LLM calls.
    """
class ExecutorAgent(Workflow) {
    static has _EXCLUDE_TOOLS: any = {"complete"};

    def init(
        llm: LLM,
        registry: "ToolRegistry | None",
        action_ctx: "ActionContext | None",
        shared_state: "MobileAgentState",
        agent_config: AgentConfig,
        prompt_resolver: Optional[PromptResolver] = None,
        **kwargs,
    );

    """Prepare executor context and prompt."""
    @step
    async def prepare_context(ctx: Context, ev: StartEvent) -> ExecutorContextEvent;

    """Get LLM response."""
    @step
    async def get_response(ctx: Context, ev: ExecutorContextEvent) -> ExecutorResponseEvent;

    """Parse LLM response and extract action."""
    @step
    async def process_response(ctx: Context, ev: ExecutorResponseEvent) -> ExecutorActionEvent;

    """Execute the action."""
    @step
    async def execute(ctx: Context, ev: ExecutorActionEvent) -> ExecutorActionResultEvent;

    """Return executor results to parent workflow."""
    @step
    async def finalize(ctx: Context, ev: ExecutorActionResultEvent) -> StopEvent;
}
