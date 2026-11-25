import builtins;

import from typing { Any, Dict }

glob VERSION: any = 4;

glob _OLD_SYSTEM_PROMPT: any = "config/prompts/codeact/tools_system.jinja2";

glob _OLD_USER_PROMPT: any = "config/prompts/codeact/tools_user.jinja2";

glob _NEW_SYSTEM_PROMPT: any = "config/prompts/fast_agent/system.jinja2";

glob _NEW_USER_PROMPT: any = "config/prompts/fast_agent/user.jinja2";

def migrate(config: Dict[builtins.str, Any]) -> Dict[builtins.str, Any] {
    agent: any = config.get("agent", {});

    fast_agent: any = agent.get("fast_agent", {});
    fast_agent.pop("codeact", None);
    fast_agent.pop("safe_execution", None);
    fast_agent.pop("execution_timeout", None);
    if fast_agent.get("system_prompt") == _OLD_SYSTEM_PROMPT {
        fast_agent["system_prompt"] = _NEW_SYSTEM_PROMPT;
    }
    if fast_agent.get("user_prompt") == _OLD_USER_PROMPT {
        fast_agent["user_prompt"] = _NEW_USER_PROMPT;
    }
    agent.pop("scripter", None);
    config.pop("safe_execution", None);
    profiles: any = config.get("llm_profiles", {});
    profiles.pop("text_manipulator", None);
    profiles.pop("scripter", None);

    return config;
}
