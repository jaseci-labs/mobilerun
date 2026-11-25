"""
Element search and filtering for Android accessibility trees.

Provides composable filters to search elements by text, ID, spatial relationships, and traits.
Works with raw a11y tree data from Portal before index assignment.
"""

import builtins;

import re;

import from typing { Any, Callable, Dict, List, Tuple }

glob ElementFilter: any;

with entry {
    ElementFilter = Callable[[List[Dict[str, Any]]], List[Dict[str, Any]]];
}

"""Recursively flatten tree to list of all nodes."""
def flatten_tree(`root: Dict[builtins.str, Any]) -> List[Dict[builtins.str, Any]];

"""Get center coordinates from boundsInScreen."""
def get_element_center(`node: Dict[builtins.str, Any]) -> Tuple[builtins.int, builtins.int];

"""Sort elements top-to-bottom, left-to-right."""
def sort_by_position(nodes: List[Dict[builtins.str, Any]]) -> List[Dict[builtins.str, Any]];

"""Composable filters for element search."""
obj Filters {
    """
        Match elements by text content in text, contentDescription, or hint fields.
        Supports exact match, regex, and newline normalization.
        """
    static def text_matches(pattern: builtins.str | re.Pattern) -> ElementFilter;

    """Match elements by resource ID (full or short form)."""
    static def id_matches(pattern: builtins.str | re.Pattern) -> ElementFilter;

    """Find elements positioned below the anchor element."""
    static def below(anchor_filter: ElementFilter) -> ElementFilter;

    """Find elements positioned above the anchor element."""
    static def above(anchor_filter: ElementFilter) -> ElementFilter;

    """Find elements positioned left of the anchor element."""
    static def left_of(anchor_filter: ElementFilter) -> ElementFilter;

    """Find elements positioned right of the anchor element."""
    static def right_of(anchor_filter: ElementFilter) -> ElementFilter;

    """Match clickable elements."""
    static def clickable -> ElementFilter;

    """Match non-clickable elements."""
    static def non_clickable -> ElementFilter;

    """Match elements by enabled state."""
    static def enabled(expected: builtins.bool = True) -> ElementFilter;

    """Match elements by selected state."""
    static def selected(expected: builtins.bool = True) -> ElementFilter;

    """Match elements by checked state."""
    static def checked(expected: builtins.bool = True) -> ElementFilter;

    """Match elements by focused state."""
    static def focused(expected: builtins.bool = True) -> ElementFilter;

    """Match elements by size (width and/or height with tolerance)."""
    static def size_matches(
        width: builtins.int = None, height: builtins.int = None, tolerance: builtins.int = 0
    ) -> ElementFilter;

    """Match elements that contain at least one direct child matching the filter."""
    static def contains_child(child_filter: ElementFilter) -> ElementFilter;

    """Match elements that contain ALL specified descendants at any depth."""
    static def contains_descendants(filters: List[ElementFilter]) -> ElementFilter;

    """Match elements that are direct children of elements matching the parent filter."""
    static def child_of(parent_filter: ElementFilter) -> ElementFilter;

    """Match elements that have non-empty text content."""
    static def has_text -> ElementFilter;

    """Sort elements to put clickable ones first."""
    static def clickable_first -> ElementFilter;

    """Select element at index position (supports negative indices)."""
    static def index(idx: builtins.int) -> ElementFilter;

    """Apply filters sequentially (pipeline)."""
    static def compose(filters: List[ElementFilter]) -> ElementFilter;

    """Return elements matching ALL filters (AND logic)."""
    static def intersect(filters: List[ElementFilter]) -> ElementFilter;

    """Find the deepest (most specific) matching elements in the tree."""
    static def deepest_matching(base_filter: ElementFilter) -> ElementFilter;

    def __repr__ -> str;

    def __eq__(other: any) -> bool;

    def __hash__ -> int;
}
