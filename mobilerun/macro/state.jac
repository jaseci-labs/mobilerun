import operator;

import from __future__ { annotations }

import from typing { Any, Dict, Iterable, List, Optional, Tuple }

glob MACRO_SCHEMA_VERSION: any = "2.0";

glob UNSUPPORTED_SCHEMA_MESSAGE: any = "Unsupported macro schema. Re-record this macro with the current Mobilerun version.";

def normalize_ui_state(ui_state: Any) -> Dict[str, Any];

def build_screen_snapshot(ui_state: Any) -> Dict[str, Any];

def node_semantic_key(`node: Dict[str, Any]) -> Tuple[Any, ...];

def _extract_elements(ui_state: Any) -> List[Dict[str, Any]];

def _extract_phone_state(ui_state: Any) -> Dict[str, Any];

def _extract_screen(ui_state: Any) -> Dict[str, Any];

def _walk_elements(elements: Iterable[Dict[str, Any]]) -> Generator[any, any, any];

def _normalize_element(element: Dict[str, Any]) -> Optional[Dict[str, Any]];

def _first_present(data: Dict[str, Any], *keys_: str) -> Any;

def _normalize_text(value: Any) -> Optional[str];

def _normalize_bool(value: Any) -> Optional[bool];

def _parse_bounds(value: Any) -> Optional[Dict[str, int]];

def _bounds_tuple(value: Any) -> Optional[Tuple[int, int, int, int]];
