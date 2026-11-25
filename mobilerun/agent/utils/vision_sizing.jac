import builtins;

import from __future__ { annotations }

import from typing { Any, Optional, Sequence }

glob _ANTHROPIC_STANDARD: any = (1568, 1568);

glob _ANTHROPIC_HIGHRES: any = (2576, 4784);

glob _GROUNDING_MAX_SIDE: any = {"claude-sonnet-5": 1568};

def _model_id(llm: Any) -> str;

def _is_anthropic(model_id: str) -> bool;

def model_uses_normalized_coordinates(model_id: str) -> bool;

def model_effective_dims(model_id: str, width: int, height: int) -> tuple[int, int];

"""Composite resize policy across all active vision models.

    Resolves the screenshot dimensions the contract should declare and send so
    the image matches what EVERY screenshot recipient grounds on. Uses the
    smallest (most conservative) result across models, then an optional explicit
    max-side cap (escape hatch for undocumented local/Ollama models).
    """
class VisionResizePolicy {
    has _model_ids: any,
        _cap: any;

    def init(model_ids: Sequence[str], max_side_cap: Optional[int] = None);

    class def from_llms(
        llms: Sequence[Any], max_side_cap: Optional[int] = None
    ) -> "VisionResizePolicy";

    def effective_dims(width: int, height: int) -> tuple[int, int];
}
