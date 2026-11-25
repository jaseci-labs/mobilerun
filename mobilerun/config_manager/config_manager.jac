import from __future__ { annotations }

import os;

import from dataclasses { asdict, dataclass, field }

import from typing { Any, Dict, List, Literal, Optional }

import yaml;

glob DEFAULT_MANAGER_SYSTEM_PROMPT: any = "config/prompts/manager/system.jinja2";

glob DEFAULT_STATELESS_MANAGER_SYSTEM_PROMPT: any = "config/prompts/manager/stateless.jinja2";

"""LLM profile configuration."""
@dataclass
class LLMProfile {
    has provider: str = "GoogleGenAI";

    has model: str = GEMINI_API_DEFAULT_MODEL;

    has temperature: float = 0.2;

    has api_key_source: Literal["auto", "env", "file"] = "auto";

    has base_url: Optional[str] = None;

    has api_base: Optional[str] = None;

    has provider_family: Optional[str] = None;

    has auth_mode: Optional[str] = None;

    has credential_path: Optional[str] = None;

    has kwargs: Dict[str, Any] = field(default_factory=dict[any, any]);

    """Convert profile to kwargs for load_llm function."""
    def to_load_llm_kwargs -> Dict[str, Any];
}

@dataclass
class FastAgentConfig {
    has vision: bool = False;

    has parallel_tools: bool = True;

    has tool_calling: str = "auto";

    has system_prompt: str = "config/prompts/fast_agent/system.jinja2";

    has user_prompt: str = "config/prompts/fast_agent/user.jinja2";
}

@dataclass
class ManagerConfig {
    has vision: bool = False;

    has system_prompt: str | None = None;

    has stateless: bool = False;
}

@dataclass
class ExecutorConfig {
    has vision: bool = False;

    has system_prompt: str = "config/prompts/executor/system.jinja2";
}

"""App card configuration."""
@dataclass
class AppCardConfig {
    has enabled: bool = True;

    has mode: str = "local";

    has app_cards_dir: str = "config/app_cards";

    has server_url: Optional[str] = None;

    has server_timeout: float = 2.0;

    has server_max_retries: int = 2;
}

@dataclass
class AgentConfig {
    has name: str = "mobilerun";

    has max_steps: int = 15;

    has reasoning: bool = False;

    has streaming: bool = True;

    has vision_only: bool = False;

    has after_sleep_action: float = 1.0;

    has wait_for_stable_ui: float = 0.3;

    has use_normalized_coordinates: bool = False;

    has model_screenshot_max_side: Optional[int] = None;

    has fast_agent: FastAgentConfig = field(default_factory=FastAgentConfig);

    has manager: ManagerConfig = field(default_factory=ManagerConfig);

    has executor: ExecutorConfig = field(default_factory=ExecutorConfig);

    has app_cards: AppCardConfig = field(default_factory=AppCardConfig);

    def get_fast_agent_system_prompt_path -> str;

    def get_fast_agent_user_prompt_path -> str;

    def get_manager_system_prompt_path -> str;

    def get_executor_system_prompt_path -> str;
}

"""Device-related configuration."""
@dataclass
class DeviceConfig {
    has serial: Optional[str] = None;

    has control_backend: Optional[str] = None;

    has device_id: str = "auto";

    has use_tcp: bool = False;

    has platform: str = "android";

    has portal_mode: Literal["auto", "required", "disabled"] = "auto";

    has auto_setup: bool = True;

    has auth_token: Optional[str] = None;

    def resolve_auth_token -> Optional[str];
}

"""Telemetry configuration."""
@dataclass
class TelemetryConfig {
    has enabled: bool = True;
}

"""Tracing configuration."""
@dataclass
class TracingConfig {
    has enabled: bool = False;

    has provider: str = "phoenix";

    has langfuse_screenshots: bool = False;

    has langfuse_secret_key: str = "";

    has langfuse_public_key: str = "";

    has langfuse_host: str = "";

    has langfuse_user_id: str = "anonymous";

    has langfuse_session_id: str = "";
}

"""Logging configuration."""
@dataclass
class LoggingConfig {
    has debug: bool = False;

    has save_trajectory: str = "none";

    has trajectory_path: str = "trajectories";

    has rich_text: bool = False;

    has trajectory_gifs: bool = True;
}

glob DEFAULT_DISABLED_TOOLS: tuple[str, ...];

glob DroidConfig: any;

with entry {
    DEFAULT_DISABLED_TOOLS = ("click_at", "click_area", "long_press_at");
}

"""Tools configuration.

    ``disabled_tools=None`` means "use the framework default" — coordinate
    tools are disabled, and ``click_at`` is auto-unmasked when the active
    action agent has vision. Pass an explicit list (even an empty one) to
    take full control: the list is then honored as-is with no auto-unmask.
    """
@dataclass
class ToolsConfig {
    has disabled_tools: Optional[List[str]] = None;

    has stealth: bool = False;
}

"""Credentials configuration."""
@dataclass
class CredentialsConfig {
    has enabled: bool = False;

    has file_path: str = "config/credentials.yaml";
}

"""Complete Mobilerun configuration schema."""
@dataclass
class MobileConfig {
    has agent: AgentConfig = field(default_factory=AgentConfig);

    has llm_profiles: Dict[str, LLMProfile] = field(default_factory=dict[any, any]);

    has device: DeviceConfig = field(default_factory=DeviceConfig);

    has telemetry: TelemetryConfig = field(default_factory=TelemetryConfig);

    has tracing: TracingConfig = field(default_factory=TracingConfig);

    has logging: LoggingConfig = field(default_factory=LoggingConfig);

    has tools: ToolsConfig = field(default_factory=ToolsConfig);

    has credentials: CredentialsConfig = field(default_factory=CredentialsConfig);

    has external_agents: Dict[str, Dict[str, Any]] = field(default_factory=dict[any, any]);

    has mcp: MCPConfig = field(default_factory=MCPConfig);

    """Ensure default profiles exist."""
    def postinit -> any;

    """Get default agent specific LLM profiles."""
    static def _default_profiles -> Dict[str, LLMProfile];

    """Convert config to dictionary."""
    def to_dict -> Dict[str, Any];

    """Create config from dictionary.

        If ``data`` carries a ``_version`` lower than the current schema
        version, migrations are applied before parsing so SDK callers using
        ``MobileConfig.from_yaml()`` / ``from_dict()`` get the same upgrade
        path as ``ConfigLoader``. In-memory dicts without ``_version`` are
        assumed to already match the current schema.
        """
    class def from_dict(data: Dict[str, Any]) -> "MobileConfig";

    """
        Load config from YAML file.

        Args:
            path: Path to config file (relative to CWD or absolute)

        Returns:
            MobileConfig instance

        Raises:
            FileNotFoundError: If file doesn't exist
            Exception: If file can't be parsed
        """
    class def from_yaml(path: str) -> "MobileConfig";
}

with entry {
    DroidConfig = MobileConfig;
}
