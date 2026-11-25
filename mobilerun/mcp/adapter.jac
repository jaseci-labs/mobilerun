import from __future__ { annotations }

import functools;

import from typing { Any }

def schema_to_parameters(input_schema: dict) -> dict[str, dict[str, Any]] {
    properties: any = input_schema.get("properties", {});
    required: any = `set(input_schema.get("required", []));

    parameters: dict[str, dict[str, Any]] = {};
    for (prop_name, prop_info) in properties.items() {
        param: dict[str, Any] = {
            "type": prop_info.get("type", "string"),
            "required": prop_name in required,
        };
        if "default" in prop_info {
            param["default"] = prop_info["default"];
        }
        if "description" in prop_info {
            param["description"] = prop_info["description"];
        }
        parameters[prop_name] = param;
    }

    return parameters;
}

def mcp_to_mobilerun_tools(mcp_manager: "MCPClientManager") -> dict[str, dict[str, Any]] {
    custom_tools: dict[str, dict[str, Any]] = {};

    for (tool_name, tool_info) in mcp_manager.tools.items() {
        wrapper: any = _create_tool_wrapper(tool_name, mcp_manager);
        custom_tools[tool_name] = {
            "parameters": schema_to_parameters(tool_info.input_schema),
            "description": tool_info.description,
            "function": wrapper,
        };
    }

    return custom_tools;
}

async def _call_mcp_tool(
    tool_name: str, manager: "MCPClientManager", *, ctx=None, **kwargs
) -> str {
    result: any = await manager.call_tool(tool_name, kwargs);

    if hasattr(result, "content") and result.content {
        text_parts: any = [];
        for block in result.content {
            if hasattr(block, "text") and block.text {
                text_parts.append(block.text);
            }
        }
        if text_parts {
            return "\n".join(text_parts);
        }
    }

    return `str(result);
}

def _create_tool_wrapper(tool_name: str, manager: "MCPClientManager") -> any {
    mcp_tool_wrapper: any = functools.partial(_call_mcp_tool, tool_name, manager);
    mcp_tool_wrapper.__name__ = f"mcp_{tool_name}";
    return mcp_tool_wrapper;
}

glob mcp_to_droidrun_tools: any;

with entry {
    mcp_to_droidrun_tools = mcp_to_mobilerun_tools;
}
