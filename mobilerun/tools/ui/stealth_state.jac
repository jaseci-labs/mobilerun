import builtins;

import from __future__ { annotations }

import random;

import from typing { Tuple }

class StealthUIState(UIState) {
    def get_element_coords(index: int) -> Tuple[int, int];
    def get_clear_point(index: int) -> Tuple[int, int];
}
