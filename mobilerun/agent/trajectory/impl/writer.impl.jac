impl make_serializable(`obj) -> any {
    if hasattr(`obj, "__class__") and `obj.__class__.__name__ == "ChatMessage" {
        if hasattr(`obj, "content") and `obj.content is not None {
            return {"role": `obj.role.value, "content": `obj.content};
        } elif hasattr(`obj, "blocks") and `obj.blocks {
            text_content: any = "";
            for block in `obj.blocks {
                if hasattr(block, "text") {
                    text_content += block.text;
                }
            }
            return {"role": `obj.role.value, "content": text_content};
        } else {
            return `str(`obj);
        }
    } elif isinstance(`obj, `dict) {
        return {k: make_serializable(v) for (k, v) in `obj.items()};
    } elif isinstance(`obj, `list) {
        return [make_serializable(item) for item in `obj];
    } elif hasattr(`obj, "__dict__") {
        result: any = {};
        for (k, v) in `obj.__dict__.items() {
            if not k.startswith("_") {
                try {
                    result[k] = make_serializable(v);
                } except (TypeError, ValueError) as e {
                    logger.warning(f"Failed to serialize attribute {k}: {e}");
                    result[k] = `str(v);
                }
            }
        }
        return result;
    } else {
        try {
            json.dumps(`obj);
            return `obj;
        } except (TypeError, ValueError) {
            return `str(`obj);
        }
    }
}

impl WriteJob.execute -> None {}

impl EventsWriteJob.execute -> None {
    async with (aiofiles.open(self.target_path, "w")) as f {
        (await f.write(self.serialized_events));
    }
}

impl MacroWriteJob.execute -> None {
    async with (aiofiles.open(self.target_path, "w")) as f {
        (await f.write(self.serialized_macro));
    }
}

impl ScreenshotWriteJob.execute -> None {
    async with (aiofiles.open(self.target_path, "wb")) as f {
        (await f.write(self.screenshot_bytes));
    }
}

impl GifWriteJob.execute -> None {
    def _create_gif -> any {
        images: any = [];

        for idx in range(self.screenshot_count) {
            screenshot_path: any = self.screenshots_folder / f"{idx:04d}.png";
            if not screenshot_path.exists() {
                logger.warning(f"Screenshot {idx:04d}.png not found, skipping");
                continue;
            }

            try {
                img: any = Image.open(screenshot_path);
                images.append(img.copy());
                img.close();
            } except Exception as e {
                logger.warning(f"Failed to load screenshot {idx}: {e}");
                continue;
            }
        }

        if images {
            try {
                images[0].save(
                    `str(self.target_path),
                    save_all=True,
                    append_images=images[1:],
                    duration=self.duration,
                    loop=0,
                );
            } finally {
                for img in images {
                    try {
                        img.close();
                    } except Exception {}
                }
            }
        }
    }

    loop: any = asyncio.get_running_loop();
    (await loop.run_in_executor(None, _create_gif));
}

impl UIStateWriteJob.execute -> None {
    if not (await ospath.exists(self.target_path)) {
        async with (aiofiles.open(self.target_path, "w", encoding="utf-8")) as f {
            (await f.write(self.serialized_state));
        }
    }
}

impl WriterWorker.init(max_queue_size: builtins.int = 300) {
    self.queue = asyncio.Queue(maxsize=max_queue_size);
    self.worker_task = None;
    self.running = False;
    self._write_count = 0;
    self._error_count = 0;
}

impl WriterWorker.start -> None {
    if self.running {
        return;
    }

    self.running = True;
    self.worker_task = asyncio.create_task(self._work_loop());
}

impl WriterWorker.stop(timeout: builtins.float = 30.0) -> None {
    if not self.running {
        return;
    }

    drain_task: any = asyncio.create_task(self.queue.join());
    try {
        (done, _) = (await asyncio.wait({drain_task}, timeout=timeout)) as any;
        if not done {
            logger.warning(f"Writer timeout after {timeout}s, {self.queue.qsize()} jobs remaining");
        }
    } finally {
        if not drain_task.done() {
            drain_task.cancel();
            drain_task.add_done_callback(WriterWorker._consume_worker_result);
        }
        self.running = False;
        if self.worker_task and not self.worker_task.done() {
            self.worker_task.cancel();
            self.worker_task.add_done_callback(WriterWorker._consume_worker_result);
        }
    }
}

impl WriterWorker._consume_worker_result(task: asyncio.Task) -> None {
    try {
        task.result();
    } except (asyncio.CancelledError, Exception) {}
}

impl WriterWorker._work_loop -> None {
    while self.running {
        try {
            job: any = (await self.queue.get());

            try {
                (await job.execute());
                self._write_count += 1;
            } except Exception as e {
                self._error_count += 1;
                logger.error(f"Write failed: {e}", exc_info=True);
            } finally {
                self.queue.task_done();
            }
        } except asyncio.CancelledError {
            break;
        }
    }
}

impl WriterWorker.submit(job: WriteJob) -> builtins.bool {
    try {
        self.queue.put_nowait(job);
        return True;
    } except asyncio.QueueFull {
        logger.warning(f"Queue full, dropping {job.__class__.__name__}");
        return False;
    }
}

impl TrajectoryWriter.init(queue_size: builtins.int = 300) {
    self.worker = WriterWorker(max_queue_size=queue_size);
    self._started = False;
}

impl TrajectoryWriter.start -> None {
    (await self.worker.start());
    self._started = True;
}

impl TrajectoryWriter.stop(timeout: builtins.float = 30.0) -> None {
    (await self.worker.stop(timeout=timeout));
}

impl TrajectoryWriter.write(trajectory, stage: builtins.str) -> None {
    if not self._started {
        logger.warning("TrajectoryWriter not started, skipping save");
        return;
    }

    trajectory_id: any = trajectory.trajectory_folder.name;

    events_snapshot: any = `list(trajectory.events);
    macro_snapshot: any = `list(trajectory.macro) if trajectory.macro else [];
    screenshot_queue_snapshot: any = `list(trajectory.screenshot_queue);
    ui_states_snapshot: any = `list(trajectory.ui_states);

    jobs: any = [];

    events_job: any = self._create_events_job(events_snapshot, trajectory, trajectory_id, stage);
    if events_job {
        jobs.append(events_job);
    }

    macro_job: any = self._create_macro_job(macro_snapshot, trajectory, trajectory_id, stage);
    if macro_job {
        jobs.append(macro_job);
    }

    screenshot_jobs: any = self._create_screenshot_jobs(
        screenshot_queue_snapshot, trajectory, trajectory_id, stage
    );
    jobs.extend(screenshot_jobs);

    ui_jobs: any = self._create_ui_state_jobs(ui_states_snapshot, trajectory, trajectory_id, stage);
    jobs.extend(ui_jobs);

    for job in jobs {
        self.worker.submit(job);
    }

    if screenshot_queue_snapshot {
        trajectory.screenshot_queue.clear();
        logger.debug(f"Cleared {len(screenshot_queue_snapshot)} screenshots from queue");
    }
}

impl TrajectoryWriter.write_final(trajectory, trajectory_gifs) -> None {
    self.write(trajectory, stage="final");
    if trajectory_gifs is True {
        trajectory_id: any = trajectory.trajectory_folder.name;
        gif_job: any = self._create_gif_job(trajectory, trajectory_id, "final");
        if gif_job {
            self.worker.submit(gif_job);
        }
    }
}

impl TrajectoryWriter._create_events_job(
    events_snapshot, trajectory, trajectory_id, stage
) -> Optional[EventsWriteJob] {
    serialized_events: any = [];

    for event in events_snapshot {
        event_dict: any = {"type": event.__class__.__name__};

        for (k, v) in event.__dict__.items() {
            if not k.startswith("_") {
                try {
                    event_dict[k] = make_serializable(v);
                } except (TypeError, ValueError) as e {
                    logger.warning(f"Failed to serialize {k}: {e}");
                    event_dict[k] = `str(v);
                }
            }
        }

        if hasattr(event, "tokens") and "tokens" not in event_dict {
            event_dict["tokens"] = make_serializable(event.tokens);
        }

        serialized_events.append(event_dict);
    }

    return EventsWriteJob(
        trajectory_id=trajectory_id,
        stage=stage,
        target_path=trajectory.trajectory_folder / "trajectory.json",
        serialized_events=json.dumps(serialized_events, indent=2),
    );
}

impl TrajectoryWriter._create_macro_job(
    macro_snapshot, trajectory, trajectory_id, stage
) -> Optional[MacroWriteJob] {
    if not macro_snapshot {
        return None;
    }

    macro_actions: any = [
        {key: value for (key, value) in action.items() if key != "target_hint"}
        for action in macro_snapshot
    ];
    macro_data: any = {
        "macro_schema_version": MACRO_SCHEMA_VERSION,
        "version": MACRO_SCHEMA_VERSION,
        "description": trajectory.goal,
        "timestamp": time.strftime("%Y%m%d_%H%M%S"),
        "total_actions": len(macro_actions),
        "actions": macro_actions,
    };

    return MacroWriteJob(
        trajectory_id=trajectory_id,
        stage=stage,
        target_path=trajectory.trajectory_folder / "macro.json",
        serialized_macro=json.dumps(macro_data, indent=2),
    );
}

impl TrajectoryWriter._create_screenshot_jobs(
    screenshot_queue_snapshot, trajectory, trajectory_id, stage
) -> List[ScreenshotWriteJob] {
    jobs: any = [];
    screenshots_folder: any = trajectory.trajectory_folder / "screenshots";
    screenshots_folder.mkdir(exist_ok=True);

    start_idx: any = trajectory.screenshot_count - len(screenshot_queue_snapshot);

    for (offset, screenshot_bytes) in enumerate(screenshot_queue_snapshot) {
        screenshot_idx: any = start_idx + offset;
        screenshot_path: any = screenshots_folder / f"{screenshot_idx:04d}.png";
        jobs.append(
            ScreenshotWriteJob(
                trajectory_id=trajectory_id,
                stage=stage,
                target_path=screenshot_path,
                screenshot_bytes=screenshot_bytes,
            ),
        );
    }

    return jobs;
}

impl TrajectoryWriter._create_gif_job(trajectory, trajectory_id, stage) -> Optional[GifWriteJob] {
    if trajectory.screenshot_count == 0 {
        return None;
    }

    screenshots_folder: any = trajectory.trajectory_folder / "screenshots";
    screenshots_folder.mkdir(exist_ok=True);

    return GifWriteJob(
        trajectory_id=trajectory_id,
        stage=stage,
        target_path=screenshots_folder / "trajectory.gif",
        screenshots_folder=screenshots_folder,
        screenshot_count=trajectory.screenshot_count,
    );
}

impl TrajectoryWriter._create_ui_state_jobs(
    ui_states_snapshot, trajectory, trajectory_id, stage
) -> List[UIStateWriteJob] {
    jobs: any = [];
    ui_states_folder: any = trajectory.trajectory_folder / "ui_states";
    ui_states_folder.mkdir(exist_ok=True);

    for (idx, ui_state) in enumerate(ui_states_snapshot) {
        ui_state_path: any = ui_states_folder / f"{idx:04d}.json";
        jobs.append(
            UIStateWriteJob(
                trajectory_id=trajectory_id,
                stage=stage,
                target_path=ui_state_path,
                serialized_state=json.dumps(ui_state, ensure_ascii=False, indent=2),
            ),
        );
    }

    return jobs;
}
