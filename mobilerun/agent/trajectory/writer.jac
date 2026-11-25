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

"""Recursively make objects JSON serializable."""
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
obj WriterWorker {
    has queue: any,
        worker_task: any,
        running: any,
        _write_count: any,
        _error_count: any;

    def init(max_queue_size: builtins.int = 300);

    """Start the worker task."""
    async def start -> None;

    """Stop worker and wait for pending writes to complete.

        Drains the queue before canceling. Any jobs still pending after
        timeout are dropped with a warning.

        Args:
            timeout: Maximum seconds to wait for queue to drain
        """
    async def stop(timeout: builtins.float = 30.0) -> None;

    static def _consume_worker_result(task: asyncio.Task) -> None;

    async def _work_loop -> None;

    def submit(job: WriteJob) -> builtins.bool;

    def __repr__ -> str;

    def __eq__(other: any) -> bool;

    def __hash__ -> int;
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
obj TrajectoryWriter {
    has worker: any,
        _started: any;

    def init(queue_size: builtins.int = 300);

    """Start the background worker."""
    async def start -> None;

    """Stop the background worker and wait for pending writes."""
    async def stop(timeout: builtins.float = 30.0) -> None;

    """Write trajectory data to disk in background (non-blocking).

        Creates a snapshot of trajectory data and queues write jobs.
        Returns immediately - actual writes happen asynchronously.

        Args:
            trajectory: Trajectory instance with data to persist
            stage: Label for this save point (e.g. "init", "step_1", "final")
        """
    def write(trajectory, stage: builtins.str) -> None;

    """Write final trajectory data including GIF creation.

        Args:
            trajectory: Trajectory instance to finalize
        """
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

    def __repr__ -> str;

    def __eq__(other: any) -> bool;

    def __hash__ -> int;
}
