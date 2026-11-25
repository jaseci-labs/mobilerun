glob _LEGACY_ALIASES: any = {"DroidAgent": MobileAgent, "DroidAgentState": MobileAgentState};

glob __all__: any;

def __getattr__(name) -> any;

with entry {
    __all__ = ["MobileAgent", "MobileAgentState", "DroidAgent", "DroidAgentState"];
}
