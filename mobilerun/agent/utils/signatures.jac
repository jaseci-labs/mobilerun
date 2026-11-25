"""Tool registry builder — single place for all standard mobilerun tools."""

import builtins;

import logging;

glob logger: any;

with entry {
    logger = logging.getLogger("mobilerun");
}

"""Build a ToolRegistry with all standard mobilerun tools.

    Args:
        supported_buttons: Buttons available for system_button description.
            Defaults to ``{"back", "home", "enter"}`` if *None*.
        credential_manager: If provided and has keys, ``type_secret`` is registered.
        platform: ``"android"`` or ``"ios"``. Controls which ``open_app``
            implementation is registered unless exact_app_launch is enabled.
        exact_app_launch: Register ``open_app`` as an exact app identifier
            launcher that only depends on ``start_app``.
        screenshot_only: When true, coordinate tool descriptions refer to the
            screenshot shown to the model. Normal mode keeps generic wording.
        normalized_coordinates: With ``screenshot_only``, describe coordinates
            as 0-1000 on both screenshot axes instead of screenshot pixels.

    Returns:
        ``(registry, standard_tool_names)`` where *standard_tool_names* is the
        set of tool names registered here.  The ManagerAgent uses this to
        exclude already-described tools from its ``<custom_actions>`` prompt
        section.  User/MCP tools added later by MobileAgent will NOT be in
        this set, so they correctly appear in ``<custom_actions>``.
    """
async def build_tool_registry(
    supported_buttons: builtins.set[builtins.str] | None = None,
    credential_manager=None,
    platform: builtins.str = "android",
    exact_app_launch: builtins.bool = False,
    screenshot_only: builtins.bool = False,
    normalized_coordinates: builtins.bool = False,
) -> builtins.tuple[ToolRegistry, builtins.set[builtins.str]];
