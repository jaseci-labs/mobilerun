"""Coordinate conversion utilities for normalized [0-1000] coordinates."""

import builtins;

glob NORMALIZED_MAX: any = 1000;

glob NORMALIZED_STATE_NOTE: any = "All coordinates in this device state (element bounds above, and any x/y you provide to coordinate actions) are normalized 0-1000 on both axes, whatever the screenshot size: (0,0) is the top-left, (500,500) the center and (1000,1000) the bottom-right of the screen.";

"""Convert [0-1000] normalized to absolute pixels."""
def to_absolute(
    x: builtins.int, y: builtins.int, width: builtins.int, height: builtins.int
) -> builtins.tuple[builtins.int, builtins.int];

"""Convert absolute pixels to [0-1000] normalized."""
def to_normalized(
    x: builtins.int, y: builtins.int, width: builtins.int, height: builtins.int
) -> builtins.tuple[builtins.int, builtins.int];

"""Convert 'left,top,right,bottom' bounds string to normalized."""
def bounds_to_normalized(
    bounds_str: builtins.str, width: builtins.int, height: builtins.int
) -> builtins.str;
