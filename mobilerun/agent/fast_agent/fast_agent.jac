"""FastAgent — tool-calling agent for device interaction.

Uses a structured XML tool-calling protocol by default. The LLM emits
<function_calls> blocks, the agent parses them, executes the tools via
ToolRegistry, and feeds <function_results> back as user messages. LLMs that
support native function calling receive the tools as API tool definitions
instead and get tool-result messages back.
"""

import builtins;

import operator;

import asyncio;

import copy;

import logging;

import os;

import from typing { TYPE_CHECKING, Optional, Type }

import from llama_index.core.base.llms.types { ChatMessage, ImageBlock, TextBlock }

import from llama_index.core.llms.llm { LLM }

import from llama_index.core.workflow { Context, StartEvent, StopEvent, Workflow, step }

import from mobilerun_core_local.driver.base { DeviceDisconnectedError }

import from opentelemetry { trace }

import from pydantic { BaseModel }

glob logger: any;

glob _MALFORMED_TOOL_CALL_LIMIT: any;

glob _TOOL_CALLING_MODES: any;

glob _NATIVE_NO_TOOL_CALL: any;

glob _NATIVE_CONTINUE: any;

with entry {
    logger = logging.getLogger("mobilerun");

    _MALFORMED_TOOL_CALL_LIMIT = 3;
    _TOOL_CALLING_MODES = ("auto", "xml");
    _NATIVE_NO_TOOL_CALL = "No tool was called. Call one of the provided tools to continue. To mark the task as complete (whether it failed or succeeded), call the `complete` tool.";
    _NATIVE_CONTINUE = "The tool results are above. Continue with the next step.";
}

"""Build a focused retry instruction without echoing malformed model output."""
def _malformed_tool_call_correction(attempt: builtins.int) -> builtins.str;

"""Cut text at offset ``end`` of ``message.content``, keeping non-text blocks."""
def _truncate_message_text(message: ChatMessage, end: builtins.int) -> ChatMessage;

def _format_results(
    results: builtins.list[ToolResult], ignored_blocks: builtins.int
) -> builtins.str;

"""Agent that uses XML tool-calling instead of code generation.

    Uses ReAct cycle: Thought -> Tool Call -> Observation -> repeat until complete().
    Messages stored as list[ChatMessage] to preserve thinking tokens across turns.
    """
class FastAgent(Workflow) {
    def init(
        llm: LLM,
        agent_config: AgentConfig,
        registry: "ToolRegistry",
        action_ctx: "ActionContext",
        state_provider: "StateProvider",
        save_trajectory: builtins.str = "none",
        debug: builtins.bool = False,
        shared_state: Optional["MobileAgentState"] = None,
        output_model: Type[BaseModel] | None = None,
        prompt_resolver: Optional[PromptResolver] = None,
        tracing_config: TracingConfig | None = None,
        *args_,
        **kwargs,
    );

    """Build system prompt message."""
    async def _build_system_prompt -> ChatMessage;

    """Build initial user prompt message."""
    async def _build_user_prompt(goal: builtins.str) -> ChatMessage;

    """Initialize message history with goal."""
    @step
    async def prepare_chat(ctx: Context, ev: StartEvent) -> FastAgentInputEvent;

    """Get device state, call LLM, return response."""
    @step
    async def handle_llm_input(ctx: Context, ev: FastAgentInputEvent) -> FastAgentResponseEvent
        | FastAgentEndEvent;

    """Route to execution or request tool call if missing."""
    @step
    async def handle_llm_output(ctx: Context, ev: FastAgentResponseEvent) -> FastAgentToolCallEvent
        | FastAgentInputEvent
        | FastAgentEndEvent;

    """Execute parsed tool calls and return results."""
    @step
    async def execute_code(ctx: Context, ev: FastAgentToolCallEvent) -> FastAgentOutputEvent
        | FastAgentEndEvent;

    async def _store_native_results(
        ctx: Context, tool_calls: builtins.list, results: builtins.list[ToolResult]
    ) -> None;

    """Add execution result to history and loop back."""
    @step
    async def handle_execution_result(ctx: Context, ev: FastAgentOutputEvent) -> FastAgentInputEvent;

    @step
    async def finalize(ev: FastAgentEndEvent, ctx: Context) -> StopEvent;
}
