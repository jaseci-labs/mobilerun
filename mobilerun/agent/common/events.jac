import builtins;

import from typing { Any, Dict }

import from llama_index.core.workflow { Event }

class ScreenshotEvent(Event) {
    has screenshot: builtins.bytes;
}

class RecordUIStateEvent(Event) {
    has ui_state: builtins.list[Dict[builtins.str, Any]];
}

"""Emitted after every tool call dispatched through ToolRegistry."""
class ToolExecutionEvent(Event) {
    has tool_name: builtins.str;

    has tool_args: Dict[builtins.str, Any];

    has success: builtins.bool;

    has summary: builtins.str;
}
