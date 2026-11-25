"""Adapter to convert MCP tools to Mobilerun custom tool format."""

import from __future__ { annotations }

import functools;

import from typing { TYPE_CHECKING, Any }

"""Convert JSON Schema properties to Mobilerun parameters format.

    Args:
        input_schema: JSON Schema with "properties" and "required" fields.

    Returns:
        Dict mapping param name to {"type": ..., "required": ..., "default": ...}.
    """
def schema_to_parameters(input_schema: dict) -> dict[str, dict[str, Any]];

"""Convert discovered MCP tools to Mobilerun custom tool format."""
def mcp_to_mobilerun_tools(mcp_manager: "MCPClientManager") -> dict[str, dict[str, Any]];

async def _call_mcp_tool(tool_name: str, manager: "MCPClientManager", *, ctx=None, **kwargs) -> str;

"""Create async wrapper function for an MCP tool."""
def _create_tool_wrapper(tool_name: str, manager: "MCPClientManager") -> any;

glob mcp_to_droidrun_tools: any;

with entry {
    mcp_to_droidrun_tools = mcp_to_mobilerun_tools;
}
