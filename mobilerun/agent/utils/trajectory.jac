import builtins;

import json;

import logging;

import os;

import time;

import uuid;

import from typing { Any, Dict, List }

import from llama_index.core.workflow { Event }

glob logger: any = logging.getLogger("mobilerun");

class Trajectory {
    has events: any,
        screenshot_count: any,
        screenshot_queue: any,
        ui_states: any,
        macro: any,
        goal: any,
        base_path: any,
        trajectory_folder: any;

    def init(goal: builtins.str = None, base_path: builtins.str = "trajectories");

    def _resolve_path(config_path: builtins.str) -> any;

    def _create_trajectory_folder -> any;

    def set_goal(goal: builtins.str) -> None;

    def get_trajectory -> List[Dict[builtins.str, Any]];

    static def load_trajectory_folder(trajectory_folder: builtins.str) -> Dict[builtins.str, Any];

    static def load_macro_sequence(macro_file_path: builtins.str) -> Dict[builtins.str, Any];

    static def get_macro_summary(macro_data: Dict[builtins.str, Any]) -> Dict[builtins.str, Any];

    static def print_macro_summary(macro_file_path: builtins.str) -> None;

    static def print_trajectory_folder_summary(trajectory_folder: builtins.str) -> None;

    def print_trajectory_summary(trajectory_data: Dict[builtins.str, Any]) -> None;
}

def get_trajectory_statistics(
    trajectory_steps: List[Dict[builtins.str, Any]]
) -> Dict[builtins.str, Any];
