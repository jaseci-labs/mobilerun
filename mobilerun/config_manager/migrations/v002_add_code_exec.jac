import builtins;

import from typing { Any, Dict }

glob VERSION: any = 2;

glob _OLD_SYSTEM_PROMPT: any = "config/prompts/codeact/system.jinja2";

glob _OLD_USER_PROMPT: any = "config/prompts/codeact/user.jinja2";

glob _NEW_SYSTEM_PROMPT: any = "config/prompts/codeact/tools_system.jinja2";

glob _NEW_USER_PROMPT: any = "config/prompts/codeact/tools_user.jinja2";

def migrate(config: Dict[builtins.str, Any]) -> Dict[builtins.str, Any] {
    agent: any = config.get("agent", {});
    if "codeact" in agent and "fast_agent" not in agent {
        agent["fast_agent"] = agent.pop("codeact");
    }

    fast_agent: any = agent.setdefault("fast_agent", {});

    fast_agent.setdefault("codeact", False);
    fast_agent.setdefault("parallel_tools", True);
    fast_agent.pop("safe_execution", None);
    fast_agent.pop("execution_timeout", None);
    if fast_agent.get("system_prompt") == _OLD_SYSTEM_PROMPT {
        fast_agent["system_prompt"] = _NEW_SYSTEM_PROMPT;
    }
    if fast_agent.get("user_prompt") == _OLD_USER_PROMPT {
        fast_agent["user_prompt"] = _NEW_USER_PROMPT;
    }

    config["agent"] = agent;
    profiles: any = config.get("llm_profiles", {});
    if "codeact" in profiles and "fast_agent" not in profiles {
        profiles["fast_agent"] = profiles.pop("codeact");
    }

    return config;
}
