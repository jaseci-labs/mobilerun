import operator;

import from __future__ { annotations }

import from dataclasses { dataclass }

import from typing { Any, Dict, Tuple }

@dataclass(frozen=True)
class StateMatchResult {
    has matches: bool;

    has score: float;

    has reason: str;
}

def compare_states(
    saved_state: Dict[str, Any], current_state: Dict[str, Any], threshold: float = 0.85
) -> StateMatchResult;

def _node_key_set(state: Dict[str, Any]) -> set[Tuple[Any, ...]];

def _phone_score(saved_state: Dict[str, Any], current_state: Dict[str, Any]) -> float;
