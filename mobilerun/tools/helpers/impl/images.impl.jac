impl anthropic_resized_size(
    width: int, height: int, max_edge: int, max_tokens: int
) -> tuple[int, int] {
    if width <= 0 or height <= 0 {
        raise ValueError("Image dimensions must be positive.");
    }

    def tokens(w: int, h: int) -> int {
        return math.ceil(w / 28) * math.ceil(h / 28);
    }

    def fits(w: int, h: int) -> bool {
        return operator.le(math.ceil(w / 28) * 28, max_edge)
            and operator.le(math.ceil(h / 28) * 28, max_edge)
            and operator.le(tokens(w, h), max_tokens);
    }

    if fits(width, height) {
        return (width, height);
    }
    if height > width {
        rw: any;
        rh: any;
        (rw, rh) = anthropic_resized_size(height, width, max_edge, max_tokens) as any;
        return (rh, rw);
    }

    aspect: any = width / height;
    lo: any;
    hi: any;
    (lo, hi) = (1, width);
    while lo + 1 < hi {
        mid: any = (lo + hi) // 2;
        if fits(mid, max(round(mid / aspect), 1)) {
            lo = mid;
        } else {
            hi = mid;
        }
    }
    return (lo, max(round(lo / aspect), 1));
}

impl image_dimensions(image: bytes) -> tuple[int, int] {
    if image.startswith(b"\x89PNG\r\n\x1a\n") and len(image) >= 24 {
        width: any;
        height: any;
        (width, height) = struct.unpack(">II", image[16:24]) as any;
        return (`int(width), `int(height));
    }

    if image.startswith(b"\xff\xd8") {
        return _jpeg_dimensions(image);
    }

    raise ValueError("Unsupported screenshot image format. Expected PNG or JPEG.");
}

impl fit_dimensions_to_max_side(
    width: int, height: int, max_side: int = max_side_default_
) -> tuple[int, int] {
    if width <= 0 or height <= 0 {
        raise ValueError("Image dimensions must be positive.");
    }
    if max(width, height) <= max_side {
        return (width, height);
    }

    scale: any = max_side / max(width, height);
    return (max(1, round(width * scale)), max(1, round(height * scale)));
}

impl resize_image_to_max_side(image: bytes, max_side: int = max_side_default__) -> bytes {
    width: any;
    height: any;
    (width, height) = image_dimensions(image) as any;
    target_width: any;
    target_height: any;
    (target_width, target_height) = fit_dimensions_to_max_side(width, height, max_side) as any;
    if (target_width, target_height) == (width, height) {
        return image;
    }

    source: any;
    with Image.open(BytesIO(image)) as source {
        resized: any = source.convert("RGBA").resize(
            (target_width, target_height), Image.Resampling.LANCZOS
        );
        output: any = BytesIO();
        resized.save(output, format="PNG");
        return output.getvalue();
    }
}

impl resize_image_to_max_side_with_grid(
    image: bytes, max_side: int = max_side_default___, divisions: int = 10
) -> bytes {
    width: any;
    height: any;
    (width, height) = image_dimensions(image) as any;
    target_width: any;
    target_height: any;
    (target_width, target_height) = fit_dimensions_to_max_side(width, height, max_side) as any;
    return resize_image_to_dimensions_with_grid(
        image, target_width, target_height, divisions=divisions
    );
}

impl resize_image_to_dimensions_with_grid(
    image: bytes, target_width: int, target_height: int, divisions: int = 10
) -> bytes {
    width: any;
    height: any;
    (width, height) = image_dimensions(image) as any;
    source: any;
    with Image.open(BytesIO(image)) as source {
        screenshot: any = source.convert("RGBA");
        if (target_width, target_height) != (width, height) {
            screenshot = screenshot.resize((target_width, target_height), Image.Resampling.LANCZOS);
        }

        _draw_coordinate_grid(screenshot, divisions=divisions);
        output: any = BytesIO();
        screenshot.save(output, format="PNG");
        return output.getvalue();
    }
}

impl _draw_coordinate_grid(image: Image.Image, divisions: int) -> None {
    width: any;
    height: any;
    (width, height) = image.size as any;
    if divisions <= 0 or width <= 0 or height <= 0 {
        return;
    }

    overlay: any = Image.new("RGBA", image.size, (0, 0, 0, 0));
    draw: any = ImageDraw.Draw(overlay);
    font: any = ImageFont.load_default();

    line_color: any = (255, 255, 255, 68);
    major_line_color: any = (255, 230, 120, 110);
    label_fill: any = (255, 255, 255, 230);
    label_shadow: any = (0, 0, 0, 190);
    label_bg: any = (0, 0, 0, 115);

    for index in range(divisions + 1) {
        x: any = round(index * (width - 1) / divisions);
        y: any = round(index * (height - 1) / divisions);
        color: any = major_line_color if index in {0, divisions // 2, divisions} else line_color;
        draw.line([(x, 0), (x, height - 1)], fill=color, width=1);
        draw.line([(0, y), (width - 1, y)], fill=color, width=1);
        _draw_grid_label(
            draw, f"x={x}", (min(x + 3, width - 38), 4), font, label_fill, label_shadow, label_bg
        );
        _draw_grid_label(
            draw, f"y={y}", (4, min(y + 3, height - 14)), font, label_fill, label_shadow, label_bg
        );
    }

    image.alpha_composite(overlay);
}

impl _draw_grid_label(
    draw: ImageDraw.ImageDraw,
    text: str,
    position: tuple[int, int],
    font: ImageFont.ImageFont,
    fill: tuple[int, int, int, int],
    shadow: tuple[int, int, int, int],
    background: tuple[int, int, int, int],
) -> None {
    x: any;
    y: any;
    (x, y) = position as any;
    bbox: any = draw.textbbox((x, y), text, font=font);
    draw.rectangle((bbox[0] - 2, bbox[1] - 1, bbox[2] + 2, bbox[3] + 1), fill=background);
    draw.text((x + 1, y + 1), text, font=font, fill=shadow);
    draw.text((x, y), text, font=font, fill=fill);
}

impl _jpeg_dimensions(image: bytes) -> tuple[int, int] {
    offset: any = 2;
    length: any = len(image);
    while offset + 9 < length {
        if image[offset] != 255 {
            offset += 1;
            continue;
        }

        while offset < length and image[offset] == 255 {
            offset += 1;
        }
        if offset >= length {
            break;
        }

        marker: any = image[offset];
        offset += 1;

        if marker in {216, 217} {
            continue;
        }
        if marker == 218 {
            break;
        }
        if offset + 2 > length {
            break;
        }

        segment_length: any = int.from_bytes(image[offset:offset + 2], "big");
        if segment_length < 2 {
            raise ValueError("Invalid JPEG segment length.");
        }

        if _is_start_of_frame(marker) {
            if offset + 7 > length {
                break;
            }
            height: any = int.from_bytes(image[offset + 3:offset + 5], "big");
            width: any = int.from_bytes(image[offset + 5:offset + 7], "big");
            return (`int(width), `int(height));
        }

        offset += segment_length;
    }

    raise ValueError("Could not read JPEG dimensions.");
}

impl _is_start_of_frame(marker: int) -> bool {
    return marker in {192, 193, 194, 195, 197, 198, 199, 201, 202, 203, 205, 206, 207};
}
