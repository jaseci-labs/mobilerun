"""IOSStateProvider — builds UIState from iOS portal accessibility data.

Parses the raw text-based accessibility tree returned by the iOS portal
into structured elements compatible with UIState.

Known limitations:
- Normalized coordinates untested on real iOS devices
- No filter/formatter pipeline (iOS UIState still formats from raw a11y text)
"""

import operator;

import from __future__ { annotations }

import builtins;

import logging;

import re;

import from typing { Any, Dict, List, Optional }

import from mobilerun_core_local.driver.base { DeviceDisconnectedError, DeviceDriver }

glob logger: any;

glob _SKIP_TYPES: any;

glob _COORD_RE: any;

glob _ELEMENT_TYPE_RE: any;

glob _LABEL_RE: any;

glob _IDENTIFIER_RE: any;

glob _PLACEHOLDER_RE: any;

glob _VALUE_RE: any;

glob _CLOCK_RE: any;

with entry {
    logger = logging.getLogger("mobilerun");
    _SKIP_TYPES = {
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

    _COORD_RE = re.compile("\\{\\{([0-9.]+),\\s*([0-9.]+)\\},\\s*\\{([0-9.]+),\\s*([0-9.]+)\\}\\}");
    _ELEMENT_TYPE_RE = re.compile("\\s*(.+?),");
    _LABEL_RE = re.compile("label:\\s*'([^']*)'");
    _IDENTIFIER_RE = re.compile("identifier:\\s*'([^']*)'");
    _PLACEHOLDER_RE = re.compile("placeholderValue:\\s*'([^']*)'");
    _VALUE_RE = re.compile("value:\\s*([^,}]+)");
    _CLOCK_RE = re.compile("^\\d{1,2}:\\d{2}$");
}

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

"""Parse iOS accessibility tree text into structured elements.

    Moved verbatim from ``IOSTools._parse_ios_accessibility_tree``.
    """
def _parse_a11y_tree(a11y_text: str) -> List[Dict[str, Any]];

def _normalize_phone_state(phone_state: Dict[str, Any], a11y_text: str) -> Dict[str, Any];

def _prioritize_actionable_elements(elements: List[Dict[str, Any]]) -> List[Dict[str, Any]];

"""Build the text representation shown to the agent."""
def _format_elements(
    elements: List[Dict[str, Any]], screen_width: int, screen_height: int, normalized: bool = False
) -> str;
