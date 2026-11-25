"""
Mobilerun Agent Module.

This module provides a ReAct agent for automating Android devices using reasoning and acting.
"""

glob _LEGACY_ALIASES: any;

glob __all__: any;

with entry {
    _LEGACY_ALIASES = {"DroidAgent": MobileAgent, "DroidAgentState": MobileAgentState};
}

def __getattr__(name) -> any;

with entry {
    __all__ = ["MobileAgent", "MobileAgentState", "DroidAgent", "DroidAgentState"];
}
