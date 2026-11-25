import builtins;

import from typing { Dict, Optional }

import from pydantic { BaseModel }

"""Base class for all telemetry events."""
class TelemetryEvent(BaseModel) {}

"""Event captured when MobileAgent is initialized."""
class MobileAgentInitEvent(TelemetryEvent) {
    has goal: builtins.str;

    has llms: Dict[builtins.str, builtins.str];

    has tools: builtins.str;

    has max_steps: builtins.int;

    has timeout: builtins.int;

    has vision: Dict[builtins.str, builtins.bool];

    has reasoning: builtins.bool;

    has enable_tracing: builtins.bool;

    has debug: builtins.bool;

    has save_trajectories: builtins.str = "none";

    has runtype: builtins.str = "developer";

    has custom_prompts: Optional[Dict[builtins.str, builtins.str]] = None;
}

"""Event captured when agent visits a new app package."""
class PackageVisitEvent(TelemetryEvent) {
    has package_name: builtins.str;

    has activity_name: builtins.str;

    has step_number: builtins.int;
}

"""Event captured when MobileAgent execution completes."""
class MobileAgentFinalizeEvent(TelemetryEvent) {
    has success: builtins.bool;

    has reason: builtins.str;

    has steps: builtins.int;

    has unique_packages_count: builtins.int;

    has unique_activities_count: builtins.int;
}

glob DroidAgentInitEvent: any;

glob DroidAgentFinalizeEvent: any;

with entry {
    DroidAgentInitEvent = MobileAgentInitEvent;
    DroidAgentFinalizeEvent = MobileAgentFinalizeEvent;
}
