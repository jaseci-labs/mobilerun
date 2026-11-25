impl AppCardProvider.load_app_card(
    package_name: builtins.str, instruction: builtins.str = "", platform: builtins.str | None = None
) -> builtins.str {}

impl DisabledAppCardProvider.load_app_card(
    package_name: builtins.str,
    instruction: builtins.str = "",
    platform: builtins.str | None = None,
) -> builtins.str {
    return "";
}
