import builtins;

import from __future__ { annotations }

import random;

import from typing { Tuple }

obj StealthUIState(UIState) {
    def get_element_coords(index: int) -> Tuple[int, int];
    def get_clear_point(index: int) -> Tuple[int, int];

    def __repr__ -> str;

    def __eq__(other: any) -> bool;

    def __hash__ -> int;
}
