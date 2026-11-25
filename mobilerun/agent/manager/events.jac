"""
Events for the ManagerAgent workflow.

Internal events for streaming to frontend/logging.
For MobileAgent coordination events, see droid/events.py
"""

import builtins;

import from typing { Optional }

import from llama_index.core.workflow { Event }

"""Context prepared, ready for LLM call."""
class ManagerContextEvent(Event) {}

"""LLM response received, ready for parsing."""
class ManagerResponseEvent(Event) {
    has response: builtins.str;

    has usage: Optional[UsageResult] = None;
}

"""Plan parsed and ready (internal event with full details)."""
class ManagerPlanDetailsEvent(Event) {
    has plan: builtins.str;

    has subgoal: builtins.str;

    has thought: builtins.str;

    has answer: builtins.str = "";

    has memory_update: builtins.str = "";

    has progress_summary: builtins.str = "";

    has success: Optional[builtins.bool] = None;

    has full_response: builtins.str = "";
}
