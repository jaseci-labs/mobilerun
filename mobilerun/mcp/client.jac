import builtins;

import from __future__ { annotations }

import asyncio;

import logging;

import from contextlib { AsyncExitStack }

import from dataclasses { dataclass }

import from typing { Any }

glob logger: any = logging.getLogger("mobilerun");

"""Cached metadata about an MCP tool."""
@dataclass
class MCPToolInfo {
    has server_name: str;

    has original_name: str;

    has description: str;

    has input_schema: dict;
}

async def _own_connection(
    server_params: Any, ready: asyncio.Future, shutdown: asyncio.Event
) -> None;

"""Manages MCP server connections with lazy initialization."""
class MCPClientManager {
    has config: any,
        _tools: any,
        _server_tools: any,
        _sessions: any,
        _shutdown_events: any,
        _connection_tasks: any;

    def init(config: "MCPConfig");

    async def discover_tools -> dict[str, MCPToolInfo];

    async def _discover_server_tools(server_name: str, config: "MCPServerConfig") -> None;

    def _should_include_tool(tool_name: str, config: "MCPServerConfig") -> bool;

    async def call_tool(tool_name: str, arguments: dict) -> Any;

    async def _connect_server(server_name: str) -> None;

    async def disconnect_all -> None;

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
}
