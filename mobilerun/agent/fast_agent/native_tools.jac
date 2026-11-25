import builtins;

import json;

import from typing { Any, Dict, List, Optional }

import from llama_index.core.base.llms.types { ChatMessage, ToolCallBlock }

def native_tool_kwargs(
    llm: Any, specs: List[Dict[builtins.str, Any]], parallel: builtins.bool
) -> Dict[builtins.str, Any];

def parse_native_tool_calls(
    message: ChatMessage, param_types: Optional[Dict[builtins.str, builtins.str]] = None
) -> ToolCallParseResult;

def tool_result_messages(calls: List[ToolCall], results: List[ToolResult]) -> List[ChatMessage];

def _to_tool_call(
    block: ToolCallBlock, param_types: Optional[Dict[builtins.str, builtins.str]]
) -> ToolCall;
