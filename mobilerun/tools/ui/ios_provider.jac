import operator;

import from __future__ { annotations }

import builtins;

import logging;

import re;

import from typing { Any, Dict, List }

import from mobilerun_core_local.driver.base { DeviceDisconnectedError, DeviceDriver }

glob logger: any = logging.getLogger("mobilerun");

glob _SKIP_TYPES: any = {
    "Window",
    "Window (Main)",
    "ScrollView",
    "CollectionView",
    "Table",
    "Toolbar",
    "TabBar",
    "StatusBar",
    "PageIndicator",
};

glob _COORD_RE: any = re.compile(
    "\\{\\{([0-9.]+),\\s*([0-9.]+)\\},\\s*\\{([0-9.]+),\\s*([0-9.]+)\\}\\}"
);

glob _ELEMENT_TYPE_RE: any = re.compile("\\s*(.+?),");

glob _LABEL_RE: any = re.compile("label:\\s*'([^']*)'");

glob _IDENTIFIER_RE: any = re.compile("identifier:\\s*'([^']*)'");

glob _PLACEHOLDER_RE: any = re.compile("placeholderValue:\\s*'([^']*)'");

glob _VALUE_RE: any = re.compile("value:\\s*([^,}]+)");

glob _CLOCK_RE: any = re.compile("^\\d{1,2}:\\d{2}$");

"""Produces ``UIState`` from an iOS device's accessibility tree."""
class IOSStateProvider(StateProvider) {
    has use_normalized: any,
        vision_enabled: any,
        vision_resize_policy: any,
        model_screenshot_width: any,
        model_screenshot_height: any,
        _vision_contract_intent: any,
        resize_model_screenshot: any,
        screenshot_matches_input_coords: any,
        requires_active_contract_for_coords: any;

    static has supported: any = {"element_index", "convert_point"};

    def init(
        driver: DeviceDriver,
        use_normalized: bool = False,
        vision_enabled: bool = False,
        vision_resize_policy: Any = None,
    );

    async def get_state -> UIState;
}

def _parse_a11y_tree(a11y_text: str) -> List[Dict[str, Any]];

def _normalize_phone_state(phone_state: Dict[str, Any], a11y_text: str) -> Dict[str, Any];

def _prioritize_actionable_elements(elements: List[Dict[str, Any]]) -> List[Dict[str, Any]];

def _format_elements(
    elements: List[Dict[str, Any]], screen_width: int, screen_height: int, normalized: bool = False
) -> str;
