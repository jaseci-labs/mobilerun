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
) -> None {
    import from mcp.client.session { ClientSession }
    import from mcp.client.stdio { stdio_client }

    try {
        async with AsyncExitStack() as stack {
            (read, write) = await stack.enter_async_context(stdio_client(server_params)) as any;
            session: any = await stack.enter_async_context(ClientSession(read, write));
            await session.initialize();
            ready.set_result(session);
            await shutdown.wait();
        }
    } except BaseException as e {
        if ready.done() {
            raise;
        }
        if isinstance(e, asyncio.CancelledError) {
            ready.cancel();
            raise;
        }
        ready.set_exception(e);
    }
}

"""Manages MCP server connections with lazy initialization."""
class MCPClientManager {
    has config: any,
        _tools: any,
        _server_tools: any,
        _sessions: any,
        _shutdown_events: any,
        _connection_tasks: any;

    def init(config: "MCPConfig") {
        self.config = config;
        self._tools = {};
        self._server_tools = {};
        self._sessions = {};
        self._shutdown_events = {};
        self._connection_tasks = {};
    }

    async def discover_tools -> dict[str, MCPToolInfo] {
        if not self.config.enabled {
            return {};
        }

        for (server_name, server_config) in self.config.servers.items() {
            if not server_config.enabled {
                continue;
            }
            try {
                (await self._discover_server_tools(server_name, server_config));
            } except Exception as e {
                logger.warning(f"MCP '{server_name}': discovery failed: {e}");
            }
        }

        if self._tools {
            logger.info(
                f"MCP: discovered {len(self._tools)} tools from {len(self._server_tools)} servers"
            );
        }
        return self._tools;
    }

    async def _discover_server_tools(server_name: str, config: "MCPServerConfig") -> None {
        import from mcp.client.session { ClientSession }
        import from mcp.client.stdio { StdioServerParameters, stdio_client }

        server_params: any = StdioServerParameters(
            command=config.command, args=config.args, env=config.env or None
        );

        server_tool_names: list[str] = [];

        async with (AsyncExitStack()) as stack {
            transport: any = (await stack.enter_async_context(stdio_client(server_params)));
            (read, write) = transport as any;
            session: any = (await stack.enter_async_context(ClientSession(read, write)));
            (await session.initialize());

            response: any = (await session.list_tools());
            prefix: any = config.prefix if config.prefix is not None else f"{server_name}_";

            for tool in response.tools {
                if not self._should_include_tool(tool.name, config) {
                    continue;
                }

                tool_name: any = f"{prefix}{tool.name}" if prefix else tool.name;
                self._tools[tool_name] = MCPToolInfo(
                    server_name=server_name,
                    original_name=tool.name,
                    description=tool.description or f"MCP tool: {tool.name}",
                    input_schema=tool.inputSchema,
                );
                server_tool_names.append(tool_name);
            }
        }

        self._server_tools[server_name] = server_tool_names;
        logger.debug(f"MCP '{server_name}': discovered {len(server_tool_names)} tools");
    }

    def _should_include_tool(tool_name: str, config: "MCPServerConfig") -> bool {
        if tool_name in config.exclude_tools {
            return False;
        }
        if config.include_tools is not None {
            return tool_name in config.include_tools;
        }
        return True;
    }

    async def call_tool(tool_name: str, arguments: dict) -> Any {
        if tool_name not in self._tools {
            raise ValueError(f"Unknown MCP tool: {tool_name}");
        }

        tool_info: any = self._tools[tool_name];
        server_name: any = tool_info.server_name;

        if server_name not in self._sessions {
            (await self._connect_server(server_name));
        }

        session: any = self._sessions[server_name];
        return (await session.call_tool(tool_info.original_name, arguments));
    }

    async def _connect_server(server_name: str) -> None {
        import from mcp.client.session { ClientSession }
        import from mcp.client.stdio { StdioServerParameters, stdio_client }

        config: any = self.config.servers[server_name];
        server_params: any = StdioServerParameters(
            command=config.command, args=config.args, env=config.env or None
        );

        logger.debug(f"MCP '{server_name}': connecting...");

        ready: asyncio.Future = asyncio.get_running_loop().create_future();
        shutdown: any = asyncio.Event();
        task: any = asyncio.create_task(
            _own_connection(server_params, ready, shutdown), name=f"mcp:{server_name}"
        );
        try {
            session: any = (await ready);
        } except BaseException {
            task.cancel();
            (await asyncio.gather(task, return_exceptions=True));
            raise;
        }

        self._sessions[server_name] = session;
        self._shutdown_events[server_name] = shutdown;
        self._connection_tasks[server_name] = task;
        logger.info(f"MCP '{server_name}': connected");
    }

    async def disconnect_all -> None {
        for shutdown in self._shutdown_events.values() {
            shutdown.set();
        }

        for (server_name, task) in `list(self._connection_tasks.items()) {
            try {
                (await task);
                logger.debug(f"MCP '{server_name}': disconnected");
            } except Exception as e {
                logger.warning(f"MCP '{server_name}': disconnect error: {e}");
            }
        }

        self._sessions.clear();
        self._shutdown_events.clear();
        self._connection_tasks.clear();
    }

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
