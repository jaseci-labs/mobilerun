"""
Mobilerun CLI - Command line interface for controlling Android devices through LLM agents.
"""

import builtins;

import importlib;

import asyncio;

import importlib.metadata;

import logging;

import math;

import os;

import sys;

import tomllib;

import warnings;

import from contextlib { nullcontext }

import from functools { partial, wraps }

import from pathlib { Path }

import click;

import from async_adbutils { adb }

import from mobilerun_core_local.driver.android.portal {
    DOWNLOAD_BASE,
    PORTAL_PACKAGE_NAME,
    check_portal_accessibility,
    download_portal_apk,
    download_versioned_portal_apk,
    enable_portal_accessibility,
    ping_portal,
    ping_portal_content,
    ping_portal_tcp,
    portal_content_uri,
    setup_portal,
}

import from mobilerun_core_local.driver.ios { discover_ios_device, validate_ios_portal_url }

import from mobilerun_core_local.driver.visual_remote { VISUAL_REMOTE_CONNECTION }

import from rich.console { Console }

import from rich.panel { Panel }

import from rich.text { Text }

glob console: any;

glob _available_agents: any;

glob DEFAULT_AUTH_URL: any;

glob DEFAULT_DEVICE_CLIENT_ID: any;

glob command: any;

glob device: any;

glob provider: any;

glob model: any;

glob temperature: any;

glob api_key: any;

glob steps: any;

glob vision: any;

glob reasoning: any;

glob tracing: any;

glob debug: any;

glob use_tcp: any;

glob base_url: any;

glob api_base: any;

glob ios: any;

glob save_trajectory: any;

with entry {
    warnings.filterwarnings("ignore");
    os.environ["TOKENIZERS_PARALLELISM"] = "false";
    os.environ["GRPC_ENABLE_FORK_SUPPORT"] = "false";

    console = Console();
}

def _validate_oauth_timeout(
    _ctx: click.Context, _param: click.Parameter, value: builtins.float
) -> builtins.float;

def _force_screenshot_only_vision(config: MobileConfig) -> None;

"""Configure the mobilerun logger with a CLILogHandler."""
def _setup_cli_logging(debug: builtins.bool) -> None;

def _run_coroutine(f, *args_, **kwargs) -> any;

def coro(f) -> any;

"""Run a command on your Android device using natural language.

    Returns:
        bool: True if the task completed successfully, False otherwise.
    """
async def run_command(
    command: builtins.str,
    config_path: builtins.str | None = None,
    device: builtins.str | None = None,
    agent: builtins.str | None = None,
    provider: builtins.str | None = None,
    model: builtins.str | None = None,
    steps: builtins.int | None = None,
    base_url: builtins.str | None = None,
    api_base: builtins.str | None = None,
    vision: builtins.bool | None = None,
    vision_only: builtins.bool | None = None,
    manager_vision: builtins.bool | None = None,
    executor_vision: builtins.bool | None = None,
    fast_agent_vision: builtins.bool | None = None,
    reasoning: builtins.bool | None = None,
    stream: builtins.bool | None = None,
    tracing: builtins.bool | None = None,
    debug: builtins.bool | None = None,
    tcp: builtins.bool | None = None,
    control_backend: builtins.str | None = None,
    device_id: builtins.str | None = None,
    save_trajectory: builtins.str | None = None,
    ios: builtins.bool = False,
    temperature: builtins.float | None = None,
    **kwargs,
) -> builtins.bool;

async def _cleanup_android_keyboard(
    config: MobileConfig, serial: builtins.str | None = None
) -> None;

"""Click callback to print version and exit early when --version is passed."""
def _print_version(ctx, param, value) -> any;

"""Mobilerun - Control your mobile devices through LLM agents."""
@click.group()
@click.option(
    "--version",
    is_flag=True,
    callback=_print_version,
    expose_value=False,
    is_eager=True,
    help="Show mobilerun version and exit",
)
def cli -> any;

def _print_oauth_login_success(provider_label: builtins.str, credential_path: builtins.str) -> None;

def _run_openai_oauth_login(
    credential_path: builtins.str, model: builtins.str | None, **kwargs
) -> None;

def _run_gemini_oauth_login(
    credential_path: builtins.str, model: builtins.str | None, **kwargs
) -> None;

"""Run the full Anthropic OAuth flow inline and save the token."""
def _run_anthropic_oauth_login(credential_path: builtins.str, **kwargs) -> None;

def _run_grok_oauth_login(
    credential_path: builtins.str, model: builtins.str | None = None, **kwargs
) -> None;

with entry {
    try {
        _available_agents = list_agents();
    } except Exception {
        _available_agents = [];
    }
}

"""Run a command on your mobile device using natural language."""
@getattr(cli as any, "command")()
@click.argument("command", type=str)
@click.option("--config", "-c", help="Path to custom config file", default=None)
@click.option(
    "--device", "-d", help="Device serial number, IP address, or Portal HTTP URL", default=None
)
@click.option(
    "--agent",
    "-a",
    type=click.Choice(_available_agents) if _available_agents else None,
    help="External agent to use"
        + (
            " [" + format(", ".join(_available_agents), "") + "]"
                if _available_agents
                else " (none available)"
        ),
    default=None,
)
@click.option(
    "--provider",
    "-p",
    help="LLM provider (OpenAI, openai_oauth, XAI, Ollama, Anthropic, anthropic_oauth, GoogleGenAI, gemini_oauth_code_assist, DeepSeek)",
    default=None,
)
@click.option("--model", "-m", help="LLM model name", default=None)
@click.option("--temperature", type=float, help="Temperature for LLM", default=None)
@click.option("--steps", type=int, help="Maximum number of steps", default=None)
@click.option(
    "--base_url", "-u", help="Base URL for API (e.g., OpenRouter or Ollama)", default=None
)
@click.option("--api_base", help="Base URL for API (e.g., OpenAI or OpenAI-Like)", default=None)
@click.option(
    "--vision/--no-vision",
    default=None,
    help="Enable vision capabilites by using screenshots for all agents.",
)
@click.option(
    "--vision-only/--no-vision-only",
    default=None,
    help="Use screenshots only without an accessibility tree.",
)
@click.option("--reasoning/--no-reasoning", default=None, help="Enable planning with reasoning")
@click.option(
    "--stream/--no-stream", default=None, help="Stream LLM responses to console in real-time"
)
@click.option("--tracing/--no-tracing", default=None, help="Enable Arize Phoenix tracing")
@click.option("--debug/--no-debug", default=None, help="Enable verbose debug logging")
@click.option("--tcp/--no-tcp", default=None, help="Use TCP communication for device control")
@click.option(
    "--control-backend",
    type=click.Choice([VISUAL_REMOTE_CONNECTION]),
    default=None,
    help="Use a compatible visual remote backend instead of the platform default backend.",
)
@click.option(
    "--device-id", default=None, help="Device id for backends that expose multiple devices."
)
@click.option(
    "--save-trajectory",
    type=click.Choice(["none", "step", "action"]),
    help="Trajectory saving level: none (no saving), step (save per step), action (save per action)",
    default=None,
)
@click.option("--ios", is_flag=True, default=False, help="Run on iOS device")
@coro
async def run(
    command: builtins.str,
    config: builtins.str | None,
    device: builtins.str | None,
    agent: builtins.str | None,
    provider: builtins.str | None,
    model: builtins.str | None,
    steps: builtins.int | None,
    base_url: builtins.str | None,
    api_base: builtins.str | None,
    temperature: builtins.float | None,
    vision: builtins.bool | None,
    vision_only: builtins.bool | None,
    reasoning: builtins.bool | None,
    stream: builtins.bool | None,
    tracing: builtins.bool | None,
    debug: builtins.bool | None,
    tcp: builtins.bool | None,
    control_backend: builtins.str | None,
    device_id: builtins.str | None,
    save_trajectory: builtins.str | None,
    ios: builtins.bool,
) -> any;

"""List Mobilerun cloud devices via the SDK.

    Returns the number of devices printed. With ``silent_if_no_key=True``
    a missing credential is treated as "no cloud section" rather than an
    error — useful for the unified ``mobilerun devices`` output.
    """
async def _list_cloud_devices(
    base_url: builtins.str | None,
    *,
    silent_if_no_key: builtins.bool = False,
    raise_on_error: builtins.bool = False,
    silent_errors: builtins.bool = False,
) -> builtins.int;

"""List connected devices.

    Without flags: shows local Android devices, plus cloud devices when
    a Mobilerun credential is available. ``--cloud`` shows only cloud.
    """
@getattr(cli as any, "command")()
@click.option("--cloud", is_flag=True, default=False, help="Only list Mobilerun cloud devices")
@click.option(
    "--base-url",
    "base_url",
    default=None,
    help=f"Cloud API base URL (default {DEFAULT_CLOUD_BASE_URL})",
)
@coro
async def devices(cloud: builtins.bool, base_url: builtins.str | None) -> any;

with entry {
    DEFAULT_AUTH_URL = "https://cloud.mobilerun.ai/api/auth";
    DEFAULT_DEVICE_CLIENT_ID = "mobilerun-cli";
}

"""Authenticate via OAuth 2.0 device authorization and save the session token."""
@getattr(cli as any, "command")()
@click.option(
    "--auth-url",
    "auth_url",
    default=None,
    help=f"Better-auth base URL (default {DEFAULT_AUTH_URL}; or set MOBILERUN_AUTH_URL)",
)
@click.option(
    "--client-id",
    "client_id",
    default=DEFAULT_DEVICE_CLIENT_ID,
    show_default=True,
    help="OAuth device client id",
)
def login(auth_url: builtins.str | None, client_id: builtins.str) -> any;

"""Remove the saved Mobilerun cloud login."""
@getattr(cli as any, "command")()
def logout -> any;

"""Show the currently logged-in Mobilerun cloud user."""
@getattr(cli as any, "command")()
def whoami -> any;

"""Connect to a device over TCP/IP."""
@getattr(cli as any, "command")()
@click.argument("serial")
@coro
async def connect(serial: builtins.str) -> any;

"""Disconnect from a device."""
@getattr(cli as any, "command")()
@click.argument("serial")
@coro
async def disconnect(serial: builtins.str) -> any;

"""Wait until Portal's accessibility service responds.

    Android drops the service when it is enabled before a fresh install is
    registered, so it is enabled again while waiting. ``/ping`` answers once
    the service is bound, even without an active window. A busy device can
    take well over 10s to bind it.
    """
async def _wait_for_portal_service(
    device_obj, timeout: builtins.float = 30.0, interval: builtins.float = 1.0
) -> builtins.bool;

"""Internal async function to install and enable the Mobilerun Portal on a device."""
async def _setup_portal(
    path: builtins.str | None,
    device: builtins.str | None,
    debug: builtins.bool,
    latest: builtins.bool = False,
    specific_version: builtins.str | None = None,
    in_place: builtins.bool = False,
) -> any;

"""Install and enable the Mobilerun Portal on a device."""
@getattr(cli as any, "command")()
@click.option("--device", "-d", help="Device serial number or IP address", default=None)
@click.option(
    "--path",
    help="Path to the Mobilerun Portal APK to install on the device. If not provided, the latest portal apk version will be downloaded and installed.",
    default=None,
)
@click.option(
    "--portal-version", "-pv", help="Specific Portal version to install (e.g., 0.4.7)", default=None
)
@click.option(
    "--latest",
    is_flag=True,
    help="Install latest Portal instead of compatible version",
    default=False,
)
@click.option("--debug", is_flag=True, help="Enable verbose debug logging", default=False)
@coro
async def setup(
    path: builtins.str | None,
    device: builtins.str | None,
    portal_version: builtins.str | None,
    latest: builtins.bool,
    debug: builtins.bool,
) -> any;

"""Ping a device to check if it is ready and accessible."""
@getattr(cli as any, "command")()
@click.option(
    "--device", "-d", help="Device serial number, IP address, or Portal HTTP URL", default=None
)
@click.option("--tcp/--no-tcp", default=None, help="Use TCP communication for device control")
@click.option("--debug/--no-debug", default=None, help="Enable verbose debug logging")
@coro
async def ping(
    device: builtins.str | None, tcp: builtins.bool | None, debug: builtins.bool | None
) -> any;

with entry {
    getattr(cli as any, "add_command")(macro_cli, name="macro");
    getattr(cli as any, "add_command")(device_cli, name="device");
}

"""Check system health and diagnose issues."""
@getattr(cli as any, "command")()
@click.option("--device", "-d", help="Device serial number or IP address", default=None)
@click.option("--debug/--no-debug", default=None, help="Enable verbose debug output")
@coro
async def doctor(device: builtins.str | None, debug: builtins.bool | None) -> any;

"""Configure LLM provider, auth mode, and model.

    Run without a subcommand for the interactive wizard, or use a provider
    subcommand (e.g. `mobilerun configure anthropic`) to log in via OAuth.
    """
@getattr(cli as any, "group")(name="configure", invoke_without_command=True)
@click.option(
    "--provider",
    type=str,
    default=None,
    help="Provider family (gemini, openai, anthropic, XAI, ollama, openai_like, minimax, zai).",
)
@click.option(
    "--auth-mode", type=str, default=None, help="Auth mode for the selected provider family."
)
@click.option("--model", type=str, default=None, help="Model to configure.")
@click.option("--api-key", type=str, default=None, help="API key for API-key providers.")
@click.option(
    "--base-url", type=str, default=None, help="Base URL override for compatible providers."
)
@click.pass_context
def configure(
    ctx: click.Context,
    provider: builtins.str | None,
    auth_mode: builtins.str | None,
    model: builtins.str | None,
    api_key: builtins.str | None,
    base_url: builtins.str | None,
) -> any;

"""Log in to ChatGPT/OpenAI via OAuth and save credentials locally."""
@getattr(configure as any, "command")("openai")
@click.option(
    "--credential-path",
    default=`str(DEFAULT_OPENAI_OAUTH_CREDENTIAL_PATH),
    show_default=True,
    help="Where to store OpenAI OAuth credentials.",
)
@click.option("--model", default=None, help="Optional model override for later API calls.")
@click.option(
    "--timeout",
    type=float,
    callback=_validate_oauth_timeout,
    default=300.0,
    show_default=True,
    help="Max seconds allowed for the complete OpenAI OAuth login.",
)
@click.option(
    "--callback-host",
    default=DEFAULT_OPENAI_OAUTH_CALLBACK_HOST,
    show_default=True,
    help="Host to bind the local OAuth callback server.",
)
@click.option(
    "--callback-port",
    type=int,
    default=DEFAULT_OPENAI_OAUTH_CALLBACK_PORT,
    show_default=True,
    help="Port to bind the local OAuth callback server.",
)
@click.option(
    "--callback-path",
    default=DEFAULT_OPENAI_OAUTH_CALLBACK_PATH,
    show_default=True,
    help="Callback path for the local OAuth server.",
)
@click.option(
    "--open-browser/--no-browser",
    default=True,
    show_default=True,
    help="Open the authorization URL automatically.",
)
def configure_openai(
    credential_path: builtins.str,
    model: builtins.str | None,
    timeout: builtins.float,
    callback_host: builtins.str,
    callback_port: builtins.int,
    callback_path: builtins.str,
    open_browser: builtins.bool,
) -> any;

"""Log in to Anthropic via OAuth (or pass --token to save a setup-token)."""
@getattr(configure as any, "command")("anthropic")
@click.option(
    "--credential-path",
    default=`str(ANTHROPIC_OAUTH_CREDENTIAL_PATH),
    show_default=True,
    help="Where to store the Anthropic credentials.",
)
@click.option(
    "--token", default=None, help="Anthropic setup-token value. If provided, skips the OAuth flow."
)
@click.option(
    "--timeout",
    type=float,
    callback=_validate_oauth_timeout,
    default=300.0,
    show_default=True,
    help="Max seconds allowed for the complete Anthropic OAuth login.",
)
@click.option(
    "--open-browser/--no-browser",
    default=True,
    show_default=True,
    help="Open the Anthropic authorization URL automatically.",
)
def configure_anthropic(
    credential_path: builtins.str,
    token: builtins.str | None,
    timeout: builtins.float,
    open_browser: builtins.bool,
) -> any;

"""Log in to Gemini Code Assist via OAuth and save credentials locally."""
@getattr(configure as any, "command")("gemini")
@click.option(
    "--credential-path",
    default=`str(GEMINI_OAUTH_CREDENTIAL_PATH),
    show_default=True,
    help="Where to store Gemini OAuth credentials.",
)
@click.option("--model", default=None, help="Optional model override for later API calls.")
@click.option(
    "--timeout",
    type=float,
    callback=_validate_oauth_timeout,
    default=300.0,
    show_default=True,
    help="Max seconds allowed for the complete Gemini OAuth login.",
)
@click.option(
    "--callback-host",
    default="127.0.0.1",
    show_default=True,
    help="Host to bind the local OAuth callback server.",
)
@click.option(
    "--callback-port",
    type=int,
    default=0,
    show_default=True,
    help="Port to bind the local OAuth callback server. Use 0 for auto.",
)
@click.option(
    "--callback-path",
    default="/oauth2callback",
    show_default=True,
    help="Callback path for the local OAuth server.",
)
@click.option(
    "--open-browser/--no-browser",
    default=True,
    show_default=True,
    help="Open the authorization URL automatically.",
)
def configure_gemini(
    credential_path: builtins.str,
    model: builtins.str | None,
    timeout: builtins.float,
    callback_host: builtins.str,
    callback_port: builtins.int,
    callback_path: builtins.str,
    open_browser: builtins.bool,
) -> any;

"""Log in to XAI with Mobilerun OAuth."""
@getattr(configure as any, "command")("xai")
@click.option(
    "--credential-path",
    default=`str(GROK_OAUTH_CREDENTIAL_PATH),
    show_default=True,
    help="Where to store XAI OAuth credentials.",
)
@click.option("--model", default=None, help="Optional model override for later API calls.")
@click.option(
    "--timeout",
    type=float,
    callback=_validate_oauth_timeout,
    default=300.0,
    show_default=True,
    help="Max seconds allowed for the complete xAI OAuth login.",
)
@click.option(
    "--open-browser/--no-browser",
    default=True,
    show_default=True,
    help="Open the xAI authorization URL automatically.",
)
@click.option(
    "--device-code",
    is_flag=True,
    default=False,
    help="Use xAI's device-code flow for SSH or other headless environments.",
)
def configure_xai(
    credential_path: builtins.str,
    model: builtins.str | None,
    timeout: builtins.float,
    open_browser: builtins.bool,
    device_code: builtins.bool,
) -> any;

async def `test(
    command: builtins.str,
    config_path: builtins.str | None = None,
    device: builtins.str | None = None,
    steps: builtins.int | None = None,
    vision: builtins.bool | None = None,
    reasoning: builtins.bool | None = None,
    tracing: builtins.bool | None = None,
    debug: builtins.bool | None = None,
    use_tcp: builtins.bool | None = None,
    save_trajectory: builtins.str | None = None,
    temperature: builtins.float | None = None,
    ios: builtins.bool = False,
) -> any;

with entry:__main__ {
    command = "open youtube and play a song by shakira";
    command = "use open_app to open the settings and search for the battery and enter the first result";
    device = None;
    provider = "OpenAIResponses";
    model = "gpt-6-astra";
    temperature = 1;
    api_key = os.getenv("OPENAI_API_KEY");
    steps = 15;
    vision = True;
    reasoning = False;
    tracing = True;
    debug = True;
    use_tcp = False;
    base_url = None;
    api_base = None;
    ios = False;
    save_trajectory = "none";
    asyncio.run(run_command(command, device="emulator-5556", reasoning=False));
}
