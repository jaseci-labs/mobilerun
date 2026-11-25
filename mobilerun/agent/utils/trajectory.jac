"""
Trajectory utilities for Mobilerun agents.

This module provides the Trajectory data container and utilities for
loading and analyzing saved trajectory data.
"""

import builtins;

import json;

import logging;

import os;

import time;

import uuid;

import from typing { Any, Dict, List }

import from llama_index.core.workflow { Event }

glob logger: any;

with entry {
    logger = logging.getLogger("mobilerun");
}

class Trajectory {
    has events: any,
        screenshot_count: any,
        screenshot_queue: any,
        ui_states: any,
        macro: any,
        goal: any,
        base_path: any,
        trajectory_folder: any;

    """Initialize trajectory with incremental saving.

        Args:
            goal: The goal/prompt that this trajectory is trying to achieve
            base_path: Directory for saving (absolute or relative to cwd)
        """
    def init(goal: builtins.str = None, base_path: builtins.str = "trajectories");

    """Convert config path to absolute Path."""
    def _resolve_path(config_path: builtins.str) -> any;

    """Create unique trajectory folder with timestamp and UUID."""
    def _create_trajectory_folder -> any;

    """Update the goal/description for this trajectory.

        Args:
            goal: The new goal/prompt description
        """
    def set_goal(goal: builtins.str) -> None;

    def get_trajectory -> List[Dict[builtins.str, Any]];

    """
        Load trajectory data from a trajectory folder.

        Args:
            trajectory_folder: Path to the trajectory folder

        Returns:
            Dictionary containing trajectory data, macro data, and file paths
        """
    static def load_trajectory_folder(trajectory_folder: builtins.str) -> Dict[builtins.str, Any];

    """
        Load a macro sequence from a saved macro file.

        Args:
            macro_file_path: Path to the macro JSON file (can be full path or trajectory folder)

        Returns:
            Dictionary containing the macro sequence data
        """
    static def load_macro_sequence(macro_file_path: builtins.str) -> Dict[builtins.str, Any];

    """
        Get a summary of a macro sequence.

        Args:
            macro_data: The macro data dictionary

        Returns:
            Dictionary with statistics about the macro
        """
    static def get_macro_summary(macro_data: Dict[builtins.str, Any]) -> Dict[builtins.str, Any];

    """
        Print a summary of a macro sequence.

        Args:
            macro_file_path: Path to the macro JSON file or trajectory folder
        """
    static def print_macro_summary(macro_file_path: builtins.str) -> None;

    """
        Print a comprehensive summary of a trajectory folder.

        Args:
            trajectory_folder: Path to the trajectory folder
        """
    static def print_trajectory_folder_summary(trajectory_folder: builtins.str) -> None;

    """
        Print a summary of a trajectory.

        Args:
            trajectory_data: The trajectory data dictionary
        """
    def print_trajectory_summary(trajectory_data: Dict[builtins.str, Any]) -> None;
}

"""
    Get statistics about a trajectory.

    Args:
        trajectory_steps: The trajectory list of steps

    Returns:
        Dictionary with statistics about the trajectory
    """
def get_trajectory_statistics(
    trajectory_steps: List[Dict[builtins.str, Any]]
) -> Dict[builtins.str, Any];

with entry {}
