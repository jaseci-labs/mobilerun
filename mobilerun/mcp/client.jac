"""MCP Client Manager - handles connections to MCP servers."""

import builtins;

import from __future__ { annotations }

import decimal as _jacm;

import asyncio;

import logging;

import from contextlib { AsyncExitStack }

import from dataclasses { dataclass }

import from typing { TYPE_CHECKING, Any }

glob logger: any;

with entry {
    logger = logging.getLogger("mobilerun");
}

"""Cached metadata about an MCP tool."""
@dataclass
class MCPToolInfo {
    has server_name: str;

    has original_name: str;

    has description: str;

    has input_schema: dict;
}

"""Open one server's transport and hold it until shutdown is signalled."""
async def _own_connection(
    server_params: Any, ready: asyncio.Future, shutdown: asyncio.Event
) -> None;

"""Manages MCP server connections with lazy initialization."""
obj MCPClientManager {
    has config: any,
        _tools: any,
        _server_tools: any,
        _sessions: any,
        _shutdown_events: any,
        _connection_tasks: any;

    def init(config: "MCPConfig");

    """Discover tools from all configured servers."""
    def discover_tools -> dict[str, MCPToolInfo];

    """Connect temporarily to fetch tool schemas."""
    def _discover_server_tools(server_name: str, config: "MCPServerConfig") -> None;

    """Check if tool passes include/exclude filters."""
    def _should_include_tool(tool_name: str, config: "MCPServerConfig") -> bool;

    """Call an MCP tool, connecting lazily if needed."""
    def call_tool(tool_name: str, arguments: dict) -> Any;

    """Establish persistent connection to a server."""
    def _connect_server(server_name: str) -> None;

    """Clean up all server connections."""
    def disconnect_all -> None;

    has tools: dict[str, MCPToolInfo] {
        getter {
            return self._tools;
        }
    }

    has connected_servers: list[str] {
        getter {
            return `list(self._sessions.keys());
        }
    }

    def __repr__ -> str;

    def __eq__(other: any) -> bool;

    def __hash__ -> int;
}
