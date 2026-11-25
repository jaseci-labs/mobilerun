"""
Abstract base class for app card providers.

Providers load app-specific instruction cards based on package names.
Supports multiple backends: local files, remote servers, or composite strategies.
"""

import builtins;

import from abc { ABC, abstractmethod }

"""Abstract interface for loading app-specific instruction cards."""
class AppCardProvider(ABC) {
    """
        Load app card for a given package asynchronously.

        Args:
            package_name: Android package name or iOS bundle id
            instruction: User's instruction/goal (optional context for server providers)
            platform: "android" or "ios", when known

        Returns:
            App card content as string, or empty string if not found or on error
        """
    @abstractmethod
    async def load_app_card(
        package_name: builtins.str,
        instruction: builtins.str = "",
        platform: builtins.str | None = None,
    ) -> builtins.str;
}

"""The provider used when app cards are disabled: every card is empty."""
class DisabledAppCardProvider(AppCardProvider) {
    async def load_app_card(
        package_name: builtins.str,
        instruction: builtins.str = "",
        platform: builtins.str | None = None,
    ) -> builtins.str;
}
