import builtins;

import from __future__ { annotations }

import time;

import from typing { Any, Dict, List, Optional }

class MacroRecorder {
    has actions: any,
        _last_recorded_at_ms: any;

    def init;

    def record_action(
        action: Dict[str, Any], *, pre_ui: Any = None, post_ui: Any = None
    ) -> Dict[str, Any];

    def record_wait(duration: float, *, pre_ui: Any = None, post_ui: Any = None) -> any;
}
