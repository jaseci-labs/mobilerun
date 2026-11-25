import builtins;

import from typing { Any, Dict, List, Optional, Tuple }

"""Format tree in the standard Mobilerun format."""
class IndexedFormatter(TreeFormatter) {
    def init {
        self.screen_width = None;
        self.screen_height = None;
        self.use_normalized = False;
        self.display_scale_x = 1.0;
        self.display_scale_y = 1.0;
    }

    def format(
        filtered_tree: Optional[Dict[builtins.str, Any]], phone_state: Dict[builtins.str, Any]
    ) -> Tuple[builtins.str, builtins.str, List[Dict[builtins.str, Any]], Dict[builtins.str, Any]] {
        focused_text: any = self._get_focused_text(phone_state);

        if filtered_tree is None {
            a11y_tree: any = [];
        } else {
            a11y_tree = self._flatten_with_index(filtered_tree, [1]);
        }

        phone_state_text: any = self._format_phone_state(phone_state);
        ui_elements_text: any = self._format_ui_elements_text(a11y_tree);

        formatted_text: any = f"{phone_state_text}\n\n{ui_elements_text}";

        return (formatted_text, focused_text, a11y_tree, phone_state);
    }

    static def _get_focused_text(phone_state: Dict[builtins.str, Any]) -> builtins.str {
        focused_element: any = phone_state.get("focusedElement");
        if focused_element {
            return focused_element.get("text", "");
        }
        return "";
    }

    static def _format_phone_state(phone_state: Dict[builtins.str, Any]) -> builtins.str {
        if isinstance(phone_state, `dict) and "error" not in phone_state {
            current_app: any = phone_state.get("currentApp", "");
            package_name: any = phone_state.get("packageName", "");
            focused_element: any = phone_state.get("focusedElement");
            is_editable: any = phone_state.get("isEditable", False);

            if focused_element and focused_element.get("text") {
                focused_desc: any = "'" + format(focused_element.get("text", ""), "") + "'";
            } else {
                focused_desc = "''";
            }
            if current_app and package_name {
                app_line: any = f"• **App:** {current_app} ({package_name})";
            } elif current_app {
                app_line = f"• **App:** {current_app}";
            } elif package_name {
                app_line = f"• **App:** {package_name}";
            } else {
                app_line = "";
            }

            lines: any = ["**Current Phone State:**"];
            if app_line {
                lines.append(app_line);
            }
            lines.append("• **Keyboard:** " + format("Visible" if is_editable else "Hidden", ""));
            lines.append(f"• **Focused Element:** {focused_desc}");

            phone_state_text: any = "\n".join(lines);
        } elif isinstance(phone_state, `dict) and "error" in phone_state {
            phone_state_text = "📱 **Phone State Error:** "
                + format(phone_state.get("message", "Unknown error"), "");
        } else {
            phone_state_text = f"📱 **Phone State:** {phone_state}";
        }

        return phone_state_text;
    }

    def _format_ui_elements_text(a11y_tree: List[Dict[builtins.str, Any]]) -> builtins.str {
        normalized: any = self.use_normalized and self.screen_width and self.screen_height;
        coord_note: any = " (normalized [0-1000])" if normalized else "";
        schema: any = "'index. className: resourceId; checkedState, text - bounds(x1,y1,x2,y2)'";
        if a11y_tree {
            formatted_ui: any = IndexedFormatter._format_ui_elements(a11y_tree);
            ui_elements_text: any = f"Current Clickable UI elements{coord_note}:\n{schema}:\n{formatted_ui}";
        } else {
            ui_elements_text = f"Current Clickable UI elements{coord_note}:\n{schema}:\nNo UI elements found";
        }
        return ui_elements_text;
    }

    static def _format_ui_elements(
        ui_data: List[Dict[builtins.str, Any]], level: builtins.int = 0
    ) -> builtins.str {
        if not ui_data {
            return "";
        }

        formatted_lines: any = [];
        indent: any = "  " * level;

        elements: any = ui_data if isinstance(ui_data, `list) else [ui_data];

        for element in elements {
            if not isinstance(element, `dict) {
                continue;
            }

            index: any = element.get("index", "");
            class_name: any = element.get("className", "");
            resource_id: any = element.get("resourceId", "");
            text: any = element.get("text", "");
            bounds: any = element.get("displayBounds") or element.get("bounds", "");
            checkedState: any = element.get("checkedState", "");
            children: any = element.get("children") or [];

            line_parts: any = [];
            if index != "" {
                line_parts.append(f"{index}.");
            }
            if class_name {
                line_parts.append(class_name + ":");
            }

            details: any = [];
            if resource_id {
                details.append(f"\"{resource_id}\"");
            }
            if text {
                details.append(f"\"{text}\"");
            }

            if details {
                line_parts.append(", ".join(details));
            }

            if checkedState {
                line_parts.append(f"; {checkedState}");
            }

            if bounds {
                line_parts.append(f"- ({bounds})");
            }

            formatted_line: any = format(indent, "") + format(" ".join(line_parts), "");
            formatted_lines.append(formatted_line);

            if children {
                child_formatted: any = IndexedFormatter._format_ui_elements(children, level + 1);
                if child_formatted {
                    formatted_lines.append(child_formatted);
                }
            }
        }

        return "\n".join(formatted_lines);
    }

    def _flatten_with_index(
        `node: Dict[builtins.str, Any], counter: List[builtins.int]
    ) -> List[Dict[builtins.str, Any]] {
        results: any = [];

        formatted: any = self._format_node(`node, counter[0]);
        results.append(formatted);
        counter[0] += 1;

        siblings: any = [];
        for child in `node.get("children") or [] {
            descendants: any = self._flatten_with_index(child, counter);
            siblings.append((child, descendants[0]));
            results.extend(descendants);
        }

        self._add_tap_blockers(siblings);

        return results;
    }

    static def _add_tap_blockers(
        siblings: List[Tuple[Dict[builtins.str, Any], Dict[builtins.str, Any]]]
    ) -> None {
        for (raw, formatted) in siblings {
            order: any = raw.get("drawingOrder");
            window: any = raw.get("windowId");
            if not isinstance(order, `int) or not isinstance(window, `int) or window < 0 {
                continue;
            }
            bounds: any = `tuple(map(int, formatted["bounds"].split(",")));
            blockers: any = [];
            for (other, candidate) in siblings {
                other_order: any = other.get("drawingOrder");
                if other.get("windowId") != window
                    or not isinstance(other_order, `int)
                    or other_order <= order
                    or other.get("isVisibleToUser") is False
                    or not (other.get("isClickable") or other.get("isLongClickable"))
                {
                    continue;
                }
                candidate_bounds: any = `tuple(map(int, candidate["bounds"].split(",")));
                if rects_overlap(bounds, candidate_bounds) {
                    blockers.append(candidate["bounds"]);
                }
            }
            if blockers {
                formatted["tapBlockers"] = blockers;
            }
        }
    }

    def _format_node(
        `node: Dict[builtins.str, Any], index: builtins.int
    ) -> Dict[builtins.str, Any] {
        bounds: any = `node.get("boundsInScreen", {});
        bounds_str: any = format(bounds.get("left", 0), "")
            + ","
            + format(bounds.get("top", 0), "")
            + ","
            + format(bounds.get("right", 0), "")
            + ","
            + format(bounds.get("bottom", 0), "");

        display_bounds_str: any = None;
        if self.use_normalized and self.screen_width and self.screen_height {
            display_bounds_str = bounds_to_normalized(
                bounds_str, self.screen_width, self.screen_height
            );
        } elif self.display_scale_x != 1.0 or self.display_scale_y != 1.0 {
            display_bounds_str = ",".join(
                `str(round(value / scale))
                for (value, scale) in builtins.zip(
                    (`int(part) for part in bounds_str.split(",")),
                    (
                        self.display_scale_x,
                        self.display_scale_y,
                        self.display_scale_x,
                        self.display_scale_y,
                    ),
                    strict=True,
                ),
            );
        }

        text: any = `node.get("text")
            or `node.get("contentDescription")
            or `node.get("resourceId")
            or `node.get("className", "");

        class_name: any = `node.get("className", "");
        short_class: any = class_name.split(".")[-1] if class_name else "";

        checked_state: any = "";
        if `node.get("isCheckable") {
            checked_state = "isChecked=True" if `node.get("isChecked") else "isChecked=False";
        }

        formatted: any = {
            "index": index,
            "resourceId": `node.get("resourceId", ""),
            "className": short_class,
            "checkedState": checked_state,
            "text": text,
            "bounds": bounds_str,
            "children": [],
        };
        if display_bounds_str is not None {
            formatted["displayBounds"] = display_bounds_str;
        }
        return formatted;
    }
}
