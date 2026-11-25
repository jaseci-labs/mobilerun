"""Agent handoff for guarded macro replay divergence."""

import from __future__ { annotations }

import importlib;

import from typing { Any, Dict, List, Optional }

"""Invoke the normal Mobilerun agent after macro replay diverges."""
async def run_agent_handoff(
    *,
    goal: str,
    device_serial: Optional[str],
    provider: Optional[str] = None,
    model: Optional[str] = None,
    config_path: Optional[str] = None,
    divergence: Dict[str, Any],
    current_state: Dict[str, Any],
    remaining_actions: List[Dict[str, Any]],
) -> bool;
