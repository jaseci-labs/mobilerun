import builtins;

import re;

import from typing { Any, Callable, Dict, List, Tuple }

glob ElementFilter: any = Callable[[List[Dict[str, Any]]], List[Dict[str, Any]]];

def flatten_tree(`root: Dict[builtins.str, Any]) -> List[Dict[builtins.str, Any]];

def get_element_center(`node: Dict[builtins.str, Any]) -> Tuple[builtins.int, builtins.int];

def sort_by_position(nodes: List[Dict[builtins.str, Any]]) -> List[Dict[builtins.str, Any]];

"""Composable filters for element search."""
class Filters {
    static def text_matches(pattern: builtins.str | re.Pattern) -> ElementFilter;

    static def id_matches(pattern: builtins.str | re.Pattern) -> ElementFilter;

    static def below(anchor_filter: ElementFilter) -> ElementFilter;

    static def above(anchor_filter: ElementFilter) -> ElementFilter;

    static def left_of(anchor_filter: ElementFilter) -> ElementFilter;

    static def right_of(anchor_filter: ElementFilter) -> ElementFilter;

    static def clickable -> ElementFilter;

    static def non_clickable -> ElementFilter;

    static def enabled(expected: builtins.bool = True) -> ElementFilter;

    static def selected(expected: builtins.bool = True) -> ElementFilter;

    static def checked(expected: builtins.bool = True) -> ElementFilter;

    static def focused(expected: builtins.bool = True) -> ElementFilter;

    static def size_matches(
        width: builtins.int = None, height: builtins.int = None, tolerance: builtins.int = 0
    ) -> ElementFilter;

    static def contains_child(child_filter: ElementFilter) -> ElementFilter;

    static def contains_descendants(filters: List[ElementFilter]) -> ElementFilter;

    static def child_of(parent_filter: ElementFilter) -> ElementFilter;

    static def has_text -> ElementFilter;

    static def clickable_first -> ElementFilter;

    static def index(idx: builtins.int) -> ElementFilter;

    static def compose(filters: List[ElementFilter]) -> ElementFilter;

    static def intersect(filters: List[ElementFilter]) -> ElementFilter;

    static def deepest_matching(base_filter: ElementFilter) -> ElementFilter;
}
