"""Action-level macro recorder for schema v2."""

import builtins;

import from __future__ { annotations }

import time;

import from typing { Any, Dict, List, Optional }

obj MacroRecorder {
    has actions: any,
        _last_recorded_at_ms: any;

    def init;

    def record_action(
        action: Dict[str, Any], *, pre_ui: Any = None, post_ui: Any = None
    ) -> Dict[str, Any];

    def record_wait(duration: float, *, pre_ui: Any = None, post_ui: Any = None) -> any;

    def __repr__ -> str;

    def __eq__(other: any) -> bool;

    def __hash__ -> int;
}
