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
    ) {
        super.init(driver);
        self.use_normalized = use_normalized;
        self.vision_enabled = vision_enabled;
        self.vision_resize_policy = vision_resize_policy;
        self.model_screenshot_width = None;
        self.model_screenshot_height = None;
        self._vision_contract_intent = vision_enabled and not use_normalized;
        self.resize_model_screenshot = self._vision_contract_intent;
        self.screenshot_matches_input_coords = self._vision_contract_intent or use_normalized;
        self.requires_active_contract_for_coords = vision_enabled;
    }

    async def get_state -> UIState {
        try {
            raw: any = (await self.driver.get_ui_tree());
        } except DeviceDisconnectedError {
            raise;
        } except Exception as e {
            logger.warning(f"iOS state retrieval failed, returning empty state: {e}");
            if self._vision_contract_intent {
                self.resize_model_screenshot = False;
            }
            self.model_screenshot_width = None;
            self.model_screenshot_height = None;
            return UIState(
                elements=[],
                formatted_text="No UI elements available — device may be loading.",
                focused_text="",
                phone_state={},
                screen_width=390,
                screen_height=844,
                use_normalized=self.use_normalized,
            );
        }

        a11y_tree: any = raw.get("a11y_tree", "");
        a11y_text: any = a11y_tree if isinstance(a11y_tree, `str) else raw.get("raw_a11y_tree", "");
        phone_state: any = `dict(raw.get("phone_state", {}) or {});
        device_context: any = raw.get("device_context", {});

        elements: any = _parse_a11y_tree(a11y_text);
        phone_state = _normalize_phone_state(phone_state, a11y_text);
        screen_bounds: any = device_context.get("screen_bounds", {});
        screen_width: any = `int(screen_bounds.get("width", 390));
        screen_height: any = `int(screen_bounds.get("height", 844));
        normalized_ready: any = `bool(
            self.use_normalized and screen_bounds.get("width") and screen_bounds.get("height")
        );
        coordinate_scale_x: any = 1.0;
        coordinate_scale_y: any = 1.0;
        display_width: any = None;
        display_height: any = None;
        if self._vision_contract_intent and screen_width and screen_height {
            try {
                screenshot: any = (await self.driver.screenshot());
                (shot_width, shot_height) = image_dimensions(screenshot) as any;
                if self.vision_resize_policy is not None {
                    (display_width, display_height) = self.vision_resize_policy.effective_dims(
                        shot_width, shot_height
                    ) as any;
                } else {
                    (display_width, display_height) = fit_dimensions_to_max_side(
                        shot_width, shot_height
                    ) as any;
                }
                coordinate_scale_x = screen_width / display_width;
                coordinate_scale_y = screen_height / display_height;
            } except Exception as e {
                logger.warning(
                    f"iOS vision coordinate contract disabled for this state (screenshot probe failed): {e}",
                );
                display_width = None;
                display_height = None;
                coordinate_scale_x = 1.0;
                coordinate_scale_y = 1.0;
            }
        }
        if self._vision_contract_intent {
            self.resize_model_screenshot = `bool(display_width and display_height);
        }
        self.model_screenshot_width = display_width;
        self.model_screenshot_height = display_height;

        if display_width and display_height {
            for element in elements {
                (left, top, right, bottom) = (`int(part)
                for part in element["bounds"].split(",")) as any;
                element["displayBounds"] = ",".join(
                    `str(round(value / scale))
                    for (value, scale) in builtins.zip(
                        (left, top, right, bottom),
                        (
                            coordinate_scale_x,
                            coordinate_scale_y,
                            coordinate_scale_x,
                            coordinate_scale_y,
                        ),
                        strict=True,
                    ),
                );
            }
        } elif normalized_ready {
            for element in elements {
                element["displayBounds"] = bounds_to_normalized(
                    element["bounds"], screen_width, screen_height
                );
            }
        }

        formatted_text: any = _format_elements(
            elements, screen_width, screen_height, normalized=normalized_ready
        );
        if normalized_ready and self.vision_enabled {
            formatted_text += f"\n\n{NORMALIZED_STATE_NOTE}";
        }

        if display_width and display_height {
            formatted_text += f"\n\nAll coordinates in this device state (element bounds above, and any x/y you provide to coordinate actions) are in a {display_width}x{display_height} coordinate space — the device screen scaled to the screenshot shown to you. When a screenshot is provided it matches this {display_width}x{display_height} space and carries a labeled coordinate grid for reference.";
        }
        focused_element: any = phone_state.get("focusedElement");
        focused_text: any = "";
        if focused_element and isinstance(focused_element, `dict) {
            focused_text = focused_element.get("text", "");
        }

        return UIState(
            elements=elements,
            formatted_text=formatted_text,
            focused_text=focused_text,
            phone_state=phone_state,
            screen_width=screen_width,
            screen_height=screen_height,
            use_normalized=self.use_normalized,
            coordinate_scale_x=coordinate_scale_x,
            coordinate_scale_y=coordinate_scale_y,
            coordinate_contract_active=`bool(display_width and display_height) or normalized_ready,
            model_screenshot_width=display_width,
            model_screenshot_height=display_height,
        );
    }
}

def _parse_a11y_tree(a11y_text: str) -> List[Dict[str, Any]] {
    elements: List[Dict[str, Any]] = [];
    element_index: any = 0;

    seen_signatures: set[tuple[str, str, str]] = set[any]();

    for line in a11y_text.strip().split("\n") {
        stripped: any = line.strip();
        if not stripped
            or stripped.startswith("Attributes:")
            or stripped.startswith("Element subtree:")
            or stripped.startswith("Path to element:")
            or stripped.startswith("Query chain:")
        {
            continue;
        }

        coord_match: any = _COORD_RE.search(line);
        if not coord_match {
            continue;
        }

        (x, y, width, height) = map(float, coord_match.groups()) as any;
        if width == 0 or height == 0 {
            continue;
        }
        type_match: any = _ELEMENT_TYPE_RE.match(line);
        element_type: any = type_match.group(1).strip() if type_match else "Unknown";
        element_type = re.sub("^[→\\s]+", "", element_type);
        if element_type in _SKIP_TYPES {
            continue;
        }
        label_m: any = _LABEL_RE.search(line);
        label: any = label_m.group(1) if label_m else "";
        ident_m: any = _IDENTIFIER_RE.search(line);
        identifier: any = ident_m.group(1) if ident_m else "";
        ph_m: any = _PLACEHOLDER_RE.search(line);
        placeholder: any = ph_m.group(1) if ph_m else "";
        val_m: any = _VALUE_RE.search(line);
        value: any = val_m.group(1).strip() if val_m else "";

        text: any = label or identifier or placeholder or "";
        bounds_str: any = f"{`int(x)},{`int(y)},{`int(x + width)},{`int(y + height)}";
        signature: any = (element_type, text, bounds_str);
        if element_type == "Other" and not (label or identifier or placeholder or value) {
            continue;
        }
        if signature in seen_signatures {
            continue;
        }
        seen_signatures.add(signature);

        elements.append({
            "index": element_index,
            "type": element_type,
            "className": element_type,
            "text": text,
            "label": label,
            "identifier": identifier,
            "placeholder": placeholder,
            "value": value,
            "bounds": bounds_str,
            "rect": f"{x},{y},{width},{height}",
            "children": [],
        });
        element_index += 1;
    }

    return _prioritize_actionable_elements(elements);
}

def _normalize_phone_state(phone_state: Dict[str, Any], a11y_text: str) -> Dict[str, Any] {
    package_name: any = phone_state.get("packageName", "") or "";
    current_app: any = phone_state.get("currentApp", "") or "";

    is_home: any = operator.eq(package_name, "com.apple.springboard")
        or "Home screen icons" in a11y_text;
    if is_home {
        phone_state["packageName"] = "com.apple.springboard";
        if not current_app or _CLOCK_RE.match(current_app) {
            phone_state["currentApp"] = "Home Screen";
        }
    } elif current_app and _CLOCK_RE.match(current_app) {
        phone_state["currentApp"] = "";
    }

    return phone_state;
}

def _prioritize_actionable_elements(elements: List[Dict[str, Any]]) -> List[Dict[str, Any]] {
    actionable_types = {
        "Icon",
        "Button",
        "SearchField",
        "TextField",
        "SecureTextField",
        "TextView",
        "Cell",
        "StaticText",
        "Image",
        "Switch",
    };

    def sort_key(el: Dict[str, Any]) -> tuple[int, int] {
        class_name: any = el.get("className", "");
        text: any = el.get("text", "");
        actionable_rank: any = 0 if class_name in actionable_types and text else 1;
        return (actionable_rank, el.get("index", 0));
    }

    ordered: any = sorted(elements, key=sort_key);
    for (i, el) in enumerate(ordered) {
        el["index"] = i;
    }
    return ordered;
}

def _format_elements(
    elements: List[Dict[str, Any]], screen_width: int, screen_height: int, normalized: bool = False
) -> str {
    coord_note: any = " (normalized [0-1000])" if normalized else "";
    schema: any = "'index. className: text - bounds(x1,y1,x2,y2)'";
    if not elements {
        return f"Current UI elements{coord_note}:\n{schema}:\nNo UI elements found";
    }

    lines: any = [f"Current UI elements{coord_note}:\n{schema}:"];
    for el in elements {
        idx: any = el.get("index", 0);
        cls: any = el.get("className", "Unknown");
        text: any = el.get("text", "");
        bounds: any = el.get("displayBounds") or el.get("bounds", "");

        parts: any = [f"{idx}. {cls}:"];
        if text {
            parts.append(text);
        }
        if bounds {
            parts.append(f"- ({bounds})");
        }
        lines.append(" ".join(parts));
    }

    return "\n".join(lines);
}
