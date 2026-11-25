import from __future__ { annotations }

import functools;

import from typing { Any }

def schema_to_parameters(input_schema: dict) -> dict[str, dict[str, Any]];

def mcp_to_mobilerun_tools(mcp_manager: "MCPClientManager") -> dict[str, dict[str, Any]];

async def _call_mcp_tool(tool_name: str, manager: "MCPClientManager", *, ctx=None, **kwargs) -> str;

def _create_tool_wrapper(tool_name: str, manager: "MCPClientManager") -> any;

glob mcp_to_droidrun_tools: any;

with entry {
    mcp_to_droidrun_tools = mcp_to_mobilerun_tools;
}
