"""
Prompt resolution utility for handling custom prompts passed as dict.

This module provides logic to resolve prompts from either:
1. Custom prompt strings (Jinja2 templates passed at runtime)
2. File paths (default behavior via AgentConfig)

This keeps the MobileAgent clean and separates prompt resolution logic.
"""

import builtins;

import from typing { Dict, Optional }

"""
    Resolves prompts from custom dict or falls back to file paths.

    Usage:
        resolver = PromptResolver(custom_prompts={"fast_agent_system": "..."})
        prompt = resolver.get_prompt("fast_agent_system", fallback_path="/path/to/prompt.j2")
    """
class PromptResolver {
    has custom_prompts: any;

    """
        Initialize prompt resolver.

        Args:
            custom_prompts: Dict mapping prompt keys to Jinja2 template strings.
                           Keys: "fast_agent_system", "fast_agent_user", "manager_system",
                                 "executor_system"
        """
    def init(custom_prompts: Optional[Dict[builtins.str, builtins.str]] = None);

    """
        Get prompt by key, returning custom template or None if not found.

        Args:
            prompt_key: Prompt identifier (e.g., "fast_agent_system", "manager_system")
            fallback_path: Optional file path (unused, for API compatibility)

        Returns:
            Jinja2 template string if found in custom_prompts, else None
        """
    def get_prompt(
        prompt_key: builtins.str, fallback_path: Optional[builtins.str] = None
    ) -> Optional[builtins.str];

    """Check if a custom prompt exists for the given key."""
    def has_custom_prompt(prompt_key: builtins.str) -> builtins.bool;

    """
        Return list of valid prompt keys that can be customized.

        Returns:
            List of valid prompt key strings
        """
    static def get_valid_prompt_keys -> builtins.list[builtins.str];
}
