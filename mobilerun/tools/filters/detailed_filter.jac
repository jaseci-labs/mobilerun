"""Detailed filtering - all logic self-contained."""

import builtins;

import operator;

import from typing { Any, Dict, Optional }

"""Detailed tree filtering with 10% visibility rule."""
class DetailedFilter(TreeFilter) {
    def init(
        visibility_threshold: builtins.float = 0.1,
        filter_keyboard: builtins.bool = True,
        clip_bounds: builtins.bool = False,
    );

    """Filter using detailed logic."""
    def filter(
        a11y_tree: Dict[builtins.str, Any], device_context: Dict[builtins.str, Any]
    ) -> Optional[Dict[builtins.str, Any]];

    """Calculate what percentage of element is visible on screen."""
    static def _get_visible_percentage(
        bounds: Dict[builtins.str, builtins.int],
        screen_width: builtins.int,
        screen_height: builtins.int,
    ) -> builtins.float;

    """Clip element bounds to screen boundaries."""
    static def _clip_bounds_to_screen(
        bounds: Dict[builtins.str, builtins.int],
        screen_width: builtins.int,
        screen_height: builtins.int,
    ) -> Dict[builtins.str, builtins.int];

    """Recursively clip all bounds in tree to screen."""
    class def _clip_tree_bounds(
        `node: Dict[builtins.str, Any], screen_width: builtins.int, screen_height: builtins.int
    ) -> Dict[builtins.str, Any];

    """Check if element is from Google keyboard."""
    static def _should_filter_keyboard(`node: Dict[builtins.str, Any]) -> builtins.bool;

    """Recursively remove keyboard elements from tree."""
    class def _filter_keyboard_elements(
        `node: Dict[builtins.str, Any]
    ) -> Optional[Dict[builtins.str, Any]];

    """Filter tree by visibility with parent preservation."""
    def _filter_out_of_bounds(
        `node: Dict[builtins.str, Any], screen_width: builtins.int, screen_height: builtins.int
    ) -> Optional[Dict[builtins.str, Any]];

    """Return filter name."""
    def get_name -> builtins.str;
}
