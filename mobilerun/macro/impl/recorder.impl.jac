impl MacroRecorder.init {
    self.actions = [];
    self._last_recorded_at_ms = None;
}

impl MacroRecorder.record_action(
    action: Dict[str, Any], *, pre_ui: Any = None, post_ui: Any = None
) -> Dict[str, Any] {
    now_ms: any = `int(time.time() * 1000);
    elapsed_ms: any = 0
        if self._last_recorded_at_ms is None
        else max(0, now_ms - self._last_recorded_at_ms);

    snapshot: any = build_screen_snapshot(pre_ui);
    macro_action: any = {
        **action,
        "pre_state": snapshot,
        "screen": snapshot.get("screen", {}),
        "recorded_at_ms": now_ms,
        "elapsed_since_previous_ms": elapsed_ms,
    };

    if post_ui is not None {
        macro_action["post_state"] = build_screen_snapshot(post_ui);
    }

    self.actions.append(macro_action);
    self._last_recorded_at_ms = now_ms;
    return macro_action;
}

impl MacroRecorder.record_wait(duration: float, *, pre_ui: Any = None, post_ui: Any = None) -> any {
    return self.record_action(
        {"action_type": "wait", "duration": duration}, pre_ui=pre_ui, post_ui=post_ui
    );
}
