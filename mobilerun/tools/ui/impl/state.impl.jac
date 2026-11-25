impl UIState.init(
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
) {
    self.elements = elements;
    self.formatted_text = formatted_text;
    self.focused_text = focused_text;
    self.phone_state = phone_state;
    self.screen_width = screen_width;
    self.screen_height = screen_height;
    self.use_normalized = use_normalized;
    self.coordinate_scale_x = coordinate_scale_x;
    self.coordinate_scale_y = coordinate_scale_y;
    self.model_screenshot_width = model_screenshot_width;
    self.model_screenshot_height = model_screenshot_height;
    self.coordinate_contract_active = coordinate_contract_active;
}

impl UIState.get_element(index: int) -> Optional[Dict[str, Any]] {
    return self._find_by_index(self.elements, index);
}

impl UIState.get_element_coords(index: int) -> Tuple[int, int] {
    element: any = self._find_by_index(self.elements, index);

    if element is None {
        indices: any = sorted(self._collect_indices(self.elements));
        indices_str: any = ", ".join(`str(i) for i in indices[:20]);
        if len(indices) > 20 {
            indices_str += f"... and {len(indices) - 20} more";
        }
        raise ValueError(f"No element found with index {index}. Available indices: {indices_str}");
    }

    bounds_str: any = element.get("bounds");
    if not bounds_str {
        text: any = element.get("text", "No text");
        cls: any = element.get("className", "Unknown class");
        etype: any = element.get("type", "unknown");
        raise ValueError(
            f"Element with index {index} ('{text}', {cls}, type: {etype}) has no bounds and cannot be tapped",
        );
    }

    try {
        (left, top, right, bottom) = map(int, bounds_str.split(",")) as any;
    } except ValueError as e {
        raise ValueError(
            f"Invalid bounds format for element with index {index}: {bounds_str}"
        ) from e;
    }

    return self._avoid_tap_blockers(element, ((left + right) // 2, (top + bottom) // 2));
}

impl UIState._avoid_tap_blockers(
    element: Dict[str, Any], point: Tuple[int, int]
) -> Tuple[int, int] {
    blockers: any = [
        `tuple(map(int, bounds.split(",")))
        for bounds in element.get("tapBlockers", [])
    ];
    (x, y) = point as any;
    if not `any(
        operator.le(left, x)
            and operator.lt(x, right)
            and (operator.le(top, y) and operator.lt(y, bottom))
        for (left, top, right, bottom) in blockers,
    ) {
        return point;
    }
    (left, top, right, bottom) = map(int, element["bounds"].split(",")) as any;
    if self.screen_width and self.screen_height {
        (left, top) = (max(0, left), max(0, top));
        right = min(self.screen_width, right);
        bottom = min(self.screen_height, bottom);
    }
    clear: any = find_uncovered_point((left, top, right, bottom), blockers);
    if clear is None {
        raise ValueError("No clear tap point for element " + format(element.get("index"), ""));
    }
    return clear;
}

impl UIState.get_element_info(index: int) -> Dict[str, Any] {
    element: any = self.get_element(index);
    if element is None {
        return {};
    }

    info: Dict[str, Any] = {
        "text": element.get("text", "No text"),
        "className": element.get("className", "Unknown class"),
        "type": element.get("type", "unknown"),
    };

    children: any = element.get("children") or [];
    if children {
        child_texts: any = [c.get("text") for c in children if c.get("text")];
        if child_texts {
            info["child_texts"] = child_texts;
        }
    }

    return info;
}

impl UIState.get_clear_point(index: int) -> Tuple[int, int] {
    element: any = self._find_by_index(self.elements, index);
    if element is None {
        raise ValueError(f"No element found with index {index}");
    }

    bounds_str: any = element.get("bounds");
    if not bounds_str {
        raise ValueError(f"Element {index} has no bounds");
    }

    target_bounds: any = `tuple(map(int, bounds_str.split(",")));

    all_elements: any = self._collect_all(self.elements);
    blockers: any = [];
    for el in all_elements {
        el_idx: any = el.get("index");
        el_bounds_str: any = el.get("bounds");
        if el_idx is not None and el_idx > index and el_bounds_str {
            el_bounds: any = `tuple(map(int, el_bounds_str.split(",")));
            if rects_overlap(target_bounds, el_bounds) {
                blockers.append(el_bounds);
            }
        }
    }

    point: any = find_clear_point(target_bounds, blockers);
    if point is None {
        raise ValueError(f"Element {index} is fully obscured by overlapping elements");
    }
    return point;
}

impl UIState.convert_point(x: int, y: int) -> Tuple[int, int] {
    if self.use_normalized {
        (abs_x, abs_y) = to_absolute(x, y, self.screen_width, self.screen_height) as any;
        if x == NORMALIZED_MAX {
            abs_x = max(self.screen_width - 1, 0);
        }
        if y == NORMALIZED_MAX {
            abs_y = max(self.screen_height - 1, 0);
        }
        return (abs_x, abs_y);
    }
    return (`int(round(x * self.coordinate_scale_x)), `int(round(y * self.coordinate_scale_y)));
}

impl UIState._find_by_index(
    elements: List[Dict[str, Any]], target: int
) -> Optional[Dict[str, Any]] {
    for item in elements {
        if item.get("index") == target {
            return item;
        }
        child: any = UIState._find_by_index(item.get("children") or [], target);
        if child is not None {
            return child;
        }
    }
    return None;
}

impl UIState._collect_indices(elements: List[Dict[str, Any]]) -> List[int] {
    indices: List[int] = [];
    for item in elements {
        if item.get("index") is not None {
            indices.append(item["index"]);
        }
        indices.extend(UIState._collect_indices(item.get("children") or []));
    }
    return indices;
}

impl UIState._collect_all(elements: List[Dict[str, Any]]) -> List[Dict[str, Any]] {
    result: List[Dict[str, Any]] = [];
    for item in elements {
        result.append(item);
        result.extend(UIState._collect_all(item.get("children") or []));
    }
    return result;
}
