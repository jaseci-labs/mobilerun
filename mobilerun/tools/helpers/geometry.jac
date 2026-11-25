"""Geometry utilities for UI element bounds and tap point calculation."""

import builtins;

import operator;

import from typing { List, Optional, Tuple }

glob Bounds: any;

with entry {
    Bounds = Tuple[int, int, int, int];
}

"""Check if two rectangles overlap."""
def rects_overlap(a: Bounds, b: Bounds) -> builtins.bool;

"""Return the center of the largest remaining rectangle, including narrow gaps."""
def find_uncovered_point(
    bounds: Bounds, blockers: List[Bounds]
) -> Optional[Tuple[builtins.int, builtins.int]];

"""Find a clear point in bounds using quadrant subdivision."""
def find_clear_point(
    bounds: Bounds, blockers: List[Bounds], depth: builtins.int = 0
) -> Optional[Tuple[builtins.int, builtins.int]];
