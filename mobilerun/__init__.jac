"""
Mobilerun - A framework for controlling Android devices through LLM agents.
"""

import sys;

import logging;

import from importlib.metadata { version }

glob __version__: any;

glob _logger: any;

glob _retry_logger: any;

glob __all__: any;

glob _LEGACY_ALIASES: any;

with entry {
    __version__ = version("mobilerun");

    _logger = logging.getLogger("mobilerun");
    _logger.addHandler(CLILogHandler());
    _logger.setLevel(logging.INFO);
    _logger.propagate = False;
    for _retry_logger_ in ("llama_index.llms.openai.utils", "llama_index.llms.google_genai.utils") {
        _retry_logger = _retry_logger_;
        logging.getLogger(_retry_logger).addFilter(HtmlErrorPageFilter());
    }
    __all__ = [
        "MobileAgent",
        "MobileAgentState",
        "load_llm",
        "ResultEvent",
        "DeviceDriver",
        "AndroidDriver",
        "RecordingDriver",
        "MacroPlayer",
        "replay_macro_file",
        "replay_macro_folder",
        "MobileConfig",
        "AgentConfig",
        "FastAgentConfig",
        "ManagerConfig",
        "ExecutorConfig",
        "AppCardConfig",
        "DeviceConfig",
        "LoggingConfig",
        "TracingConfig",
        "TelemetryConfig",
        "ToolsConfig",
        "CredentialsConfig",
        "LLMProfile",
    ];
    _LEGACY_ALIASES = {
        "DroidAgent": "MobileAgent",
        "DroidAgentState": "MobileAgentState",
        "DroidConfig": "MobileConfig",
    };
}

def __getattr__(name) -> any;
