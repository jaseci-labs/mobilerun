impl Trajectory.init(goal: builtins.str = None, base_path: builtins.str = "trajectories") {
    self.events = [];
    self.screenshot_count = 0;
    self.screenshot_queue = [];
    self.ui_states = [];
    self.macro = [];
    self.goal = goal or "Mobilerun automation sequence";

    self.base_path = self._resolve_path(base_path);
    self.trajectory_folder = self._create_trajectory_folder();

    logger.info(f"📁 Trajectory folder: {self.trajectory_folder}");
}

impl Trajectory._resolve_path(config_path: builtins.str) -> any {
    import from pathlib { Path }

    path: any = Path(config_path);
    return path if path.is_absolute() else Path.cwd() / path;
}

impl Trajectory._create_trajectory_folder -> any {
    timestamp: any = time.strftime("%Y%m%d_%H%M%S");
    unique_id: any = `str(uuid.uuid4())[:8];
    folder: any = self.base_path / f"{timestamp}_{unique_id}";
    folder.mkdir(parents=True, exist_ok=True);
    return folder;
}

impl Trajectory.set_goal(goal: builtins.str) -> None {
    self.goal = goal;
}

impl Trajectory.get_trajectory -> List[Dict[builtins.str, Any]] {
    serializable_events: any = [];
    for event in self.events {
        event_dict: any = {
            "type": event.__class__.__name__,
            **{
                k: make_serializable(v)
                for (k, v) in event.__dict__.items()
                if not k.startswith("_")
            },
        };
        serializable_events.append(event_dict);
    }

    return serializable_events;
}

impl Trajectory.load_trajectory_folder(trajectory_folder: builtins.str) -> Dict[builtins.str, Any] {
    result: any = {
        "trajectory_data": None,
        "macro_data": None,
        "gif_path": None,
        "folder_path": trajectory_folder,
    };

    try {
        trajectory_json_path: any = os.path.join(trajectory_folder, "trajectory.json");
        if os.path.exists(trajectory_json_path) {
            with open(trajectory_json_path, "r") as f {
                result["trajectory_data"] = json.load(f);
            }
            logger.debug(f"📖 Loaded trajectory data from {trajectory_json_path}");
        }
        macro_json_path: any = os.path.join(trajectory_folder, "macro.json");
        if os.path.exists(macro_json_path) {
            with open(macro_json_path, "r") as f {
                result["macro_data"] = json.load(f);
            }
            logger.debug(f"📖 Loaded macro data from {macro_json_path}");
        }
        gif_path: any = os.path.join(trajectory_folder, "screenshots", "trajectory.gif");
        if os.path.exists(gif_path) {
            result["gif_path"] = gif_path;
            logger.debug(f"🎬 Found screenshot GIF at {gif_path}");
        }

        return result;
    } except Exception as e {
        logger.error(f"❌ Error loading trajectory folder {trajectory_folder}: {e}");
        return result;
    }
}

impl Trajectory.load_macro_sequence(macro_file_path: builtins.str) -> Dict[builtins.str, Any] {
    if os.path.isdir(macro_file_path) {
        macro_file_path = os.path.join(macro_file_path, "macro.json");
    }

    try {
        with open(macro_file_path, "r") as f {
            macro_data: any = json.load(f);
        }

        if macro_data.get("macro_schema_version") != MACRO_SCHEMA_VERSION {
            raise ValueError(UNSUPPORTED_SCHEMA_MESSAGE);
        }

        logger.debug(
            "📖 Loaded macro sequence with "
                + format(macro_data.get("total_actions", 0), "")
                + " actions from "
                + format(macro_file_path, ""),
        );
        return macro_data;
    } except FileNotFoundError {
        logger.error(f"❌ Macro file not found: {macro_file_path}");
        return {};
    } except json.JSONDecodeError as e {
        logger.error(f"❌ Error parsing macro file {macro_file_path}: {e}");
        return {};
    }
}

impl Trajectory.get_macro_summary(macro_data: Dict[builtins.str, Any]) -> Dict[builtins.str, Any] {
    if not macro_data or "actions" not in macro_data {
        return {"error": "Invalid macro data"};
    }

    actions: any = macro_data["actions"];
    action_types: any = {};
    for action in actions {
        action_type: any = action.get("action_type", "unknown");
        action_types[action_type] = action_types.get(action_type, 0) + 1;
    }
    timestamps: any = [action.get("timestamp") for action in actions if action.get("timestamp")];
    duration: any = max(timestamps) - min(timestamps) if len(timestamps) > 1 else 0;

    return {
        "version": macro_data.get("macro_schema_version", macro_data.get("version", "unknown")),
        "description": macro_data.get("description", "No description"),
        "total_actions": len(actions),
        "action_types": action_types,
        "duration_seconds": round(duration, 2) if duration > 0 else None,
        "timestamp": macro_data.get("timestamp", "unknown"),
    };
}

impl Trajectory.print_macro_summary(macro_file_path: builtins.str) -> None {
    macro_data: any = Trajectory.load_macro_sequence(macro_file_path);
    if not macro_data {
        print("❌ Could not load macro data");
        return;
    }

    summary: any = Trajectory.get_macro_summary(macro_data);

    print("=== Macro Summary ===");
    print(f"File: {macro_file_path}");
    print("Version: " + format(summary.get("version", "unknown"), ""));
    print("Description: " + format(summary.get("description", "No description"), ""));
    print("Timestamp: " + format(summary.get("timestamp", "unknown"), ""));
    print("Total actions: " + format(summary.get("total_actions", 0), ""));
    if summary.get("duration_seconds") {
        print("Duration: " + format(summary["duration_seconds"], "") + " seconds");
    }
    print("Action breakdown:");
    for (action_type, count) in summary.get("action_types", {}).items() {
        print(f"  - {action_type}: {count}");
    }
    print("=====================");
}

impl Trajectory.print_trajectory_folder_summary(trajectory_folder: builtins.str) -> None {
    folder_data: any = Trajectory.load_trajectory_folder(trajectory_folder);

    print("=== Trajectory Folder Summary ===");
    print(f"Folder: {trajectory_folder}");
    print(
        "Trajectory data: "
            + format("✅ Available" if folder_data["trajectory_data"] else "❌ Missing", ""),
    );
    print("Macro data: " + format("✅ Available" if folder_data["macro_data"] else "❌ Missing", ""));
    print(
        "Screenshot GIF: " + format("✅ Available" if folder_data["gif_path"] else "❌ Missing", "")
    );

    if folder_data["macro_data"] {
        print("\n--- Macro Summary ---");
        summary: any = Trajectory.get_macro_summary(folder_data["macro_data"]);
        print("Description: " + format(summary.get("description", "No description"), ""));
        print("Total actions: " + format(summary.get("total_actions", 0), ""));
        if summary.get("duration_seconds") {
            print("Duration: " + format(summary["duration_seconds"], "") + " seconds");
        }
        print("Action breakdown:");
        for (action_type, count) in summary.get("action_types", {}).items() {
            print(f"  - {action_type}: {count}");
        }
    }

    if folder_data["trajectory_data"] {
        print("\n--- Trajectory Summary ---");
        print("Total events: " + format(len(folder_data["trajectory_data"]), ""));
    }

    print("=================================");
}

impl Trajectory.print_trajectory_summary(trajectory_data: Dict[builtins.str, Any]) -> None {
    stats: any = get_trajectory_statistics(trajectory_data);

    print("=== Trajectory Summary ===");
    print("Goal: " + format(trajectory_data.get("goal", "Unknown"), ""));
    print("Success: " + format(trajectory_data.get("success", False), ""));
    print("Reason: " + format(trajectory_data.get("reason", "Unknown"), ""));
    print("Total steps: " + format(stats["total_steps"], ""));
    print("Step breakdown:");
    for (step_type, count) in stats["step_types"].items() {
        print(f"  - {step_type}: {count}");
    }
    print("Planning steps: " + format(stats["planning_steps"], ""));
    print("Execution steps: " + format(stats["execution_steps"], ""));
    print("Successful executions: " + format(stats["successful_executions"], ""));
    print("Failed executions: " + format(stats["failed_executions"], ""));
    print("==========================");
}

impl get_trajectory_statistics(
    trajectory_steps: List[Dict[builtins.str, Any]]
) -> Dict[builtins.str, Any] {
    step_types: any = {};
    for step in trajectory_steps {
        step_type: any = step.get("type", "unknown");
        step_types[step_type] = step_types.get(step_type, 0) + 1;
    }
    planning_steps: any = sum(
        count for (step_type, count) in step_types.items() if step_type.startswith("planner_")
    );
    execution_steps: any = sum(
        count for (step_type, count) in step_types.items() if step_type.startswith("fast_agent_")
    );
    successful_executions: any = sum(
        1
        for step in trajectory_steps
        if step.get("type") == "fast_agent_execution" and step.get("success", False),
    );
    failed_executions: any = sum(
        1
        for step in trajectory_steps
        if step.get("type") == "fast_agent_execution" and not step.get("success", True),
    );
    return {
        "total_steps": len(trajectory_steps),
        "step_types": step_types,
        "planning_steps": planning_steps,
        "execution_steps": execution_steps,
        "successful_executions": successful_executions,
        "failed_executions": failed_executions,
    };
}
