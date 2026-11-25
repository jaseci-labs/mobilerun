import builtins;

import operator;

import importlib;

import asyncio;

import logging;

import time;

import from typing { Any, Dict, Optional }

import from mobilerun_core_local.driver.android { AndroidDriver }

glob logger: any = logging.getLogger("mobilerun-macro");

glob _KEYCODE_TO_BUTTON: any = {4: "back", 3: "home", 66: "enter"};

"""
    A class for loading and replaying Mobilerun macro sequences.

    This player can execute recorded UI actions (taps, swipes, text input, key presses)
    on Android devices using AndroidDriver.
    """
class MacroPlayer {
    has device_serial: any,
        delay_between_actions: any,
        on_mismatch: any,
        state_timeout: any,
        state_threshold: any,
        state_poll_interval: any,
        handoff_runner: any,
        provider: any,
        model: any,
        config_path: any,
        last_divergence: any,
        state_provider: any,
        driver: any,
        credential_manager: any,
        _credential_load_error: any;

    def init(
        device_serial: builtins.str = None,
        delay_between_actions: builtins.float = 1.0,
        on_mismatch: builtins.str = "stop",
        state_timeout: builtins.float = 5.0,
        state_threshold: builtins.float = 0.85,
        state_poll_interval: builtins.float = 0.5,
        handoff_runner=None,
        provider: Optional[builtins.str] = None,
        model: Optional[builtins.str] = None,
        config_path: Optional[builtins.str] = None,
    );

    async def _initialize_driver -> AndroidDriver;

    def load_macro_from_file(macro_file_path: builtins.str) -> Dict[builtins.str, Any];

    def load_macro_from_folder(trajectory_folder: builtins.str) -> Dict[builtins.str, Any];

    def _load_credential_manager -> any;

    async def get_current_state_snapshot -> Dict[builtins.str, Any];

    async def wait_for_pre_state(
        pre_state: Optional[Dict[builtins.str, Any]], step_number: builtins.int
    ) -> builtins.tuple[builtins.bool, Optional[Dict[builtins.str, Any]], Optional[StateMatchResult]];

    async def replay_action(
        action: Dict[builtins.str, Any], current_state: Optional[Dict[builtins.str, Any]] = None
    ) -> builtins.bool;

    async def replay_macro(
        macro_data: Dict[builtins.str, Any],
        start_from_step: builtins.int = 0,
        max_steps: Optional[builtins.int] = None,
    ) -> builtins.bool;
}

async def replay_macro_file(
    macro_file_path: builtins.str,
    device_serial: builtins.str = None,
    delay_between_actions: builtins.float = 1.0,
    start_from_step: builtins.int = 0,
    max_steps: Optional[builtins.int] = None,
    on_mismatch: builtins.str = "stop",
    state_timeout: builtins.float = 5.0,
    state_threshold: builtins.float = 0.85,
) -> builtins.bool;

async def replay_macro_folder(
    trajectory_folder: builtins.str,
    device_serial: builtins.str = None,
    delay_between_actions: builtins.float = 1.0,
    start_from_step: builtins.int = 0,
    max_steps: Optional[builtins.int] = None,
    on_mismatch: builtins.str = "stop",
    state_timeout: builtins.float = 5.0,
    state_threshold: builtins.float = 0.85,
) -> builtins.bool;
