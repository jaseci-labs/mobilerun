"""
Macro Replay Module - Replay recorded UI automation sequences.

This module provides functionality to load and replay macro JSON files
that were generated during MobileAgent trajectory recording.
"""

import builtins;

import operator;

import importlib;

import asyncio;

import logging;

import time;

import from typing { Any, Dict, Optional }

import from mobilerun_core_local.driver.android { AndroidDriver }

glob logger: any;

glob _KEYCODE_TO_BUTTON: any;

with entry {
    logger = logging.getLogger("mobilerun-macro");
    _KEYCODE_TO_BUTTON = {4: "back", 3: "home", 66: "enter"};
}

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

    """
        Initialize the MacroPlayer.

        Args:
            device_serial: Serial number of the target device. If None, uses ANDROID_SERIAL or the only connected device.
            delay_between_actions: Delay in seconds between each action (default: 1.0s)
        """
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

    """Initialize AndroidDriver for the target device."""
    async def _initialize_driver -> AndroidDriver;

    """
        Load macro data from a JSON file.

        Args:
            macro_file_path: Path to the macro JSON file

        Returns:
            Dictionary containing the macro data
        """
    def load_macro_from_file(macro_file_path: builtins.str) -> Dict[builtins.str, Any];

    """
        Load macro data from a trajectory folder.

        Args:
            trajectory_folder: Path to the trajectory folder containing macro.json

        Returns:
            Dictionary containing the macro data
        """
    def load_macro_from_folder(trajectory_folder: builtins.str) -> Dict[builtins.str, Any];

    def _load_credential_manager -> any;

    async def get_current_state_snapshot -> Dict[builtins.str, Any];

    async def wait_for_pre_state(
        pre_state: Optional[Dict[builtins.str, Any]], step_number: builtins.int
    ) -> builtins.tuple[builtins.bool, Optional[Dict[builtins.str, Any]], Optional[StateMatchResult]];

    """
        Replay a single action.

        Args:
            action: Action dictionary containing type and parameters

        Returns:
            True if action was executed successfully, False otherwise
        """
    async def replay_action(
        action: Dict[builtins.str, Any], current_state: Optional[Dict[builtins.str, Any]] = None
    ) -> builtins.bool;

    """
        Replay a complete macro sequence.

        Args:
            macro_data: Macro data dictionary loaded from JSON
            start_from_step: Step number to start from (0-based, default: 0)
            max_steps: Maximum number of steps to execute (default: all)

        Returns:
            True if all actions were executed successfully, False otherwise
        """
    async def replay_macro(
        macro_data: Dict[builtins.str, Any],
        start_from_step: builtins.int = 0,
        max_steps: Optional[builtins.int] = None,
    ) -> builtins.bool;
}

"""
    Convenience function to replay a macro from a file.

    Args:
        macro_file_path: Path to the macro JSON file
        device_serial: Target device serial (optional)
        delay_between_actions: Delay between actions in seconds
        start_from_step: Step to start from (0-based)
        max_steps: Maximum steps to execute

    Returns:
        True if replay was successful, False otherwise
    """
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

"""
    Convenience function to replay a macro from a trajectory folder.

    Args:
        trajectory_folder: Path to the trajectory folder containing macro.json
        device_serial: Target device serial (optional)
        delay_between_actions: Delay between actions in seconds
        start_from_step: Step to start from (0-based)
        max_steps: Maximum steps to execute

    Returns:
        True if replay was successful, False otherwise
    """
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
