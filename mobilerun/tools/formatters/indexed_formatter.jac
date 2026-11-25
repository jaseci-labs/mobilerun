import builtins;

import from typing { Any, Dict, List, Optional, Tuple }

"""Format tree in the standard Mobilerun format."""
class IndexedFormatter(TreeFormatter) {
    def init;

    def format(
        filtered_tree: Optional[Dict[builtins.str, Any]], phone_state: Dict[builtins.str, Any]
    ) -> Tuple[builtins.str, builtins.str, List[Dict[builtins.str, Any]], Dict[builtins.str, Any]];

    static def _get_focused_text(phone_state: Dict[builtins.str, Any]) -> builtins.str;

    static def _format_phone_state(phone_state: Dict[builtins.str, Any]) -> builtins.str;

    def _format_ui_elements_text(a11y_tree: List[Dict[builtins.str, Any]]) -> builtins.str;

    static def _format_ui_elements(
        ui_data: List[Dict[builtins.str, Any]], level: builtins.int = 0
    ) -> builtins.str;

    def _flatten_with_index(
        `node: Dict[builtins.str, Any], counter: List[builtins.int]
    ) -> List[Dict[builtins.str, Any]];

    static def _add_tap_blockers(
        siblings: List[Tuple[Dict[builtins.str, Any], Dict[builtins.str, Any]]]
    ) -> None;

    def _format_node(
        `node: Dict[builtins.str, Any], index: builtins.int
    ) -> Dict[builtins.str, Any];
}
