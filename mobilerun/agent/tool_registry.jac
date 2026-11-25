import importlib;

import builtins;

import from __future__ { annotations }

import inspect;

import json;

import logging;

import from dataclasses { dataclass }

import from typing { Any, Callable, Dict, Optional, Set }

glob logger: any = logging.getLogger("mobilerun");

glob _JSON_SCHEMA_TYPES: any = {"string", "number", "integer", "boolean", "array", "object"};

def _json_schema_for_type(type_name: str) -> Dict[str, Any] {
    if type_name in ("list", "array") {
        return {"type": "array", "items": {}};
    }
    if type_name in _JSON_SCHEMA_TYPES {
        return {"type": type_name};
    }
    return {};
}

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

    def init {
        self.tools = {};
    }

    def register(
        name: str,
        fn: Callable,
        params: Dict[str, Any],
        description: str,
        deps: Optional[Set[str]] = None,
    ) -> None {
        self.tools[name] = ToolEntry(fn=fn, params=params, description=description, deps=deps);
    }

    def register_from_dict(tools_dict: Dict[str, Any]) -> None {
        for (name, spec) in tools_dict.items() {
            deps: any = spec.get("deps");
            if deps is not None {
                deps = `set(deps);
            }
            self.register(
                name=name,
                fn=spec["function"],
                params=spec.get("parameters", {}),
                description=spec.get("description", f"Tool: {name}"),
                deps=deps,
            );
        }
    }

    def disable(tool_names: list[str]) -> None {
        for name in tool_names {
            self.tools.pop(name, None);
        }
    }

    def disable_unsupported(capabilities: Set[str]) -> None {
        to_remove: any = [
            name
            for (name, `entry) in self.tools.items()
            if `entry.deps is not None and not `entry.deps <= capabilities
        ];
        if to_remove {
            logger.debug(f"Disabling unsupported tools: {to_remove}");
        }
        self.disable(to_remove);
    }

    def get_signatures(exclude: Optional[Set[str]] = None) -> Dict[str, Any] {
        exclude = exclude or set[any]();
        return {
            name: {"parameters": `entry.params, "description": `entry.description}
            for (name, `entry) in self.tools.items()
            if name not in exclude
        };
    }

    async def execute(
        name: str,
        args: Dict[str, Any],
        ctx: "ActionContext",
        workflow_ctx: "Optional[WorkflowContext]" = None,
    ) -> ActionResult {
        if name not in self.tools {
            result: any = ActionResult(
                success=False,
                summary=f"Unknown tool: {name}. Available: {`list(self.tools.keys())}",
            );
            self._emit_event(workflow_ctx, name, args, result);
            return result;
        }

        `entry: any = self.tools[name];
        try {
            if inspect.iscoroutinefunction(`entry.fn) {
                result = (await `entry.fn(**args, ctx=ctx));
            } else {
                result = `entry.fn(**args, ctx=ctx);
            }
        } except TypeError as e {
            result = ActionResult(success=False, summary=f"Invalid arguments for {name}: {e}");
            self._emit_event(workflow_ctx, name, args, result);
            return result;
        } except Exception as e {
            result = ActionResult(
                success=False, summary=f"Failed to execute {name}: {describe_error(e)}"
            );
            self._emit_event(workflow_ctx, name, args, result);
            return result;
        }
        if isinstance(result, ActionResult) {
            action_result: any = result;
        } elif isinstance(result, `tuple) {
            action_result = ActionResult(success=result[0], summary=`str(result[1]));
        } elif isinstance(result, `str) {
            success: any = not result.startswith("Failed");
            action_result = ActionResult(success=success, summary=result);
        } else {
            action_result = ActionResult(success=True, summary=`str(result) if result else "Done");
        }

        self._emit_event(workflow_ctx, name, args, action_result);
        return action_result;
    }

    static def _emit_event(
        workflow_ctx: "Optional[WorkflowContext]",
        name: str,
        args: Dict[str, Any],
        result: ActionResult,
    ) -> None {
        if workflow_ctx is None {
            return;
        }
        ToolExecutionEvent: any = importlib.import_module(
            "mobilerun.agent.common.events"
        ).ToolExecutionEvent;

        workflow_ctx.write_event_to_stream(
            ToolExecutionEvent(
                tool_name=name, tool_args=args, success=result.success, summary=result.summary
            ),
        );
    }

    def get_tool_descriptions_xml(exclude: Optional[Set[str]] = None) -> str {
        exclude = exclude or set[any]();
        lines: any = ["<functions>"];
        for (name, `entry) in self.tools.items() {
            if name in exclude {
                continue;
            }
            lines.append(f"<function>{self._spec_to_json(name, `entry)}</function>");
        }
        lines.append("</functions>");
        return "\n".join(lines);
    }

    def get_function_tool_specs(exclude: Optional[Set[str]] = None) -> list[Dict[str, Any]] {
        exclude = exclude or set[any]();
        specs: any = [];
        for (name, `entry) in self.tools.items() {
            if name in exclude {
                continue;
            }
            properties: any = {};
            required: any = [];
            for (param_name, param_info) in `entry.params.items() {
                schema: any = _json_schema_for_type(param_info.get("type", "string"));
                if param_info.get("description") {
                    schema["description"] = param_info["description"];
                }
                properties[param_name] = schema;
                if param_info.get("required", True) {
                    required.append(param_name);
                }
            }
            specs.append({
                "type": "function",
                "name": name,
                "description": `entry.description,
                "parameters": {"type": "object", "properties": properties, "required": required},
                "strict": False,
            });
        }
        return specs;
    }

    def get_tool_descriptions_text(exclude: Optional[Set[str]] = None) -> str {
        exclude = exclude or set[any]();
        descriptions: any = [];
        for (name, `entry) in self.tools.items() {
            if name in exclude {
                continue;
            }
            params: any = self._format_params(`entry.params);
            descriptions.append(f"- {name}({params}): {`entry.description}");
        }
        return "\n".join(descriptions);
    }

    def get_param_types(exclude: Optional[Set[str]] = None) -> Dict[str, str] {
        exclude = exclude or set[any]();
        param_types: Dict[str, str] = {};
        for (name, `entry) in self.tools.items() {
            if name in exclude {
                continue;
            }
            for (param_name, param_info) in `entry.params.items() {
                param_types[param_name] = param_info.get("type", "string");
            }
        }
        return param_types;
    }

    static def _format_params(parameters: Dict[str, Any]) -> str {
        parts: any = [];
        for (name, info) in parameters.items() {
            type_str: any = info.get("type", "string");
            if info.get("required", True) {
                parts.append(f"{name}: {type_str}");
            } else {
                `default: any = info.get("default", "None");
                parts.append(f"{name}: {type_str} = {`default}");
            }
        }
        return ", ".join(parts);
    }

    static def _spec_to_json(name: str, `entry: ToolEntry) -> str {
        parameters: any = `entry.params;
        properties: any = {};
        required: any = [];
        for (param_name, param_info) in parameters.items() {
            properties[param_name] = {"type": param_info.get("type", "string")};
            if param_info.get("description") {
                properties[param_name]["description"] = param_info["description"];
            }
            if param_info.get("required", True) {
                required.append(param_name);
            }
            if "default" in param_info {
                properties[param_name]["default"] = param_info["default"];
            }
        }

        tool_dict: any = {
            "name": name,
            "description": `entry.description,
            "parameters": {"type": "object", "properties": properties, "required": required},
        };
        return json.dumps(tool_dict, separators=(",", ":"));
    }
}
