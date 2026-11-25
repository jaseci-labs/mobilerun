"""ActionContext — composed bag of dependencies for action functions.

Replaces the ``tools=tools_instance`` parameter that action functions
previously received.
"""

import builtins;

import from __future__ { annotations }

import from typing { TYPE_CHECKING, Optional }

"""Everything an action function needs to interact with the device."""
class ActionContext {
    has driver: any,
        ui: any,
        shared_state: any,
        state_provider: any,
        app_opener_llm: any,
        credential_manager: any,
        streaming: any,
        macro_recorder: any;

    def init(
        driver: "DeviceDriver",
        ui: "Optional[UIState]",
        shared_state: "MobileAgentState",
        state_provider: "StateProvider",
        app_opener_llm=None,
        credential_manager: "Optional[CredentialManager]" = None,
        streaming: bool = False,
        macro_recorder: "Optional[MacroRecorder]" = None,
    );
}
