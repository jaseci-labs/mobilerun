"""Native function-calling support for FastAgent.

Converts provider tool-call blocks into the same ToolCall objects the XML
protocol produces, and builds the tool-result messages that answer them.
"""

import builtins;

import json;

import from typing { Any, Dict, List, Optional }

import from llama_index.core.base.llms.types { ChatMessage, ToolCallBlock }

"""Build the request arguments that send tools to the LLM."""
def native_tool_kwargs(
    llm: Any, specs: List[Dict[builtins.str, Any]], parallel: builtins.bool
) -> Dict[builtins.str, Any];

"""Split a native tool-calling response into its text and tool calls."""
def parse_native_tool_calls(
    message: ChatMessage, param_types: Optional[Dict[builtins.str, builtins.str]] = None
) -> ToolCallParseResult;

"""Answer every native tool call; calls without a result were not run."""
def tool_result_messages(calls: List[ToolCall], results: List[ToolResult]) -> List[ChatMessage];

def _to_tool_call(
    block: ToolCallBlock, param_types: Optional[Dict[builtins.str, builtins.str]]
) -> ToolCall;
