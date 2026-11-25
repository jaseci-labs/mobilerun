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

    def append_memory(text: str) -> None;

    async def complete(success: bool, reason: str = "", message: str = "") -> None;

    def queue_user_message(message: str) -> QueuedUserMessage;

    def drain_user_messages -> list[QueuedUserMessage];

    def update_current_app(package_name: str, activity_name: str) -> any;
}

glob DroidAgentState: any;

with entry {
    DroidAgentState = MobileAgentState;
}
