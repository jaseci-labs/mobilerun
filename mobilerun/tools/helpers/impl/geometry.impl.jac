impl rects_overlap(a: Bounds, b: Bounds) -> builtins.bool {
    return not (a[2] <= b[0] or b[2] <= a[0] or a[3] <= b[1] or b[3] <= a[1]);
}

impl find_uncovered_point(
    bounds: Bounds, blockers: List[Bounds]
) -> Optional[Tuple[builtins.int, builtins.int]] {
    regions: any = [bounds] if bounds[0] < bounds[2] and bounds[1] < bounds[3] else [];
    for blocker in blockers {
        remaining: any = [];
        left: any;
        top: any;
        right: any;
        bottom: any;
        for (left, top, right, bottom) in regions {
            bl: any = max(left, blocker[0]);
            bt: any = max(top, blocker[1]);
            br: any = min(right, blocker[2]);
            bb: any = min(bottom, blocker[3]);
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
        regions, key=lambda (r) -> any { (r[2] - r[0]) * (r[3] - r[1]) }
    ) as any;
    return ((left + right) // 2, (top + bottom) // 2);
}

impl find_clear_point(
    bounds: Bounds, blockers: List[Bounds], depth: builtins.int = 0
) -> Optional[Tuple[builtins.int, builtins.int]] {
    cx: any;
    cy: any;
    left: any;
    top: any;
    right: any;
    bottom: any;
    (left, top, right, bottom) = bounds as any;
    (cx, cy) = ((left + right) // 2, (top + bottom) // 2);

    blocked: any = `any(
        operator.le(b[0], cx)
            and operator.lt(cx, b[2])
            and (operator.le(b[1], cy) and operator.lt(cy, b[3]))
        for b in blockers,
    );

    if not blocked {
        return (cx, cy);
    }

    if depth > 4 or (right - left) * (bottom - top) < 100 {
        return None;
    }

    quadrants: any = [
        (left, top, cx, cy),
        (cx, top, right, cy),
        (left, cy, cx, bottom),
        (cx, cy, right, bottom),
    ];

    best_point: any = None;
    best_area: any = 0;

    for q in quadrants {
        q_area: any = (q[2] - q[0]) * (q[3] - q[1]);
        if q_area <= 0 {
            continue;
        }
        point: any = find_clear_point(q, blockers, depth + 1);
        if point and q_area > best_area {
            best_point = point;
            best_area = q_area;
        }
    }

    return best_point;
}
