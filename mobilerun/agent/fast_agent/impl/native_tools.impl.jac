impl native_tool_kwargs(
    llm: Any, specs: List[Dict[builtins.str, Any]], parallel: builtins.bool
) -> Dict[builtins.str, Any] {
    if getattr(llm, "native_tool_api", "responses") == "chat_completions" {
        return {
            "tools": [
                {
                    "type": "function",
                    "function": {
                        "name": spec["name"],
                        "description": spec["description"],
                        "parameters": spec["parameters"],
                    },
                }
                for spec in specs
            ],
            "tool_choice": "auto",
            "parallel_tool_calls": parallel,
        };
    }
    return {"tools": specs, "tool_choice": "required", "parallel_tool_calls": parallel};
}

impl parse_native_tool_calls(
    message: ChatMessage, param_types: Optional[Dict[builtins.str, builtins.str]] = None
) -> ToolCallParseResult {
    calls: any = [
        _to_tool_call(block, param_types)
        for block in message.blocks
        if isinstance(block, ToolCallBlock)
    ];
    return ToolCallParseResult(
        thought=(message.content or "").strip(),
        calls=calls,
        status=ToolCallParseStatus.VALID if calls else ToolCallParseStatus.NO_MARKUP,
    );
}

impl tool_result_messages(calls: List[ToolCall], results: List[ToolResult]) -> List[ChatMessage] {
    messages: any = [];
    for (index, call) in enumerate(calls) {
        if index < len(results) {
            result: any = results[index];
            output: any = f"Error: {result.output}" if result.is_error else result.output;
        } else {
            output = "Error: Not executed.";
        }
        messages.append(
            ChatMessage(
                role="tool",
                content=output or "Done",
                additional_kwargs={"tool_call_id": call.call_id},
            ),
        );
    }
    return messages;
}

impl _to_tool_call(
    block: ToolCallBlock, param_types: Optional[Dict[builtins.str, builtins.str]]
) -> ToolCall {
    name: any = block.tool_name;
    call_id: any = block.tool_call_id;
    arguments: Any = block.tool_kwargs;
    if isinstance(arguments, `str) {
        try {
            arguments = json.loads(arguments) if arguments.strip() else {};
        } except json.JSONDecodeError {
            return ToolCall(name=name, error="arguments are not valid JSON", call_id=call_id);
        }
    }
    if not isinstance(arguments, `dict) {
        return ToolCall(name=name, error="arguments must be a JSON object", call_id=call_id);
    }

    parameters: Dict[builtins.str, Any] = {};
    value: any;
    for (param_name, value) in arguments.items() {
        if isinstance(value, `str) and param_types {
            if param_types.get(param_name, "string") != "string" {
                try {
                    value = _coerce_param(param_name, value, param_types);
                } except ValueError as e {
                    return ToolCall(
                        name=name, parameters=parameters, error=`str(e), call_id=call_id
                    );
                }
            }
        }
        parameters[param_name] = value;
    }
    return ToolCall(name=name, parameters=parameters, call_id=call_id);
}
