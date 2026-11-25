import builtins;

import from __future__ { annotations }

import random;

import from typing { Tuple }

class StealthUIState(UIState) {
    def get_element_coords(index: int) -> Tuple[int, int] {
        (element, left, top, right, bottom) = self._tappable_bounds(index);

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

    def get_clear_point(index: int) -> Tuple[int, int] {
        (cx, cy) = super.get_clear_point(index) as any;

        element: any = self._find_by_index(self.elements, index);
        bounds_str: any = element.get("bounds", "");
        if not bounds_str {
            return (cx, cy);
        }

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
}
