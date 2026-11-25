import builtins;

glob NORMALIZED_MAX: any = 1000;

glob NORMALIZED_STATE_NOTE: any = "All coordinates in this device state (element bounds above, and any x/y you provide to coordinate actions) are normalized 0-1000 on both axes, whatever the screenshot size: (0,0) is the top-left, (500,500) the center and (1000,1000) the bottom-right of the screen.";

def to_absolute(
    x: builtins.int, y: builtins.int, width: builtins.int, height: builtins.int
) -> builtins.tuple[builtins.int, builtins.int] {
    if width is None or height is None {
        raise ValueError("Screen dimensions not available. Call get_state() first.");
    }
    return (`int(x * width / NORMALIZED_MAX), `int(y * height / NORMALIZED_MAX));
}

def to_normalized(
    x: builtins.int, y: builtins.int, width: builtins.int, height: builtins.int
) -> builtins.tuple[builtins.int, builtins.int] {
    if width is None or height is None {
        raise ValueError("Screen dimensions not available. Call get_state() first.");
    }
    return (`int(x * NORMALIZED_MAX / width), `int(y * NORMALIZED_MAX / height));
}

def bounds_to_normalized(
    bounds_str: builtins.str, width: builtins.int, height: builtins.int
) -> builtins.str {
    (left, top, right, bottom) = map(int, bounds_str.split(",")) as any;
    (n_left, n_top) = to_normalized(left, top, width, height) as any;
    (n_right, n_bottom) = to_normalized(right, bottom, width, height) as any;
    return f"{n_left},{n_top},{n_right},{n_bottom}";
}
