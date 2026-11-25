import builtins;

import from typing { Optional }

import from llama_index.core.workflow { Event }

"""Input ready for LLM."""
class FastAgentInputEvent(Event) {}

"""LLM response received."""
class FastAgentResponseEvent(Event) {
    has thought: builtins.str;

    has code: Optional[builtins.str] = None;

    has usage: Optional[UsageResult] = None;

    has tool_call_status: ToolCallParseStatus = ToolCallParseStatus.NO_MARKUP;
}

"""Tool calls ready to execute."""
class FastAgentToolCallEvent(Event) {
    has tool_calls_repr: builtins.str;
}

"""Tool execution result."""
class FastAgentOutputEvent(Event) {
    has output: builtins.str;
}

"""FastAgent finished."""
class FastAgentEndEvent(Event) {
    has success: builtins.bool;

    has reason: builtins.str;

    has tool_call_count: builtins.int = 0;
}
