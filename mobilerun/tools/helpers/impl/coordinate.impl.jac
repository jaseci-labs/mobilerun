impl to_absolute(
    x: builtins.int, y: builtins.int, width: builtins.int, height: builtins.int
) -> builtins.tuple[builtins.int, builtins.int] {
    if width is None or height is None {
        raise ValueError("Screen dimensions not available. Call get_state() first.");
    }
    return (`int(x * width / NORMALIZED_MAX), `int(y * height / NORMALIZED_MAX));
}

impl to_normalized(
    x: builtins.int, y: builtins.int, width: builtins.int, height: builtins.int
) -> builtins.tuple[builtins.int, builtins.int] {
    if width is None or height is None {
        raise ValueError("Screen dimensions not available. Call get_state() first.");
    }
    return (`int(x * NORMALIZED_MAX / width), `int(y * NORMALIZED_MAX / height));
}

impl bounds_to_normalized(
    bounds_str: builtins.str, width: builtins.int, height: builtins.int
) -> builtins.str {
    left: any;
    top: any;
    right: any;
    bottom: any;
    (left, top, right, bottom) = map(int, bounds_str.split(",")) as any;
    n_left: any;
    n_top: any;
    (n_left, n_top) = to_normalized(left, top, width, height) as any;
    n_right: any;
    n_bottom: any;
    (n_right, n_bottom) = to_normalized(right, bottom, width, height) as any;
    return f"{n_left},{n_top},{n_right},{n_bottom}";
}
