import operator;

import from __future__ { annotations }

import from typing { Dict, List, Optional }

import from uuid { uuid4 }

import from llama_index.core.base.llms.types { ChatMessage }

import from pydantic { BaseModel, ConfigDict, Field }

class QueuedUserMessage(BaseModel) {
    has id: str = Field(default_factory=lambda -> any { `str(uuid4()) });

    has message: str;

    has queued_at_step: int = 0;
}

"""
    State model for MobileAgent workflow - shared across parent and child workflows.
    """
class MobileAgentState(BaseModel) {
    static has model_config: any = ConfigDict(arbitrary_types_allowed=True);

    has instruction: str = "";

    has step_number: int = 0;

    has runtype: str = "developer";

    has user_id: str | None = None;

    has telemetry_config_enabled: bool = Field(default=True, exclude=True);

    has platform: str = "Android";

    has device_date: str = "";

    has formatted_device_state: str = "";

    has focused_text: str = "";

    has a11y_tree: List[Dict] = Field(default_factory=list[any]);

    has phone_state: Dict = Field(default_factory=dict[any, any]);

    has screenshot: str | bytes | None = None;

    has width: int = 0;

    has height: int = 0;

    has previous_formatted_device_state: str = "";

    has app_card: str = "";

    has current_package_name: str = "";

    has current_activity_name: str = "";

    has visited_packages: set = Field(default_factory=set[any]);

    has visited_activities: set = Field(default_factory=set[any]);

    has last_thought: str = "";

    has previous_plan: str = "";

    has progress_summary: str = "";

    has plan: str = "";

    has current_subgoal: str = "";

    has answer: str = "";

    has action_history: List[Dict] = Field(default_factory=list[any]);

    has summary_history: List[str] = Field(default_factory=list[any]);

    has action_outcomes: List[bool] = Field(default_factory=list[any]);

    has error_descriptions: List[str] = Field(default_factory=list[any]);

    has last_action: Dict = Field(default_factory=dict[any, any]);

    has last_summary: str = "";

    has agent_memory: str = "";

    has finished: bool = False;

    has success: Optional[bool] = None;

    has message_history: List[ChatMessage] = Field(default_factory=list[any]);

    has error_flag_plan: bool = False;

    has err_to_manager_thresh: int = 2;

    has pending_user_messages: List[QueuedUserMessage] = Field(default_factory=list[any]);

    has workflow_completed: bool = False;

    has custom_variables: Dict = Field(default_factory=dict[any, any]);

    has output_dir: str = "";

    def append_memory(text: str) -> None {
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

    async def complete(success: bool, reason: str = "", message: str = "") -> None {
        answer: any = reason or message;
        if not success and not answer {
            raise ValueError("Reason for failure is required if success is False.");
        }
        self.finished = True;
        self.success = success;
        self.answer = answer or "Task completed successfully.";
    }

    def queue_user_message(message: str) -> QueuedUserMessage {
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

    def drain_user_messages -> list[QueuedUserMessage] {
        if not self.pending_user_messages {
            return [];
        }
        messages: any = `list(self.pending_user_messages);
        self.pending_user_messages.clear();
        return messages;
    }

    def update_current_app(package_name: str, activity_name: str) -> any {
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
}

glob DroidAgentState: any;

with entry {
    DroidAgentState = MobileAgentState;
}
