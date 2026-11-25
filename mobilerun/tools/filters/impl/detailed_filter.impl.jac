impl DetailedFilter.init(
    visibility_threshold: builtins.float = 0.1,
    filter_keyboard: builtins.bool = True,
    clip_bounds: builtins.bool = False,
) {
    self.visibility_threshold = visibility_threshold;
    self.filter_keyboard = filter_keyboard;
    self.clip_bounds = clip_bounds;
}

impl DetailedFilter.filter(
    a11y_tree: Dict[builtins.str, Any], device_context: Dict[builtins.str, Any]
) -> Optional[Dict[builtins.str, Any]] {
    screen_bounds: any = device_context.get("screen_bounds", {});
    screen_width: any = screen_bounds.get("width", 1080);
    screen_height: any = screen_bounds.get("height", 2400);

    filtered_tree: any = a11y_tree;

    if self.clip_bounds {
        filtered_tree = self._clip_tree_bounds(filtered_tree, screen_width, screen_height);
    }

    if self.filter_keyboard {
        filtered_tree = self._filter_keyboard_elements(filtered_tree);
        if filtered_tree is None {
            return None;
        }
    }

    filtered_tree = self._filter_out_of_bounds(filtered_tree, screen_width, screen_height);

    return filtered_tree;
}

impl DetailedFilter._get_visible_percentage(
    bounds: Dict[builtins.str, builtins.int],
    screen_width: builtins.int,
    screen_height: builtins.int,
) -> builtins.float {
    left: any = bounds.get("left", 0);
    top: any = bounds.get("top", 0);
    right: any = bounds.get("right", 0);
    bottom: any = bounds.get("bottom", 0);

    width: any = right - left;
    height: any = bottom - top;

    if width == 0 and height == 0 {
        return 0.0;
    }

    overflow: any = operator.le(left, 0)
        and operator.le(top, 0)
        and operator.ge(right, screen_width)
        and operator.ge(bottom, screen_height);
    if overflow {
        return 1.0;
    }

    visible_x: any = max(0, min(right, screen_width) - max(left, 0));
    visible_y: any = max(0, min(bottom, screen_height) - max(top, 0));

    visible_area: any = visible_x * visible_y;
    total_area: any = width * height;

    return visible_area / total_area if total_area > 0 else 0.0;
}

impl DetailedFilter._clip_bounds_to_screen(
    bounds: Dict[builtins.str, builtins.int],
    screen_width: builtins.int,
    screen_height: builtins.int,
) -> Dict[builtins.str, builtins.int] {
    return {
        "left": max(bounds.get("left", 0), 0),
        "top": max(bounds.get("top", 0), 0),
        "right": min(bounds.get("right", 0), screen_width),
        "bottom": min(bounds.get("bottom", 0), screen_height),
    };
}

impl DetailedFilter._clip_tree_bounds(
    `node: Dict[builtins.str, Any], screen_width: builtins.int, screen_height: builtins.int
) -> Dict[builtins.str, Any] {
    if "boundsInScreen" in `node {
        `node = {**`node};
        `node["boundsInScreen"] = cls._clip_bounds_to_screen(
            `node["boundsInScreen"], screen_width, screen_height
        );
    }

    if "children" in `node {
        `node["children"] = [
            cls._clip_tree_bounds(child, screen_width, screen_height)
            for child in `node.get("children") or []
        ];
    }

    return `node;
}

impl DetailedFilter._should_filter_keyboard(`node: Dict[builtins.str, Any]) -> builtins.bool {
    resource_id: any = `node.get("resourceId", "");
    return resource_id.startswith("com.google.android.inputmethod.latin:id/");
}

impl DetailedFilter._filter_keyboard_elements(
    `node: Dict[builtins.str, Any]
) -> Optional[Dict[builtins.str, Any]] {
    filtered_children: any = [];
    for child in `node.get("children") or [] {
        filtered_child: any = cls._filter_keyboard_elements(child);
        if filtered_child is not None {
            filtered_children.append(filtered_child);
        }
    }

    if cls._should_filter_keyboard(`node) {
        return None;
    }

    return {**`node, "children": filtered_children};
}

impl DetailedFilter._filter_out_of_bounds(
    `node: Dict[builtins.str, Any], screen_width: builtins.int, screen_height: builtins.int
) -> Optional[Dict[builtins.str, Any]] {
    if `node.get("ignoreBoundsFiltering") == "true" {
        return `node;
    }

    filtered_children: any = [];
    for child in `node.get("children") or [] {
        filtered_child: any = self._filter_out_of_bounds(child, screen_width, screen_height);
        if filtered_child is not None {
            filtered_children.append(filtered_child);
        }
    }

    bounds: any = `node.get("boundsInScreen");
    if bounds is None {
        visible_percentage: any = 0.0;
    } else {
        visible_percentage = self._get_visible_percentage(bounds, screen_width, screen_height);
    }

    if visible_percentage < self.visibility_threshold and not filtered_children {
        return None;
    }

    return {**`node, "children": filtered_children};
}

impl DetailedFilter.get_name -> builtins.str {
    return "detailed";
}
