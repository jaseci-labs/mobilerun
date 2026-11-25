"""Migration v2: Rename codeact config to fast_agent, add codeact flag."""

import builtins;

import from typing { Any, Dict }

glob VERSION: any = 2;

glob _OLD_SYSTEM_PROMPT: any = "config/prompts/codeact/system.jinja2";

glob _OLD_USER_PROMPT: any = "config/prompts/codeact/user.jinja2";

glob _NEW_SYSTEM_PROMPT: any = "config/prompts/codeact/tools_system.jinja2";

glob _NEW_USER_PROMPT: any = "config/prompts/codeact/tools_user.jinja2";

"""Rename agent.codeact -> agent.fast_agent and llm_profiles.codeact -> fast_agent."""
def migrate(config: Dict[builtins.str, Any]) -> Dict[builtins.str, Any];
