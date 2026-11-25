impl ScreenshotOnlyStateProvider.init(
    driver: "DeviceDriver", vision_resize_policy: Any = None, use_normalized: bool = False
) {
    super.init(driver);
    self.vision_resize_policy = vision_resize_policy;
    self.use_normalized = use_normalized;
    self.model_screenshot_grid = not use_normalized;
    self.model_screenshot_width = None;
    self.model_screenshot_height = None;
}

impl ScreenshotOnlyStateProvider.get_state -> UIState {
    screenshot: any = (await self.driver.screenshot());
    (native_width, native_height) = image_dimensions(screenshot) as any;
    input_size: any = getattr(self.driver, "input_coordinate_size", None);
    if input_size is None {
        (input_width, input_height) = (native_width, native_height);
    } else {
        (input_width, input_height) = (await input_size(native_width, native_height)) as any;
    }
    if self.vision_resize_policy is not None {
        (screen_width, screen_height) = self.vision_resize_policy.effective_dims(
            native_width, native_height
        ) as any;
    } else {
        (screen_width, screen_height) = fit_dimensions_to_max_side(
            native_width, native_height
        ) as any;
    }
    self.model_screenshot_width = screen_width;
    self.model_screenshot_height = screen_height;
    phone_state: any = {"observationMode": "screenshot_only", "accessibilityTree": False};

    if self.use_normalized {
        return UIState(
            elements=[],
            formatted_text=f"Screenshot-only mode is active. There is no accessibility tree or element index list. Inspect the screenshot and use coordinate actions in normalized coordinates: both axes run from 0 to 1000 across the screenshot, whatever the image size, so (0,0) is top-left, (500,500) is the center and (1000,1000) is bottom-right. {_SCREENSHOT_ONLY_GUIDANCE}",
            focused_text="",
            phone_state=phone_state,
            screen_width=input_width,
            screen_height=input_height,
            use_normalized=True,
            model_screenshot_width=screen_width,
            model_screenshot_height=screen_height,
        );
    }

    max_x: any = max(screen_width - 1, 0);
    max_y: any = max(screen_height - 1, 0);
    return UIState(
        elements=[],
        formatted_text=f"Screenshot-only mode is active. There is no accessibility tree or element index list. Inspect the screenshot and use coordinate actions in the screenshot pixel coordinates shown to the model. The screenshot includes a coordinate grid for visual reference; use the underlying screenshot pixel coordinates, not grid-cell numbers. The screenshot shown to the model is {screen_width}x{screen_height}; (0,0) is top-left and ({max_x},{max_y}) is bottom-right. {_SCREENSHOT_ONLY_GUIDANCE}",
        focused_text="",
        phone_state=phone_state,
        screen_width=screen_width,
        screen_height=screen_height,
        use_normalized=False,
        coordinate_scale_x=input_width / screen_width,
        coordinate_scale_y=input_height / screen_height,
        model_screenshot_width=screen_width,
        model_screenshot_height=screen_height,
    );
}
