import builtins;

import logging;

glob logger: any;

with entry {
    logger = logging.getLogger("mobilerun");
}

async def build_tool_registry(
    supported_buttons: builtins.set[builtins.str] | None = None,
    credential_manager=None,
    platform: builtins.str = "android",
    exact_app_launch: builtins.bool = False,
    screenshot_only: builtins.bool = False,
    normalized_coordinates: builtins.bool = False,
) -> builtins.tuple[ToolRegistry, builtins.set[builtins.str]];
