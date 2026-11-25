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

    def init(custom_prompts: Optional[Dict[builtins.str, builtins.str]] = None) {
        self.custom_prompts = custom_prompts or {};
    }

    def get_prompt(
        prompt_key: builtins.str, fallback_path: Optional[builtins.str] = None
    ) -> Optional[builtins.str] {
        return self.custom_prompts.get(prompt_key);
    }

    def has_custom_prompt(prompt_key: builtins.str) -> builtins.bool {
        return prompt_key in self.custom_prompts;
    }

    static def get_valid_prompt_keys -> builtins.list[builtins.str] {
        return ["fast_agent_system", "fast_agent_user", "manager_system", "executor_system"];
    }
}
