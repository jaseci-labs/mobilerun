"""Concise filtering - all logic self-contained."""

import builtins;

import operator;

import from typing { Any, Dict, Optional }

"""Concise tree filtering (formerly Mobilerun)."""
class ConciseFilter(TreeFilter) {
    """Filter using concise logic."""
    def filter(
        a11y_tree: Dict[builtins.str, Any], device_context: Dict[builtins.str, Any]
    ) -> Optional[Dict[builtins.str, Any]];

    """Recursively filter node."""
    def _filter_node(
        `node: Dict[builtins.str, Any],
        screen_bounds: Dict[builtins.str, builtins.int],
        filtering_params: Dict[builtins.str, Any],
    ) -> Optional[Dict[builtins.str, Any]];

    """Check if element intersects screen bounds."""
    static def _intersects_screen(
        `node: Dict[builtins.str, Any], screen_width: builtins.int, screen_height: builtins.int
    ) -> builtins.bool;

    """Check if element meets minimum size."""
    static def _min_size(`node: Dict[builtins.str, Any], min_size: builtins.int) -> builtins.bool;

    """Return filter name."""
    def get_name -> builtins.str;
}
