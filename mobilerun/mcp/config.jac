import builtins;

import from dataclasses { dataclass, field }

import from typing { Dict, List, Optional }

"""Configuration for a single MCP server."""
@dataclass
class MCPServerConfig {
    has command: builtins.str = "";

    has args: List[builtins.str] = field(default_factory=list[any]);

    has env: Dict[builtins.str, builtins.str] = field(default_factory=dict[any, any]);

    has prefix: Optional[builtins.str] = None;

    has enabled: builtins.bool = True;

    has include_tools: Optional[List[builtins.str]] = None;

    has exclude_tools: List[builtins.str] = field(default_factory=list[any]);
}

"""MCP client configuration."""
@dataclass
class MCPConfig {
    has enabled: builtins.bool = False;

    has servers: Dict[builtins.str, MCPServerConfig] = field(default_factory=dict[any, any]);
}
