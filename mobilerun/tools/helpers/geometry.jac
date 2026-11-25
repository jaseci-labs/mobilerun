import from typing { Tuple }

# Concrete types keep the CPython emission free of `_jac.held` reads and
# `bool(...)` wraps: these are the agent's per-tap hot loops.
type _Box = tuple[int, int, int, int];

glob Bounds: any = Tuple[int, int, int, int];

"""A "left,top,right,bottom" bounds string as a typed box, so the helpers
below run on typed tuples, with no per-read `held` or per-call `convert`."""
def parse_bounds(bounds_str: str) -> _Box {
    v = [`int(p) for p in bounds_str.split(",")];
    return (v[0], v[1], v[2], v[3]);
}

def rects_overlap(a: _Box, b: _Box) -> bool {
    return not (a[2] <= b[0] or b[2] <= a[0] or a[3] <= b[1] or b[3] <= a[1]);
}

# Untyped on purpose: it is the cold path (a tap that is blocked), and its
# bounds may carry whatever the screen size clamped them to.
def find_uncovered_point(bounds: any, blockers: any) -> any {
    regions = [bounds] if bounds[0] < bounds[2] and bounds[1] < bounds[3] else [];
    for blocker in blockers {
        remaining = [];
        for (left, top, right, bottom) in regions {
            bl = max(left, blocker[0]);
            bt = max(top, blocker[1]);
            br = min(right, blocker[2]);
            bb = min(bottom, blocker[3]);
            if bl >= br or bt >= bb {
                remaining.append((left, top, right, bottom));
                continue;
            }
            for region in (
                (left, top, right, bt),
                (left, bb, right, bottom),
                (left, bt, bl, bb),
                (br, bt, right, bb),
            ) {
                if region[0] < region[2] and region[1] < region[3] {
                    remaining.append(region);
                }
            }
        }
        regions = remaining;
    }
    if not regions {
        return None;
    }
    (left, top, right, bottom) = max(
        regions, key=lambda (r: any) -> any { (r[2] - r[0]) * (r[3] - r[1]) }
    );
    return ((left + right) // 2, (top + bottom) // 2);
}

def find_clear_point(
    bounds: _Box, blockers: list[_Box], depth: int = 0
) -> tuple[int, int] | None {
    (left, top, right, bottom) = bounds;
    (cx, cy) = ((left + right) // 2, (top + bottom) // 2);

    blocked = `any(b[0] <= cx < b[2] and b[1] <= cy < b[3] for b in blockers);

    if not blocked {
        return (cx, cy);
    }

    if depth > 4 or (right - left) * (bottom - top) < 100 {
        return None;
    }

    quadrants: list[_Box] = [
        (left, top, cx, cy),
        (cx, top, right, cy),
        (left, cy, cx, bottom),
        (cx, cy, right, bottom),
    ];

    best_point: tuple[int, int] | None = None;
    best_area = 0;

    for q in quadrants {
        q_area = (q[2] - q[0]) * (q[3] - q[1]);
        if q_area <= 0 {
            continue;
        }
        point = find_clear_point(q, blockers, depth + 1);
        if point and q_area > best_area {
            best_point = point;
            best_area = q_area;
        }
    }

    return best_point;
}
