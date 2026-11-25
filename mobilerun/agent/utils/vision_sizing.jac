"""Resolve the exact screenshot size a vision model actually grounds on.

Some providers downsize images server-side before the model sees them (e.g.
Anthropic's 28px visual-token budget). If the coordinate contract declares a
larger space than the model receives, the model grounds on the smaller image it
actually sees and coordinate actions land short. This policy computes the EXACT
dimensions the model will use, so the declared space == the sent image and
``convert_point`` stays exact.
"""

import builtins;

import from __future__ { annotations }

import from typing { Any, Optional, Sequence }

glob _ANTHROPIC_STANDARD: any = (1568, 1568);

glob _ANTHROPIC_HIGHRES: any = (2576, 4784);

glob _GROUNDING_MAX_SIDE: any = {"claude-sonnet-5": 1568};

def _model_id(llm: Any) -> str;

def _is_anthropic(model_id: str) -> bool;

"""Whether the model answers screenshot positions on a 0-1000 grid.

    Gemma and Gemini 3.8 Flash ground in normalized coordinates and ignore a
    declared pixel space.
    """
def model_uses_normalized_coordinates(model_id: str) -> bool;

"""Exact dims a single model grounds on for a native ``width``x``height`` screen."""
def model_effective_dims(model_id: str, width: int, height: int) -> tuple[int, int];

"""Composite resize policy across all active vision models.

    Resolves the screenshot dimensions the contract should declare and send so
    the image matches what EVERY screenshot recipient grounds on. Uses the
    smallest (most conservative) result across models, then an optional explicit
    max-side cap (escape hatch for undocumented local/Ollama models).
    """
obj VisionResizePolicy {
    has _model_ids: any,
        _cap: any;

    def init(model_ids: Sequence[str], max_side_cap: Optional[int] = None);

    class def from_llms(
        llms: Sequence[Any], max_side_cap: Optional[int] = None
    ) -> "VisionResizePolicy";

    """Smallest effective dims across all models, after the optional cap."""
    def effective_dims(width: int, height: int) -> tuple[int, int];

    def __repr__ -> str;

    def __eq__(other: any) -> bool;

    def __hash__ -> int;
}
