import builtins;

import from typing { Any, Dict, Optional }

"""Concise tree filtering (formerly Mobilerun)."""
class ConciseFilter(TreeFilter) {
    def filter(
        a11y_tree: Dict[builtins.str, Any], device_context: Dict[builtins.str, Any]
    ) -> Optional[Dict[builtins.str, Any]] {
        screen_bounds: any = device_context.get("screen_bounds", {});
        filtering_params: any = device_context.get("filtering_params", {});

        return self._filter_node(a11y_tree, screen_bounds, filtering_params);
    }

    def _filter_node(
        `node: Dict[builtins.str, Any],
        screen_bounds: Dict[builtins.str, builtins.int],
        filtering_params: Dict[builtins.str, Any],
    ) -> Optional[Dict[builtins.str, Any]] {
        min_size: any = filtering_params.get("min_element_size", 5);
        screen_width: any = screen_bounds.get("width", 1080);
        screen_height: any = screen_bounds.get("height", 2400);

        if not self._intersects_screen(`node, screen_width, screen_height) {
            return None;
        }
        if not self._min_size(`node, min_size) {
            return None;
        }

        filtered_children = [];
        for child in `node.get("children") or [] {
            filtered_child: any = self._filter_node(child, screen_bounds, filtering_params);
            if filtered_child {
                filtered_children.append(filtered_child);
            }
        }

        return {**`node, "children": filtered_children};
    }

    static def _intersects_screen(
        `node: Dict[builtins.str, Any], screen_width: builtins.int, screen_height: builtins.int
    ) -> builtins.bool {
        bounds: any = `node.get("boundsInScreen", {});
        left: any = bounds.get("left", 0);
        top: any = bounds.get("top", 0);
        right: any = bounds.get("right", 0);
        bottom: any = bounds.get("bottom", 0);
        return not (right <= 0 or bottom <= 0 or left >= screen_width or top >= screen_height);
    }

    static def _min_size(`node: Dict[builtins.str, Any], min_size: builtins.int) -> builtins.bool {
        bounds: any = `node.get("boundsInScreen", {});
        w: any = bounds.get("right", 0) - bounds.get("left", 0);
        h: any = bounds.get("bottom", 0) - bounds.get("top", 0);
        return (w > min_size) and (h > min_size);
    }

    def get_name -> builtins.str {
        return "concise";
    }
}
