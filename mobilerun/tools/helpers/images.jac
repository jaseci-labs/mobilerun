import operator;

import from __future__ { annotations }

import math;

import struct;

import from io { BytesIO }

import from PIL { Image, ImageDraw, ImageFont }

glob MODEL_SCREENSHOT_MAX_SIDE: any = 2048;

def anthropic_resized_size(
    width: int, height: int, max_edge: int, max_tokens: int
) -> tuple[int, int];

def image_dimensions(image: bytes) -> tuple[int, int];

glob max_side_default_: any = MODEL_SCREENSHOT_MAX_SIDE;

def fit_dimensions_to_max_side(
    width: int, height: int, max_side: int = max_side_default_
) -> tuple[int, int];

glob max_side_default__: any;

with entry {
    max_side_default__ = MODEL_SCREENSHOT_MAX_SIDE;
}

def resize_image_to_max_side(image: bytes, max_side: int = max_side_default__) -> bytes;

glob max_side_default___: any;

with entry {
    max_side_default___ = MODEL_SCREENSHOT_MAX_SIDE;
}

def resize_image_to_max_side_with_grid(
    image: bytes, max_side: int = max_side_default___, divisions: int = 10
) -> bytes;

def resize_image_to_dimensions_with_grid(
    image: bytes, target_width: int, target_height: int, divisions: int = 10
) -> bytes;

def _draw_coordinate_grid(image: Image.Image, divisions: int) -> None;

def _draw_grid_label(
    draw: ImageDraw.ImageDraw,
    text: str,
    position: tuple[int, int],
    font: ImageFont.ImageFont,
    fill: tuple[int, int, int, int],
    shadow: tuple[int, int, int, int],
    background: tuple[int, int, int, int],
) -> None;

def _jpeg_dimensions(image: bytes) -> tuple[int, int];

def _is_start_of_frame(marker: int) -> bool;
