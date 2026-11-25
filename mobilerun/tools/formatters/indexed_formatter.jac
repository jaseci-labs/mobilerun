"""Indexed formatter - Standard Mobilerun format."""

import builtins;

import from typing { Any, Dict, List, Optional, Tuple }

"""Format tree in the standard Mobilerun format."""
class IndexedFormatter(TreeFormatter) {
    def init;

    """Format device state with indices and hierarchy."""
    def format(
        filtered_tree: Optional[Dict[builtins.str, Any]], phone_state: Dict[builtins.str, Any]
    ) -> Tuple[builtins.str, builtins.str, List[Dict[builtins.str, Any]], Dict[builtins.str, Any]];

    """Extract focused element text."""
    static def _get_focused_text(phone_state: Dict[builtins.str, Any]) -> builtins.str;

    """Format phone state."""
    static def _format_phone_state(phone_state: Dict[builtins.str, Any]) -> builtins.str;

    """Format UI elements text."""
    def _format_ui_elements_text(a11y_tree: List[Dict[builtins.str, Any]]) -> builtins.str;

    """Format UI elements."""
    static def _format_ui_elements(
        ui_data: List[Dict[builtins.str, Any]], level: builtins.int = 0
    ) -> builtins.str;

    """Recursively flatten tree with index assignment."""
    def _flatten_with_index(
        `node: Dict[builtins.str, Any], counter: List[builtins.int]
    ) -> List[Dict[builtins.str, Any]];

    """Retain proven sibling touch obstructions before discarding hierarchy.

        Android drawingOrder is relative to siblings, not a global z-index.
        Portal can append other windows as children, so windowId must match.
        Missing or tied order is insufficient evidence to change existing taps.
        """
    static def _add_tap_blockers(
        siblings: List[Tuple[Dict[builtins.str, Any], Dict[builtins.str, Any]]]
    ) -> None;

    """Format single node to Mobilerun format."""
    def _format_node(
        `node: Dict[builtins.str, Any], index: builtins.int
    ) -> Dict[builtins.str, Any];
}
