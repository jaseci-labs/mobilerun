"""
MobileAgent coordination events.

These events route between MobileAgent and child agents.
For internal agent events, see each agent's events.py file.
"""

import builtins;

import from typing { Dict, List, Optional }

import from llama_index.core.workflow { Event, StopEvent }

import from pydantic { BaseModel }

class FastAgentExecuteEvent(Event) {
    has instruction: builtins.str;
}

class FastAgentResultEvent(Event) {
    has success: builtins.bool;

    has reason: builtins.str;

    has instruction: builtins.str;
}

"""Trigger Manager workflow for planning"""
class ManagerInputEvent(Event) {}

"""
    Coordination event from ManagerAgent to MobileAgent.

    Used for workflow step routing only (NOT streamed to frontend).
    For internal events with memory_update metadata, see ManagerPlanDetailsEvent.
    """
class ManagerPlanEvent(Event) {
    has plan: builtins.str;

    has current_subgoal: builtins.str;

    has thought: builtins.str;

    has answer: builtins.str = "";

    has success: Optional[builtins.bool] = None;
}

"""Trigger Executor workflow for action execution"""
class ExecutorInputEvent(Event) {
    has current_subgoal: builtins.str;
}

"""Executor finished with action result."""
class ExecutorResultEvent(Event) {
    has action: Dict;

    has outcome: builtins.bool;

    has error: builtins.str;

    has summary: builtins.str;
}

class ExternalUserMessageAppliedEvent(Event) {
    has message_ids: List[builtins.str];

    has consumer: builtins.str;

    has step_number: builtins.int;
}

class ExternalUserMessageDroppedEvent(Event) {
    has message_ids: List[builtins.str];

    has reason: builtins.str;

    has step_number: builtins.int;
}

"""Trigger finalization."""
class FinalizeEvent(Event) {
    has success: builtins.bool;

    has reason: builtins.str;
}

"""
    Final result from MobileAgent.

    Returned by MobileAgent.run() with:
    - success: Whether the task completed successfully
    - reason: Explanation or answer
    - steps: Number of steps taken
    - structured_output: Extracted structured data (if output_model was provided)
    """
class ResultEvent(StopEvent) {
    has success: builtins.bool;

    has reason: builtins.str;

    has steps: builtins.int;

    has structured_output: Optional[BaseModel] = None;
}
