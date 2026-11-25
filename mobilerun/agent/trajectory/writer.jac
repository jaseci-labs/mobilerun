import builtins;

import asyncio;

import json;

import logging;

import time;

import from abc { ABC, abstractmethod }

import from dataclasses { dataclass }

import from pathlib { Path }

import from typing { List, Optional }

import aiofiles;

import from aiofiles { ospath }

import from PIL { Image }

glob logger: any;

with entry {
    logger = logging.getLogger("mobilerun");
}

def make_serializable(`obj) -> any;

"""Immutable write operation.

    Jobs capture a snapshot of data at creation time, preventing race
    conditions from concurrent trajectory mutations during async writes.
    """
@dataclass(frozen=True)
class WriteJob(ABC) {
    has trajectory_id: builtins.str;

    has stage: builtins.str;

    """Execute the write operation asynchronously."""
    @abstractmethod
    async def execute -> None;
}

"""Writes trajectory.json."""
@dataclass(frozen=True)
class EventsWriteJob(WriteJob) {
    has target_path: Path;

    has serialized_events: builtins.str;

    async def execute -> None;
}

"""Writes macro.json."""
@dataclass(frozen=True)
class MacroWriteJob(WriteJob) {
    has target_path: Path;

    has serialized_macro: builtins.str;

    async def execute -> None;
}

"""Writes individual screenshot PNG."""
@dataclass(frozen=True)
class ScreenshotWriteJob(WriteJob) {
    has target_path: Path;

    has screenshot_bytes: builtins.bytes;

    async def execute -> None;
}

"""Creates animated GIF from screenshots on disk."""
@dataclass(frozen=True)
class GifWriteJob(WriteJob) {
    has target_path: Path;

    has screenshots_folder: Path;

    has screenshot_count: builtins.int;

    has duration: builtins.int = 1000;

    async def execute -> None;
}

"""Writes UI state JSON."""
@dataclass(frozen=True)
class UIStateWriteJob(WriteJob) {
    has target_path: Path;

    has serialized_state: builtins.str;

    async def execute -> None;
}

"""Async worker that processes write jobs from a queue.

    Jobs are executed sequentially (FIFO order). Errors are logged but
    don't stop the worker - it continues processing remaining jobs.
    """
class WriterWorker {
    has queue: any,
        worker_task: any,
        running: any,
        _write_count: any,
        _error_count: any;

    def init(max_queue_size: builtins.int = 300);

    async def start -> None;

    async def stop(timeout: builtins.float = 30.0) -> None;

    static def _consume_worker_result(task: asyncio.Task) -> None;

    async def _work_loop -> None;

    def submit(job: WriteJob) -> builtins.bool;
}

"""Background writer that persists trajectory data without blocking.

    Manages a single async worker that processes write jobs from a queue.
    All writes happen in the background - agent never blocks on I/O.

    Usage:
        writer = TrajectoryWriter(queue_size=300)
        await writer.start()

        # Non-blocking writes
        writer.write(trajectory, stage="step_1")

        # Wait for completion
        writer.write_final(trajectory)
        await writer.stop()
    """
class TrajectoryWriter {
    has worker: any,
        _started: any;

    def init(queue_size: builtins.int = 300);

    async def start -> None;

    async def stop(timeout: builtins.float = 30.0) -> None;

    def write(trajectory, stage: builtins.str) -> None;

    def write_final(trajectory, trajectory_gifs) -> None;

    def _create_events_job(
        events_snapshot, trajectory, trajectory_id, stage
    ) -> Optional[EventsWriteJob];

    def _create_macro_job(
        macro_snapshot, trajectory, trajectory_id, stage
    ) -> Optional[MacroWriteJob];

    def _create_screenshot_jobs(
        screenshot_queue_snapshot, trajectory, trajectory_id, stage
    ) -> List[ScreenshotWriteJob];

    def _create_gif_job(trajectory, trajectory_id, stage) -> Optional[GifWriteJob];

    def _create_ui_state_jobs(
        ui_states_snapshot, trajectory, trajectory_id, stage
    ) -> List[UIStateWriteJob];
}
