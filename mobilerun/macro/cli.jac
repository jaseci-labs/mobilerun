"""
Command-line interface for Mobilerun macro replay.
"""

import builtins;

import functools;

import asyncio;

import logging;

import from typing { Optional }

import click;

import from rich.console { Console }

import from rich.table { Table }

glob console: any = Console();

"""Configure logging for the macro CLI."""
def configure_logging(debug: builtins.bool = False) -> any;

"""Replay recorded automation sequences."""
@click.group()
def macro_cli -> any;

"""Replay a macro from a file or trajectory folder."""
@getattr(macro_cli as any, "command")()
@click.argument("path", type=click.Path(exists=True))
@click.option("--device", "-d", help="Device serial number", default=None)
@click.option("--delay", "-t", help="Delay between actions (seconds)", default=1.0, type=float)
@click.option("--start-from", "-s", help="Start from step number (1-based)", default=1, type=int)
@click.option("--max-steps", "-m", help="Maximum steps to execute", default=None, type=int)
@click.option("--debug", is_flag=True, help="Enable debug logging", default=False)
@click.option("--dry-run", is_flag=True, help="Show actions without executing", default=False)
@click.option(
    "--on-mismatch",
    type=click.Choice(["stop", "agent"]),
    default="stop",
    show_default=True,
    help="What to do when the current UI does not match the recorded pre-action state.",
)
@click.option(
    "--state-timeout",
    default=5.0,
    show_default=True,
    type=float,
    help="Seconds to wait for the recorded pre-action state before declaring divergence.",
)
@click.option(
    "--state-threshold",
    default=0.85,
    show_default=True,
    type=float,
    help="Minimum normalized state similarity required before replaying an action.",
)
@click.option("--config", "config_path", default=None, help="Config file for agent handoff.")
@click.option("--provider", default=None, help="LLM provider override for agent handoff.")
@click.option("--model", default=None, help="LLM model override for agent handoff.")
def replay(
    path: builtins.str,
    device: Optional[builtins.str],
    delay: builtins.float,
    start_from: builtins.int,
    max_steps: Optional[builtins.int],
    debug: builtins.bool,
    dry_run: builtins.bool,
    on_mismatch: builtins.str,
    state_timeout: builtins.float,
    state_threshold: builtins.float,
    config_path: Optional[builtins.str],
    provider: Optional[builtins.str],
    model: Optional[builtins.str],
) -> any;

async def _get_device(device, dry_run: builtins.bool, logger: logging.Logger) -> any;

async def _replay_with_device(
    path: builtins.str,
    device: builtins.str,
    delay: builtins.float,
    start_from: builtins.int,
    max_steps: Optional[builtins.int],
    dry_run: builtins.bool,
    logger: logging.Logger,
    get_device,
    on_mismatch: builtins.str,
    state_timeout: builtins.float,
    state_threshold: builtins.float,
    config_path: Optional[builtins.str],
    provider: Optional[builtins.str],
    model: Optional[builtins.str],
) -> any;

"""Async function to handle macro replay."""
async def _replay_async(
    path: builtins.str,
    device: builtins.str,
    delay: builtins.float,
    start_from: builtins.int,
    max_steps: Optional[builtins.int],
    dry_run: builtins.bool,
    logger: logging.Logger,
    on_mismatch: builtins.str,
    state_timeout: builtins.float,
    state_threshold: builtins.float,
    config_path: Optional[builtins.str],
    provider: Optional[builtins.str],
    model: Optional[builtins.str],
) -> any;

"""Show what actions would be executed in dry run mode."""
async def _show_dry_run(
    macro_data: builtins.dict,
    start_from: builtins.int,
    max_steps: Optional[builtins.int],
    logger: logging.Logger,
) -> any;

"""List available trajectory folders in a directory."""
@getattr(macro_cli as any, "command")()
@click.argument("directory", type=click.Path(exists=True), default="trajectories")
@click.option("--debug", is_flag=True, help="Enable debug logging", default=False)
def `list(directory: builtins.str, debug: builtins.bool) -> any;

with entry:__main__ {
    macro_cli();
}
