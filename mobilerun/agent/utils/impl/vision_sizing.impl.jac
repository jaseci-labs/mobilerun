impl _model_id(llm: Any) -> str {
    return `str(getattr(llm, "model", "") or "");
}

impl _is_anthropic(model_id: str) -> bool {
    return model_id.startswith("claude");
}

impl model_uses_normalized_coordinates(model_id: str) -> bool {
    model: any = model_id.lower();
    return "gemma" in model or "gemini-3.8-flash" in model;
}

impl model_effective_dims(model_id: str, width: int, height: int) -> tuple[int, int] {
    base_w: any;
    base_h: any;
    (base_w, base_h) = fit_dimensions_to_max_side(width, height, MODEL_SCREENSHOT_MAX_SIDE) as any;
    if _is_anthropic(model_id) {
        `edge: any;
        tokens: any;
        (`edge, tokens) = (
            _ANTHROPIC_HIGHRES if model_id in ANTHROPIC_HIGHRES_MODELS else _ANTHROPIC_STANDARD
        ) as any;
        (base_w, base_h) = anthropic_resized_size(base_w, base_h, `edge, tokens) as any;
    }
    limit: any = _GROUNDING_MAX_SIDE.get(model_id);
    if limit and max(base_w, base_h) > limit {
        (base_w, base_h) = fit_dimensions_to_max_side(base_w, base_h, limit) as any;
    }
    return (base_w, base_h);
}

impl VisionResizePolicy.init(model_ids: Sequence[str], max_side_cap: Optional[int] = None) {
    self._model_ids = [m for m in dict.fromkeys(model_ids) if m];
    self._cap = max_side_cap if max_side_cap and max_side_cap > 0 else None;
}

impl VisionResizePolicy.from_llms(
    llms: Sequence[Any], max_side_cap: Optional[int] = None
) -> "VisionResizePolicy" {
    return cls([_model_id(llm) for llm in llms if llm is not None], max_side_cap=max_side_cap);
}

impl VisionResizePolicy.effective_dims(width: int, height: int) -> tuple[int, int] {
    if width <= 0 or height <= 0 {
        return (width, height);
    }
    candidates: any = [model_effective_dims(m, width, height) for m in self._model_ids] or [
        fit_dimensions_to_max_side(width, height, MODEL_SCREENSHOT_MAX_SIDE),
    ];
    w: any;
    h: any;
    (w, h) = min(candidates, key=builtins.max) as any;
    if self._cap and max(w, h) > self._cap {
        (w, h) = fit_dimensions_to_max_side(w, h, self._cap) as any;
    }
    return (w, h);
}

impl VisionResizePolicy.__repr__ -> str {
    return (getattr(builtins.object, "__repr__") as any)(self);
}

impl VisionResizePolicy.__eq__(other: any) -> bool {
    return self is other;
}

impl VisionResizePolicy.__hash__ -> int {
    return id(self);
}
