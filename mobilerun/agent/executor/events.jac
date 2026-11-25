import builtins;

import from typing { Dict, Optional }

import from llama_index.core.workflow { Event }

"""Context prepared, ready for LLM call."""
class ExecutorContextEvent(Event) {
    has subgoal: builtins.str;
}

"""LLM response received, ready for parsing."""
class ExecutorResponseEvent(Event) {
    has response: builtins.str;

    has usage: Optional[UsageResult] = None;
}

"""Action parsed, ready to execute."""
class ExecutorActionEvent(Event) {
    has action_json: builtins.str;

    has thought: builtins.str;

    has description: builtins.str;

    has full_response: builtins.str = "";
}

"""Action execution result (internal event with full details)."""
class ExecutorActionResultEvent(Event) {
    has action: Dict;

    has success: builtins.bool;

    has error: builtins.str;

    has summary: builtins.str;

    has thought: builtins.str = "";

    has full_response: builtins.str = "";
}
