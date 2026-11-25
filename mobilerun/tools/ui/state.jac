import builtins;

import operator;

import from __future__ { annotations }

import from typing { Any, Dict, List, Optional, Tuple }

"""Holds parsed UI elements for a single device state snapshot."""
class UIState {
    has elements: any,
        formatted_text: any,
        focused_text: any,
        phone_state: any,
        screen_width: any,
        screen_height: any,
        use_normalized: any,
        coordinate_scale_x: any,
        coordinate_scale_y: any,
        model_screenshot_width: any,
        model_screenshot_height: any,
        coordinate_contract_active: any;

    def init(
        elements: List[Dict[str, Any]],
        formatted_text: str,
        focused_text: str,
        phone_state: Dict[str, Any],
        screen_width: int,
        screen_height: int,
        use_normalized: bool = False,
        coordinate_scale_x: float = 1.0,
        coordinate_scale_y: float = 1.0,
        coordinate_contract_active: bool = False,
        model_screenshot_width: Optional[int] = None,
        model_screenshot_height: Optional[int] = None,
    );

    def get_element(index: int) -> Optional[Dict[str, Any]];

    def get_element_coords(index: int) -> Tuple[int, int];

    def _tappable_bounds(index: int) -> tuple[any, int, int, int, int];

    def _avoid_tap_blockers(element: Dict[str, Any], point: Tuple[int, int]) -> Tuple[int, int];

    def get_element_info(index: int) -> Dict[str, Any];

    def get_clear_point(index: int) -> Tuple[int, int];

    def convert_point(x: int, y: int) -> Tuple[int, int];

    static def _find_by_index(
        elements: List[Dict[str, Any]], target: int
    ) -> Optional[Dict[str, Any]];

    static def _collect_indices(elements: List[Dict[str, Any]]) -> List[int];

    static def _collect_all(elements: List[Dict[str, Any]]) -> List[Dict[str, Any]];
}
