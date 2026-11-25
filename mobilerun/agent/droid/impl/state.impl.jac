impl MobileAgentState.append_memory(text: str) -> None {
    text = text.strip();
    if not text {
        return;
    }
    if self.agent_memory {
        self.agent_memory += "\n" + text;
    } else {
        self.agent_memory = text;
    }
}

impl MobileAgentState.complete(success: bool, reason: str = "", message: str = "") -> None {
    answer: any = reason or message;
    if not success and not answer {
        raise ValueError("Reason for failure is required if success is False.");
    }
    self.finished = True;
    self.success = success;
    self.answer = answer or "Task completed successfully.";
}

impl MobileAgentState.queue_user_message(message: str) -> QueuedUserMessage {
    if not message or not message.strip() {
        raise ValueError("Cannot queue an empty or whitespace-only message.");
    }
    if self.workflow_completed {
        raise RuntimeError("Cannot queue messages: agent has already finished.");
    }
    queued: any = QueuedUserMessage(message=message, queued_at_step=self.step_number);
    self.pending_user_messages.append(queued);
    return queued;
}

impl MobileAgentState.drain_user_messages -> list[QueuedUserMessage] {
    if not self.pending_user_messages {
        return [];
    }
    messages: any = `list(self.pending_user_messages);
    self.pending_user_messages.clear();
    return messages;
}

impl MobileAgentState.update_current_app(package_name: str, activity_name: str) -> any {
    package_name = package_name.strip() if package_name else "";
    activity_name = activity_name.strip() if activity_name else "";
    effective_package: any = package_name or self.current_package_name;
    effective_activity: any = activity_name or self.current_activity_name;

    package_changed: any = operator.ne(effective_package, self.current_package_name);
    activity_changed: any = operator.ne(effective_activity, self.current_activity_name);

    if not (package_changed or activity_changed) {
        return;
    }

    if package_changed and effective_package {
        self.visited_packages.add(effective_package);
    }
    if activity_changed and effective_activity {
        self.visited_activities.add(effective_activity);
    }

    self.current_package_name = effective_package;
    self.current_activity_name = effective_activity;

    capture(
        PackageVisitEvent(
            package_name=effective_package or "Unknown",
            activity_name=effective_activity or "Unknown",
            step_number=self.step_number,
        ),
        user_id=self.user_id,
        config_enabled=self.telemetry_config_enabled,
    );
}
