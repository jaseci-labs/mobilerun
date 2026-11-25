"""Screenshot-only state provider for visual control backends."""

import builtins;

import from __future__ { annotations }

import from typing { TYPE_CHECKING, Any, Optional }

glob _SCREENSHOT_ONLY_GUIDANCE: any = "Prefer click_at on the center of visible text or controls, especially in dense lists, adjacent rows, and compact menus. Use click_area only for large, unambiguous targets. If a tap does not change the screen, do not repeat the same coordinate; choose a better point on the intended target or use navigation. For text entry, focus a field with a coordinate action first, then use direct text typing.";

"""Build UI state from screenshots without reading an accessibility tree."""
obj ScreenshotOnlyStateProvider(StateProvider) {
    has vision_resize_policy: any,
        use_normalized: any,
        model_screenshot_grid: any,
        model_screenshot_width: any,
        model_screenshot_height: any;

    static has supported: any = {"convert_point", "direct_text_input"};

    static has requires_coordinate_tools: any = True;

    static has resize_model_screenshot: any = True;

    def init(
        driver: "DeviceDriver", vision_resize_policy: Any = None, use_normalized: bool = False
    );

    async def get_state -> UIState;

    def __repr__ -> str;

    def __eq__(other: any) -> bool;

    def __hash__ -> int;
}
