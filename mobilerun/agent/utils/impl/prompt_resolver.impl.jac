impl PromptResolver.init(custom_prompts: Optional[Dict[builtins.str, builtins.str]] = None) {
    self.custom_prompts = custom_prompts or {};
}

impl PromptResolver.get_prompt(
    prompt_key: builtins.str, fallback_path: Optional[builtins.str] = None
) -> Optional[builtins.str] {
    return self.custom_prompts.get(prompt_key);
}

impl PromptResolver.has_custom_prompt(prompt_key: builtins.str) -> builtins.bool {
    return prompt_key in self.custom_prompts;
}

impl PromptResolver.get_valid_prompt_keys -> builtins.list[builtins.str] {
    return ["fast_agent_system", "fast_agent_user", "manager_system", "executor_system"];
}
