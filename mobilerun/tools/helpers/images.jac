"""Small image helpers used by screenshot-only device backends."""

import operator;

import from __future__ { annotations }

import math;

import struct;

import from io { BytesIO }

import from PIL { Image, ImageDraw, ImageFont }

glob MODEL_SCREENSHOT_MAX_SIDE: any = 2048;

"""Dimensions Anthropic will resize an image to before the model sees it.

    Mirrors Anthropic's documented rule: images are split into 28x28 visual
    tokens; the image is shrunk (preserving aspect) until every edge is
    ``<= max_edge`` AND the token count ``<= max_tokens``. ``(max_edge,
    max_tokens)`` is ``(1568, 1568)`` for standard models and ``(2576, 4784)``
    for high-resolution models (Opus 4.7+, etc.).
    """
def anthropic_resized_size(
    width: int, height: int, max_edge: int, max_tokens: int
) -> tuple[int, int];

"""Return ``(width, height)`` for PNG or JPEG bytes."""
def image_dimensions(image: bytes) -> tuple[int, int];

glob max_side_default_: any;

with entry {
    max_side_default_ = MODEL_SCREENSHOT_MAX_SIDE;
}

"""Return dimensions scaled down so the longest side is at most ``max_side``."""
def fit_dimensions_to_max_side(
    width: int, height: int, max_side: int = max_side_default_
) -> tuple[int, int];

glob max_side_default__: any;

with entry {
    max_side_default__ = MODEL_SCREENSHOT_MAX_SIDE;
}

"""Resize image bytes to the same coordinate space exposed to vision agents."""
def resize_image_to_max_side(image: bytes, max_side: int = max_side_default__) -> bytes;

glob max_side_default___: any;

with entry {
    max_side_default___ = MODEL_SCREENSHOT_MAX_SIDE;
}

"""Resize image and overlay a model-only coordinate grid."""
def resize_image_to_max_side_with_grid(
    image: bytes, max_side: int = max_side_default___, divisions: int = 10
) -> bytes;

"""Resize image to exact ``target_width``x``target_height`` and overlay the grid.

    Used by the vision coordinate contract so the image the model receives
    matches the declared coordinate space exactly.
    """
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
