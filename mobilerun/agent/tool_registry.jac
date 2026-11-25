"""ToolRegistry — single source of truth for available tools.

Central registry for agent-callable tools.
"""

import importlib;

import builtins;

import from __future__ { annotations }

import inspect;

import json;

import logging;

import from dataclasses { dataclass }

import from typing { TYPE_CHECKING, Any, Callable, Dict, Optional, Set }

glob logger: any;

glob _JSON_SCHEMA_TYPES: any;

with entry {
    logger = logging.getLogger("mobilerun");

    _JSON_SCHEMA_TYPES = {"string", "number", "integer", "boolean", "array", "object"};
}

"""Map a registry parameter type to a JSON Schema fragment."""
def _json_schema_for_type(type_name: str) -> Dict[str, Any];

@dataclass
class ToolEntry {
    has fn: Callable;

    has params: Dict[str, Any];

    has description: str;

    has deps: Optional[Set[str]] = None;
}

"""Central registry of all agent-callable tools."""
obj ToolRegistry {
    has tools: any;

    def init;

    def register(
        name: str,
        fn: Callable,
        params: Dict[str, Any],
        description: str,
        deps: Optional[Set[str]] = None,
    ) -> None;

    """Register tools from the existing ``{name: {parameters, description, function}}`` format."""
    def register_from_dict(tools_dict: Dict[str, Any]) -> None;

    """Remove tools by name (silently ignores unknown names)."""
    def disable(tool_names: list[str]) -> None;

    """Remove tools whose ``deps`` set is not satisfied by *capabilities*.

        Tools with ``deps=None`` (custom tools, MCP tools, etc.) are kept.
        """
    def disable_unsupported(capabilities: Set[str]) -> None;

    """Return ``{name: {parameters, description}}`` for prompt building.

        Args:
            exclude: Optional set of tool names to omit.  Used by
                     ExecutorAgent to hide flow-control tools (e.g.
                     complete) that only FastAgent should see.
        """
    def get_signatures(exclude: Optional[Set[str]] = None) -> Dict[str, Any];

    """Dispatch action by name.

        All actions receive ``ctx=ctx`` as a keyword argument.

        Args:
            workflow_ctx: Optional llama-index workflow Context. When provided,
                a ``ToolExecutionEvent`` is streamed after execution.

        Handles:
        - Unknown tool names
        - Sync vs async functions
        - TypeError (bad arguments)
        - General exceptions
        """
    async def execute(
        name: str,
        args: Dict[str, Any],
        ctx: "ActionContext",
        workflow_ctx: "Optional[WorkflowContext]" = None,
    ) -> ActionResult;

    static def _emit_event(
        workflow_ctx: "Optional[WorkflowContext]",
        name: str,
        args: Dict[str, Any],
        result: ActionResult,
    ) -> None;

    """Build XML ``<functions>`` block for FastAgent system prompt."""
    def get_tool_descriptions_xml(exclude: Optional[Set[str]] = None) -> str;

    """Build OpenAI Responses function tools for native tool calling."""
    def get_function_tool_specs(exclude: Optional[Set[str]] = None) -> list[Dict[str, Any]];

    """Build text tool descriptions for executor prompts."""
    def get_tool_descriptions_text(exclude: Optional[Set[str]] = None) -> str;

    """Build a flat ``{param_name: type_string}`` map for XML coercion.

        Note: parameter names are global (not per-tool).
        """
    def get_param_types(exclude: Optional[Set[str]] = None) -> Dict[str, str];

    static def _format_params(parameters: Dict[str, Any]) -> str;

    static def _spec_to_json(name: str, `entry: ToolEntry) -> str;

    def __repr__ -> str;

    def __eq__(other: any) -> bool;

    def __hash__ -> int;
}
