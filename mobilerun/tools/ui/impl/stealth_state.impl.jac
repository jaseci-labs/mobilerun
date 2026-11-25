impl StealthUIState.get_element_coords(index: int) -> Tuple[int, int] {
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
        left: any;
        top: any;
        right: any;
        bottom: any;
        (left, top, right, bottom) = map(int, bounds_str.split(",")) as any;
    } except ValueError as e {
        raise ValueError(
            f"Invalid bounds format for element with index {index}: {bounds_str}"
        ) from e;
    }

    center_x: any = (left + right) // 2;
    center_y: any = (top + bottom) // 2;

    width: any = right - left;
    height: any = bottom - top;
    safe_zone: any = 0.4;
    x_range: any = max(5, `int(width * safe_zone));
    y_range: any = max(5, `int(height * safe_zone));

    x: any = center_x + random.randint(-x_range // 2, x_range // 2);
    y: any = center_y + random.randint(-y_range // 2, y_range // 2);
    x = max(left + 2, min(x, right - 2));
    y = max(top + 2, min(y, bottom - 2));

    return self._avoid_tap_blockers(element, (x, y));
}

impl StealthUIState.get_clear_point(index: int) -> Tuple[int, int] {
    cx: any;
    cy: any;
    (cx, cy) = super.get_clear_point(index) as any;

    element: any = self._find_by_index(self.elements, index);
    bounds_str: any = element.get("bounds", "");
    if not bounds_str {
        return (cx, cy);
    }

    left: any;
    top: any;
    right: any;
    bottom: any;
    (left, top, right, bottom) = map(int, bounds_str.split(",")) as any;
    width: any = right - left;
    height: any = bottom - top;

    x_range: any = max(5, `int(width * 0.2));
    y_range: any = max(5, `int(height * 0.2));

    x: any = cx + random.randint(-x_range // 2, x_range // 2);
    y: any = cy + random.randint(-y_range // 2, y_range // 2);

    x = max(left + 2, min(x, right - 2));
    y = max(top + 2, min(y, bottom - 2));

    return (x, y);
}
