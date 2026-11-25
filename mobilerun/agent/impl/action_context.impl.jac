impl ActionContext.init(
    driver: "DeviceDriver",
    ui: "Optional[UIState]",
    shared_state: "MobileAgentState",
    state_provider: "StateProvider",
    app_opener_llm=None,
    credential_manager: "Optional[CredentialManager]" = None,
    streaming: bool = False,
    macro_recorder: "Optional[MacroRecorder]" = None,
) {
    self.driver = driver;
    self.ui = ui;
    self.shared_state = shared_state;
    self.state_provider = state_provider;
    self.app_opener_llm = app_opener_llm;
    self.credential_manager = credential_manager;
    self.streaming = streaming;
    self.macro_recorder = macro_recorder;
}
