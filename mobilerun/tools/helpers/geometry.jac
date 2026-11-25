import builtins;

import operator;

import from typing { List, Optional, Tuple }

glob Bounds: any = Tuple[int, int, int, int];

def rects_overlap(a: Bounds, b: Bounds) -> builtins.bool;

def find_uncovered_point(
    bounds: Bounds, blockers: List[Bounds]
) -> Optional[Tuple[builtins.int, builtins.int]];

def find_clear_point(
    bounds: Bounds, blockers: List[Bounds], depth: builtins.int = 0
) -> Optional[Tuple[builtins.int, builtins.int]];
