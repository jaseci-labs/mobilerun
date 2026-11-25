import importlib;

import builtins;

import from __future__ { annotations }

import inspect;

import json;

import logging;

import from dataclasses { dataclass }

import from typing { TYPE_CHECKING, Any, Callable, Dict, Optional, Set }

glob logger: any = logging.getLogger("mobilerun");

glob _JSON_SCHEMA_TYPES: any = {"string", "number", "integer", "boolean", "array", "object"};

def _json_schema_for_type(type_name: str) -> Dict[str, Any];

@dataclass
class ToolEntry {
    has fn: Callable;

    has params: Dict[str, Any];

    has description: str;

    has deps: Optional[Set[str]] = None;
}

"""Central registry of all agent-callable tools."""
class ToolRegistry {
    has tools: any;

    def init;

    def register(
        name: str,
        fn: Callable,
        params: Dict[str, Any],
        description: str,
        deps: Optional[Set[str]] = None,
    ) -> None;

    def register_from_dict(tools_dict: Dict[str, Any]) -> None;

    def disable(tool_names: list[str]) -> None;

    def disable_unsupported(capabilities: Set[str]) -> None;

    def get_signatures(exclude: Optional[Set[str]] = None) -> Dict[str, Any];

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

    def get_tool_descriptions_xml(exclude: Optional[Set[str]] = None) -> str;

    def get_function_tool_specs(exclude: Optional[Set[str]] = None) -> list[Dict[str, Any]];

    def get_tool_descriptions_text(exclude: Optional[Set[str]] = None) -> str;

    def get_param_types(exclude: Optional[Set[str]] = None) -> Dict[str, str];

    static def _format_params(parameters: Dict[str, Any]) -> str;

    static def _spec_to_json(name: str, `entry: ToolEntry) -> str;
}
