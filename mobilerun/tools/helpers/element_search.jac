import builtins;

import re;

import from typing { Any, Callable, Dict, List, Tuple }

glob ElementFilter: any = Callable[[List[Dict[str, Any]]], List[Dict[str, Any]]];

glob _EDGES: tuple[str, str, str, str] = ("left", "top", "right", "bottom");

glob _TOP_LEFT: tuple[str, str] = ("top", "left");

glob _ZEROS: tuple[int, int, int, int] = (0, 0, 0, 0);

def flatten_tree(`root: Dict[builtins.str, Any]) -> list[any] {
    results: list[any] = [`root];
    for child in `root.get("children") or [] {
        results.extend(flatten_tree(child));
    }
    return results;
}

def get_element_center(`node: Dict[builtins.str, Any]) -> Tuple[builtins.int, builtins.int] {
    # One dynamic read of bounds.get, not four.
    (left, top, right, bottom) = map(`node.get("boundsInScreen", {}).get, _EDGES, _ZEROS) as any;

    center_x: any = (left + right) // 2;
    center_y: any = (top + bottom) // 2;

    return (center_x, center_y);
}

def sort_by_position(nodes: List[Dict[builtins.str, Any]]) -> List[Dict[builtins.str, Any]] {
    def get_sort_key(`node: Dict) -> Tuple[builtins.int, builtins.int] {
        return `tuple(map(`node.get("boundsInScreen", {}).get, _TOP_LEFT, _ZEROS));
    }

    return sorted(nodes, key=get_sort_key);
}

glob _TEXT_FIELDS: tuple[str, str, str] = ("text", "contentDescription", "hint");

glob _TEXT_DEFAULTS: tuple[str, str, str] = ("", "", "");

"""Composable filters for element search."""
class Filters {
    static def text_matches(pattern: builtins.str | re.Pattern) -> ElementFilter {
        if isinstance(pattern, `str) {
            regex = re.compile(re.escape(pattern), re.IGNORECASE);
            pattern_str = pattern;
        } else {
            regex = pattern;
            pattern_str = pattern.pattern;
        }

        def filter_fn(nodes: List[Dict]) -> List[Dict] {
            all_nodes = [];
            `node: any;
            for `node in nodes {
                all_nodes.extend(flatten_tree(`node));
            }

            results = [];

            for `node in all_nodes {
                # One dynamic read of node.get, not three.
                for field_value in map(`node.get, _TEXT_FIELDS, _TEXT_DEFAULTS) {
                    if not field_value {
                        continue;
                    }
                    if pattern_str == field_value {
                        results.append(`node);
                        break;
                    }
                    if regex.search(field_value) {
                        results.append(`node);
                        break;
                    }
                    normalized: any = field_value.replace("\n", " ");
                    if pattern_str == normalized or regex.search(normalized) {
                        results.append(`node);
                        break;
                    }
                }
            }

            return results;
        }

        return filter_fn;
    }

    static def id_matches(pattern: builtins.str | re.Pattern) -> ElementFilter {
        if isinstance(pattern, `str) {
            regex = re.compile(re.escape(pattern), re.IGNORECASE);
            pattern_str = pattern;
        } else {
            regex = pattern;
            pattern_str = pattern.pattern;
        }

        def filter_fn(nodes: List[Dict]) -> List[Dict] {
            all_nodes = [];
            `node: any;
            for `node in nodes {
                all_nodes.extend(flatten_tree(`node));
            }

            results = [];

            for `node in all_nodes {
                resource_id: any = `node.get("resourceId", "");

                if not resource_id {
                    continue;
                }

                short_id: any = resource_id.split("/")[-1] if "/" in resource_id else resource_id;
                if pattern_str == resource_id or regex.search(resource_id) {
                    results.append(`node);
                    continue;
                }
                if pattern_str == short_id or regex.search(short_id) {
                    results.append(`node);
                }
            }

            return results;
        }

        return filter_fn;
    }

    static def below(anchor_filter: ElementFilter) -> ElementFilter {
        def filter_fn(nodes: List[Dict]) -> List[Dict] {
            anchor_results: any = anchor_filter(nodes);

            if not anchor_results {
                return [];
            }

            anchor: any = anchor_results[0];
            anchor_bounds: any = anchor.get("boundsInScreen", {});
            anchor_bottom: any = anchor_bounds.get("bottom", 0);
            (anchor_center_x, anchor_center_y) = get_element_center(anchor) as any;

            all_nodes = [];
            `node: any;
            for `node in nodes {
                all_nodes.extend(flatten_tree(`node));
            }

            candidates = [];
            for `node in all_nodes {
                if `node == anchor {
                    continue;
                }

                node_bounds: any = `node.get("boundsInScreen", {});
                node_top: any = node_bounds.get("top", 0);

                if node_top > anchor_bottom {
                    (node_center_x, node_center_y) = get_element_center(`node) as any;
                    distance: any = (
                        (node_center_x - anchor_center_x) ** 2
                        + (node_center_y - anchor_center_y) ** 2
                    ) ** 0.5;
                    candidates.append((distance, `node));
                }
            }

            candidates.sort(key=lambda (x) -> any { x[0] });
            return [`node for (dist, `node) in candidates];
        }

        return filter_fn;
    }

    static def above(anchor_filter: ElementFilter) -> ElementFilter {
        def filter_fn(nodes: List[Dict]) -> List[Dict] {
            anchor_results: any = anchor_filter(nodes);

            if not anchor_results {
                return [];
            }

            anchor: any = anchor_results[0];
            anchor_bounds: any = anchor.get("boundsInScreen", {});
            anchor_top: any = anchor_bounds.get("top", 0);
            (anchor_center_x, anchor_center_y) = get_element_center(anchor) as any;

            all_nodes = [];
            `node: any;
            for `node in nodes {
                all_nodes.extend(flatten_tree(`node));
            }

            candidates = [];
            for `node in all_nodes {
                if `node == anchor {
                    continue;
                }

                node_bounds: any = `node.get("boundsInScreen", {});
                node_bottom: any = node_bounds.get("bottom", 0);

                if node_bottom < anchor_top {
                    (node_center_x, node_center_y) = get_element_center(`node) as any;
                    distance: any = (
                        (node_center_x - anchor_center_x) ** 2
                        + (node_center_y - anchor_center_y) ** 2
                    ) ** 0.5;
                    candidates.append((distance, `node));
                }
            }

            candidates.sort(key=lambda (x) -> any { x[0] });
            return [`node for (dist, `node) in candidates];
        }

        return filter_fn;
    }

    static def left_of(anchor_filter: ElementFilter) -> ElementFilter {
        def filter_fn(nodes: List[Dict]) -> List[Dict] {
            anchor_results: any = anchor_filter(nodes);

            if not anchor_results {
                return [];
            }

            anchor: any = anchor_results[0];
            anchor_bounds: any = anchor.get("boundsInScreen", {});
            anchor_left: any = anchor_bounds.get("left", 0);
            (anchor_center_x, anchor_center_y) = get_element_center(anchor) as any;

            all_nodes = [];
            `node: any;
            for `node in nodes {
                all_nodes.extend(flatten_tree(`node));
            }

            candidates = [];
            for `node in all_nodes {
                if `node == anchor {
                    continue;
                }

                node_bounds: any = `node.get("boundsInScreen", {});
                node_right: any = node_bounds.get("right", 0);

                if node_right < anchor_left {
                    (node_center_x, node_center_y) = get_element_center(`node) as any;
                    distance: any = (
                        (node_center_x - anchor_center_x) ** 2
                        + (node_center_y - anchor_center_y) ** 2
                    ) ** 0.5;
                    candidates.append((distance, `node));
                }
            }

            candidates.sort(key=lambda (x) -> any { x[0] });
            return [`node for (dist, `node) in candidates];
        }

        return filter_fn;
    }

    static def right_of(anchor_filter: ElementFilter) -> ElementFilter {
        def filter_fn(nodes: List[Dict]) -> List[Dict] {
            anchor_results: any = anchor_filter(nodes);

            if not anchor_results {
                return [];
            }

            anchor: any = anchor_results[0];
            anchor_bounds: any = anchor.get("boundsInScreen", {});
            anchor_right: any = anchor_bounds.get("right", 0);
            (anchor_center_x, anchor_center_y) = get_element_center(anchor) as any;

            all_nodes = [];
            `node: any;
            for `node in nodes {
                all_nodes.extend(flatten_tree(`node));
            }

            candidates = [];
            for `node in all_nodes {
                if `node == anchor {
                    continue;
                }

                node_bounds: any = `node.get("boundsInScreen", {});
                node_left: any = node_bounds.get("left", 0);

                if node_left > anchor_right {
                    (node_center_x, node_center_y) = get_element_center(`node) as any;
                    distance: any = (
                        (node_center_x - anchor_center_x) ** 2
                        + (node_center_y - anchor_center_y) ** 2
                    ) ** 0.5;
                    candidates.append((distance, `node));
                }
            }

            candidates.sort(key=lambda (x) -> any { x[0] });
            return [`node for (dist, `node) in candidates];
        }

        return filter_fn;
    }

    static def clickable -> ElementFilter {
        def filter_fn(nodes: List[Dict]) -> List[Dict] {
            all_nodes = [];
            for `node in nodes {
                all_nodes.extend(flatten_tree(`node));
            }

            return [`node for `node in all_nodes if `node.get("isClickable", False)];
        }

        return filter_fn;
    }

    static def non_clickable -> ElementFilter {
        def filter_fn(nodes: List[Dict]) -> List[Dict] {
            all_nodes = [];
            for `node in nodes {
                all_nodes.extend(flatten_tree(`node));
            }

            return [`node for `node in all_nodes if not `node.get("isClickable", False)];
        }

        return filter_fn;
    }

    static def enabled(expected: builtins.bool = True) -> ElementFilter {
        def filter_fn(nodes: List[Dict]) -> List[Dict] {
            all_nodes = [];
            for `node in nodes {
                all_nodes.extend(flatten_tree(`node));
            }

            return [`node for `node in all_nodes if `node.get("isEnabled", False) == expected];
        }

        return filter_fn;
    }

    static def selected(expected: builtins.bool = True) -> ElementFilter {
        def filter_fn(nodes: List[Dict]) -> List[Dict] {
            all_nodes = [];
            for `node in nodes {
                all_nodes.extend(flatten_tree(`node));
            }

            return [`node for `node in all_nodes if `node.get("isSelected", False) == expected];
        }

        return filter_fn;
    }

    static def checked(expected: builtins.bool = True) -> ElementFilter {
        def filter_fn(nodes: List[Dict]) -> List[Dict] {
            all_nodes = [];
            for `node in nodes {
                all_nodes.extend(flatten_tree(`node));
            }

            return [`node for `node in all_nodes if `node.get("isChecked", False) == expected];
        }

        return filter_fn;
    }

    static def focused(expected: builtins.bool = True) -> ElementFilter {
        def filter_fn(nodes: List[Dict]) -> List[Dict] {
            all_nodes = [];
            for `node in nodes {
                all_nodes.extend(flatten_tree(`node));
            }

            return [`node for `node in all_nodes if `node.get("isFocused", False) == expected];
        }

        return filter_fn;
    }

    static def size_matches(
        width: builtins.int = None, height: builtins.int = None, tolerance: builtins.int = 0
    ) -> ElementFilter {
        def filter_fn(nodes: List[Dict]) -> List[Dict] {
            all_nodes = [];
            `node: any;
            for `node in nodes {
                all_nodes.extend(flatten_tree(`node));
            }

            results = [];
            for `node in all_nodes {
                bounds: any = `node.get("boundsInScreen", {});

                actual_width: any = bounds.get("right", 0) - bounds.get("left", 0);
                actual_height: any = bounds.get("bottom", 0) - bounds.get("top", 0);

                if width is not None {
                    if abs(actual_width - width) > tolerance {
                        continue;
                    }
                }

                if height is not None {
                    if abs(actual_height - height) > tolerance {
                        continue;
                    }
                }

                results.append(`node);
            }

            return results;
        }

        return filter_fn;
    }

    static def contains_child(child_filter: ElementFilter) -> ElementFilter {
        def filter_fn(nodes: List[Dict]) -> List[Dict] {
            all_nodes = [];
            `node: any;
            for `node in nodes {
                all_nodes.extend(flatten_tree(`node));
            }

            results = [];

            for `node in all_nodes {
                children: any = `node.get("children") or [];

                if not children {
                    continue;
                }

                matching_children: any = child_filter(children);

                if matching_children {
                    results.append(`node);
                }
            }

            return results;
        }

        return filter_fn;
    }

    static def contains_descendants(filters: List[ElementFilter]) -> ElementFilter {
        def filter_fn(nodes: List[Dict]) -> List[Dict] {
            all_nodes = [];
            `node: any;
            for `node in nodes {
                all_nodes.extend(flatten_tree(`node));
            }

            results = [];

            for `node in all_nodes {
                descendants: any = flatten_tree(`node);

                all_match: any = True;

                for descendant_filter in filters {
                    matches: any = descendant_filter(descendants);

                    if not matches {
                        all_match = False;
                        break;
                    }
                }

                if all_match {
                    results.append(`node);
                }
            }

            return results;
        }

        return filter_fn;
    }

    static def child_of(parent_filter: ElementFilter) -> ElementFilter {
        def filter_fn(nodes: List[Dict]) -> List[Dict] {
            parents: any = parent_filter(nodes);

            if not parents {
                return [];
            }

            results: any = [];
            for parent in parents {
                results.extend(parent.get("children") or []);
            }

            return results;
        }

        return filter_fn;
    }

    static def has_text -> ElementFilter {
        def filter_fn(nodes: List[Dict]) -> List[Dict] {
            all_nodes = [];
            for `node in nodes {
                all_nodes.extend(flatten_tree(`node));
            }

            return [
                `node
                for `node in all_nodes
                if `any(map(`node.get, _TEXT_FIELDS))
            ];
        }

        return filter_fn;
    }

    static def clickable_first -> ElementFilter {
        def filter_fn(nodes: List[Dict]) -> List[Dict] {
            all_nodes = [];
            for `node in nodes {
                all_nodes.extend(flatten_tree(`node));
            }

            return sorted(all_nodes, key=lambda (n) -> any { not n.get("isClickable", False) });
        }

        return filter_fn;
    }

    static def index(idx: builtins.int) -> ElementFilter {
        def filter_fn(nodes: List[Dict]) -> List[Dict] {
            all_nodes = [];
            for `node in nodes {
                all_nodes.extend(flatten_tree(`node));
            }

            sorted_nodes: any = sort_by_position(all_nodes);

            try {
                return [sorted_nodes[idx]];
            } except IndexError {
                return [];
            }
        }

        return filter_fn;
    }

    static def compose(filters: List[ElementFilter]) -> ElementFilter {
        def filter_fn(nodes: List[Dict]) -> List[Dict] {
            result: any = nodes;

            for f in filters {
                result = f(result);

                if not result {
                    break;
                }
            }

            return result;
        }

        return filter_fn;
    }

    static def intersect(filters: List[ElementFilter]) -> ElementFilter {
        def filter_fn(nodes: List[Dict]) -> List[Dict] {
            if not filters {
                return nodes;
            }

            result_sets: any = [`set(id(n) for n in filters[0](nodes))];

            for f in filters[1:] {
                result_ids: any = `set(id(n) for n in f(nodes));
                result_sets.append(result_ids);
            }

            common_ids: any = result_sets[0].intersection(*result_sets[1:]);

            all_nodes = [];
            for `node in nodes {
                all_nodes.extend(flatten_tree(`node));
            }

            return [n for n in all_nodes if id(n) in common_ids];
        }

        return filter_fn;
    }

    static def deepest_matching(base_filter: ElementFilter) -> ElementFilter {
        def find_deepest_in_node(`node: Dict) -> list[any] {
            child_matches: list[any] = [];
            for child in `node.get("children") or [] {
                child_matches.extend(find_deepest_in_node(child));
            }

            if child_matches {
                return child_matches;
            }

            current_matches: any = base_filter([`node]);
            if current_matches {
                return [`node];
            }

            return [];
        }

        def filter_fn(nodes: List[Dict]) -> List[Dict] {
            results = [];

            for `node in nodes {
                results.extend(find_deepest_in_node(`node));
            }

            return results;
        }

        return filter_fn;
    }
}
