graph layers {
    layer all { *; }
}

graph import {
    mobilerun.agent.utils.actions --> tests.eval_coordinate_grounding { _convert_action_point }
    mobilerun.agent.utils.llm_picker --> tests.eval_coordinate_grounding { load_llm }
    mobilerun.agent.utils.vision_sizing --> tests.eval_coordinate_grounding { VisionResizePolicy }
    mobilerun.tools.filters --> tests.eval_coordinate_grounding { ConciseFilter }
    mobilerun.tools.formatters --> tests.eval_coordinate_grounding { IndexedFormatter }
    mobilerun.tools.ui.provider --> tests.eval_coordinate_grounding {
        AndroidStateProvider,
        resize_model_screenshot_with_grid,
    }
    mobilerun.agent.utils.android_device --> tests.test_android_device_selection;
    mobilerun.agent.utils.android_device --> tests.test_android_device_selection {
        AndroidDeviceSelectionError,
        resolve_android_serial,
    }
    mobilerun.cli.main --> tests.test_android_device_selection;
    mobilerun.cli.device_commands --> tests.test_android_device_selection;
    mobilerun.agent.droid.droid_agent --> tests.test_android_device_selection;
    mobilerun.config_manager.config_manager --> tests.test_android_device_selection {
        AgentConfig,
        DeviceConfig,
        MobileConfig,
        TelemetryConfig,
    }
    mobilerun.macro.cli --> tests.test_android_device_selection;
    mobilerun.agent.utils.android_device --> tests.test_android_portal_http_wiring {
        create_android_portal_http_driver,
        is_portal_http_url,
    }
    mobilerun.config_manager.config_manager --> tests.test_android_portal_http_wiring {
        DeviceConfig,
        MobileConfig,
        TelemetryConfig,
    }
    mobilerun.cli.device_commands --> tests.test_android_portal_http_wiring;
    mobilerun.cli.main --> tests.test_android_portal_http_wiring;
    mobilerun.agent.droid.droid_agent --> tests.test_android_portal_http_wiring;
    mobilerun.agent.utils.actions --> tests.test_android_tap_obstructions {
        click,
        long_press,
        type_secret,
        type_text,
    }
    mobilerun.tools.filters --> tests.test_android_tap_obstructions { ConciseFilter }
    mobilerun.tools.formatters --> tests.test_android_tap_obstructions { IndexedFormatter }
    mobilerun.tools.ui.provider --> tests.test_android_tap_obstructions { AndroidStateProvider }
    mobilerun.agent.utils.actions --> tests.test_android_vision_coordinate_contract;
    mobilerun.agent.utils.actions --> tests.test_android_vision_coordinate_contract {
        _convert_action_point,
        click_at,
    }
    mobilerun.tools.formatters --> tests.test_android_vision_coordinate_contract {
        IndexedFormatter,
    }
    mobilerun.tools.helpers.images --> tests.test_android_vision_coordinate_contract {
        fit_dimensions_to_max_side,
        image_dimensions,
        resize_image_to_max_side_with_grid,
    }
    mobilerun.tools.ui.provider --> tests.test_android_vision_coordinate_contract {
        AndroidStateProvider,
        StateProvider,
        resize_model_screenshot_with_grid,
        should_resize_model_screenshot,
    }
    mobilerun.tools.ui.screenshot_provider --> tests.test_android_vision_coordinate_contract {
        ScreenshotOnlyStateProvider,
    }
    mobilerun.agent.utils.vision_sizing --> tests.test_android_vision_coordinate_contract {
        VisionResizePolicy,
    }
    mobilerun.agent.executor.executor_agent --> tests.test_android_vision_coordinate_contract;
    mobilerun.agent.fast_agent.fast_agent --> tests.test_android_vision_coordinate_contract;
    mobilerun.agent.manager.manager_agent --> tests.test_android_vision_coordinate_contract;
    mobilerun.agent.manager.stateless_manager_agent --> tests.test_android_vision_coordinate_contract;
    mobilerun.agent.providers.anthropic --> tests.test_anthropic_oauth_llm {
        ANTHROPIC_HIGHRES_MODELS,
    }
    mobilerun.agent.utils.oauth.anthropic_oauth_llm --> tests.test_anthropic_oauth_llm {
        AnthropicOAuthLLM,
        DEFAULT_CC_VERSION,
        DEFAULT_CLAUDE_CODE_VERSION,
        DEFAULT_MAX_TOKENS,
        DEFAULT_USER_AGENT,
    }
    mobilerun.agent.usage --> tests.test_anthropic_oauth_streaming { get_usage_from_response }
    mobilerun.agent.utils.errors --> tests.test_anthropic_oauth_streaming { http_status_code }
    mobilerun.agent.utils.inference --> tests.test_anthropic_oauth_streaming {
        _is_permanent_http_client_error,
        _stream_response,
        acall_with_retries,
        acomplete_with_retries,
    }
    mobilerun.agent.utils.oauth.anthropic_oauth_llm --> tests.test_anthropic_oauth_streaming {
        AnthropicOAuthLLM,
        AnthropicOAuthStreamError,
        DEFAULT_CC_VERSION,
        DEFAULT_USER_AGENT,
    }
    mobilerun.agent.utils.llm_picker --> tests.test_anthropic_sdk_sampling { load_llm }
    mobilerun.app_cards.providers.composite_provider --> tests.test_app_card_platforms {
        CompositeAppCardProvider,
    }
    mobilerun.app_cards.providers.local_provider --> tests.test_app_card_platforms {
        LocalAppCardProvider,
    }
    mobilerun.app_cards.providers.server_provider --> tests.test_app_card_platforms {
        ServerAppCardProvider,
    }
    mobilerun.config_manager.path_resolver --> tests.test_app_card_platforms { PathResolver }
    mobilerun.agent.manager.manager_agent --> tests.test_app_card_platforms {
        ManagerAgent,
        _card_platform,
    }
    mobilerun.agent.droid.state --> tests.test_app_cards { MobileAgentState }
    mobilerun.agent.executor.executor_agent --> tests.test_app_cards { ExecutorAgent }
    mobilerun.agent.tool_registry --> tests.test_app_cards { ToolRegistry }
    mobilerun.agent.utils.prompt_resolver --> tests.test_app_cards { PromptResolver }
    mobilerun.app_cards.providers.local_provider --> tests.test_app_cards { LocalAppCardProvider }
    mobilerun.config_manager.config_manager --> tests.test_app_cards { AgentConfig }
    mobilerun.agent.droid.droid_agent --> tests.test_bounded_finalization;
    mobilerun.agent.droid.droid_agent --> tests.test_bounded_finalization { MobileAgent }
    mobilerun.agent.oneflows.structured_output_agent --> tests.test_bounded_finalization;
    mobilerun.agent.oneflows.structured_output_agent --> tests.test_bounded_finalization {
        StructuredOutputAgent,
    }
    mobilerun.telemetry.phoenix --> tests.test_bounded_finalization;
    mobilerun.tools.ui.provider --> tests.test_bounded_finalization;
    mobilerun.tools.ui.provider --> tests.test_bounded_finalization { AndroidStateProvider }
    mobilerun.agent.common.events --> tests.test_bounded_finalization { ScreenshotEvent }
    mobilerun.agent.droid.events --> tests.test_bounded_finalization { FinalizeEvent }
    mobilerun.agent.trajectory --> tests.test_bounded_finalization { TrajectoryWriter }
    mobilerun.agent.utils.chat_utils --> tests.test_chat_image_conversion { _ensure_image_bytes }
    mobilerun.cli.device_commands --> tests.test_cloud_cli;
    mobilerun.cli.main --> tests.test_cloud_cli { cli }
    mobilerun.config_manager.credential_paths --> tests.test_cloud_cli;
    mobilerun.config_manager.loader --> tests.test_config_loader_permissions { ConfigLoader }
    mobilerun.cli.configure_prompts --> tests.test_configure_prompts;
    mobilerun.cli.configure_prompts --> tests.test_configure_prompts { SelectChoice }
    mobilerun.cli.configure_wizard --> tests.test_configure_prompts;
    mobilerun.cli.configure_wizard --> tests.test_configure_prompts { ConfigureWizardCallbacks }
    mobilerun.config_manager --> tests.test_configure_prompts { MobileConfig }
    mobilerun.cli.device_commands --> tests.test_core_local_runtime;
    mobilerun.config_manager.config_manager --> tests.test_core_local_runtime { DeviceConfig }
    mobilerun.cli.deviceauth --> tests.test_deviceauth;
    mobilerun.tools --> tests.test_driver_reexports;
    mobilerun.tools.driver --> tests.test_driver_reexports {
        AndroidDriver,
        CloudDriver,
        DeviceDisconnectedError,
        DeviceDriver,
        IOSDriver,
        RecordingDriver,
        StealthDriver,
        VisualRemoteDriver,
    }
    mobilerun.agent.utils.errors --> tests.test_error_descriptions {
        HtmlErrorPageFilter,
        describe_error,
    }
    mobilerun.agent.utils.inference --> tests.test_error_descriptions { acall_with_retries }
    mobilerun --> tests.test_error_descriptions;
    mobilerun.agent.tool_registry --> tests.test_error_descriptions { ToolRegistry }
    mobilerun.agent.action_result --> tests.test_fast_agent_block_failure { ActionResult }
    mobilerun.agent.droid.state --> tests.test_fast_agent_block_failure { MobileAgentState }
    mobilerun.agent.fast_agent.fast_agent --> tests.test_fast_agent_block_failure { FastAgent }
    mobilerun.agent.action_result --> tests.test_fast_agent_malformed_tool_guard { ActionResult }
    mobilerun.agent.droid.state --> tests.test_fast_agent_malformed_tool_guard { MobileAgentState }
    mobilerun.agent.fast_agent.fast_agent --> tests.test_fast_agent_malformed_tool_guard {
        FastAgent,
    }
    mobilerun.agent.action_result --> tests.test_fast_agent_multi_block { ActionResult }
    mobilerun.agent.droid.state --> tests.test_fast_agent_multi_block { MobileAgentState }
    mobilerun.agent.fast_agent.fast_agent --> tests.test_fast_agent_multi_block { FastAgent }
    mobilerun.agent.action_result --> tests.test_fast_agent_native_tools { ActionResult }
    mobilerun.agent.droid.state --> tests.test_fast_agent_native_tools { MobileAgentState }
    mobilerun.agent.fast_agent.fast_agent --> tests.test_fast_agent_native_tools { FastAgent }
    mobilerun.agent.tool_registry --> tests.test_fast_agent_native_tools { ToolRegistry }
    mobilerun.agent.utils.chat_utils --> tests.test_fast_agent_native_tools { limit_history }
    mobilerun.agent.utils.inference --> tests.test_fast_agent_native_tools { acall_with_retries }
    mobilerun.agent.utils.llm_picker --> tests.test_fast_agent_native_tools { load_llm }
    mobilerun.agent.utils.oauth.grok_oauth_llm --> tests.test_fast_agent_native_tools { GrokOAuth }
    mobilerun.agent.utils.oauth.openai_oauth_llm --> tests.test_fast_agent_native_tools {
        OpenAIOAuth,
    }
    mobilerun.agent.fast_agent.xml_parser --> tests.test_fast_agent_xml_parser {
        ToolCallParseStatus,
        extract_add_memory,
        format_tool_calls,
        parse_tool_calls,
        parse_tool_calls_detailed,
    }
    mobilerun.agent.droid.droid_agent --> tests.test_finalization_budget { _run_finalize_stage }
    mobilerun.agent.trajectory.writer --> tests.test_finalization_budget { WriterWorker }
    mobilerun.agent.droid.droid_agent --> tests.test_finalization_workflow;
    mobilerun.agent.droid.droid_agent --> tests.test_finalization_workflow { MobileAgent }
    mobilerun.agent.droid.events --> tests.test_finalization_workflow {
        FastAgentExecuteEvent,
        FinalizeEvent,
        ManagerInputEvent,
        ResultEvent,
    }
    mobilerun.agent.trajectory --> tests.test_finalization_workflow { TrajectoryWriter }
    mobilerun.agent.utils.llm_picker --> tests.test_gemini_defaults { load_llm }
    mobilerun.config_manager.config_manager --> tests.test_gemini_defaults { MobileConfig }
    mobilerun.config_manager.migrations --> tests.test_gemini_defaults { CURRENT_VERSION }
    mobilerun.agent.providers.registry --> tests.test_gemini_oauth_llm {
        GEMINI_OAUTH_RETIRED_MODELS,
        resolve_provider_variant,
    }
    mobilerun.agent.providers.setup_service --> tests.test_gemini_oauth_llm {
        SetupSelection,
        create_profile_for_variant,
    }
    mobilerun.agent.utils.llm_picker --> tests.test_gemini_oauth_llm { load_llm }
    mobilerun.agent.utils.oauth.gemini_oauth_code_assist_llm --> tests.test_gemini_oauth_llm {
        DEFAULT_CLIENT_ID,
        DEFAULT_CREDENTIAL_SLOT,
        GeminiOAuthCodeAssistLLM,
    }
    mobilerun.cli.oauth_actions --> tests.test_gemini_oauth_llm { GEMINI_OAUTH_DEFAULT_MODEL }
    mobilerun.cli.configure_wizard --> tests.test_gemini_oauth_llm { _oauth_credentials_present }
    mobilerun.agent.providers.grok --> tests.test_grok_api {
        GROK_API_DEFAULT_MODEL,
        GROK_API_MODELS,
        GROK_OAUTH_MODELS,
        XAI_API_BASE,
        normalize_grok_model_id,
    }
    mobilerun.agent.providers.registry --> tests.test_grok_api {
        VARIANT_ENV_KEY_SLOT,
        list_models_for_variant,
        normalize_model_id_for_variant,
        resolve_provider_variant,
    }
    mobilerun.agent.providers.setup_service --> tests.test_grok_api {
        SetupSelection,
        create_profile_for_variant,
    }
    mobilerun.agent.usage --> tests.test_grok_api { get_usage_from_response }
    mobilerun.agent.utils.llm_picker --> tests.test_grok_api { load_llm, normalize_provider_name }
    mobilerun.config_manager.env_keys --> tests.test_grok_api;
    mobilerun.cli.configure_wizard --> tests.test_grok_cli;
    mobilerun.cli.configure_wizard --> tests.test_grok_cli { ConfigureWizardCallbacks }
    mobilerun.cli.main --> tests.test_grok_cli;
    mobilerun.agent.providers.registry --> tests.test_grok_cli { resolve_provider_variant }
    mobilerun.agent.utils.oauth.login_timeout --> tests.test_grok_cli { OAuthLoginDeadline }
    mobilerun.cli.oauth_actions --> tests.test_grok_cli;
    mobilerun.config_manager --> tests.test_grok_cli { MobileConfig }
    mobilerun.agent.providers.grok --> tests.test_grok_oauth { GROK_OAUTH_DEFAULT_MODEL }
    mobilerun.agent.usage --> tests.test_grok_oauth { get_usage_from_response }
    mobilerun.agent.utils.oauth.grok_oauth_llm --> tests.test_grok_oauth {
        DEFAULT_GROK_CONTEXT_WINDOW,
        DEFAULT_GROK_MODEL,
        DEFAULT_GROK_OAUTH_CLIENT_ID,
        DEFAULT_GROK_OAUTH_ISSUER,
        DEFAULT_GROK_OAUTH_PROXY,
        DEFAULT_GROK_OAUTH_SCOPES,
        GROK_CLI_COMPAT_VERSION,
        GROK_CLI_COMPAT_VERSION_HEADER,
        GrokIDTokenValidator,
        GrokOAuth,
        GrokOAuthAuth,
        GrokOAuthCredentialStore,
        GrokOAuthCredentials,
        GrokOAuthError,
        GrokOAuthReloginRequired,
        GrokOAuthSessionManager,
        _parse_callback_query,
    }
    mobilerun.agent.utils.oauth.login_timeout --> tests.test_grok_oauth { OAuthLoginDeadline }
    mobilerun.config_manager.auth_profile_store --> tests.test_grok_oauth;
    mobilerun.config_manager.auth_profile_store --> tests.test_grok_oauth {
        AuthProfileFormatError,
        AuthProfileStore,
    }
    mobilerun.config_manager.env_keys --> tests.test_grok_oauth;
    mobilerun.agent.utils.inference --> tests.test_inference_retries {
        _empty_response_diagnostics,
        _http_status_code,
        _log_empty_response,
        acall_with_retries,
        acomplete_with_retries,
        astructured_predict_with_retries,
    }
    mobilerun.config_manager.config_manager --> tests.test_ios_local_portal_wiring { DeviceConfig }
    mobilerun.tools.filters --> tests.test_ios_local_portal_wiring { ConciseFilter, DetailedFilter }
    mobilerun.tools.formatters --> tests.test_ios_local_portal_wiring { IndexedFormatter }
    mobilerun.tools.ui.provider --> tests.test_ios_local_portal_wiring { AndroidStateProvider }
    mobilerun.cli.device_commands --> tests.test_ios_local_portal_wiring;
    mobilerun.tools.ui.ios_provider --> tests.test_ios_provider { IOSStateProvider }
    mobilerun.agent.utils.actions --> tests.test_ios_vision_coordinate_contract {
        _convert_action_point,
        click_at,
        swipe,
    }
    mobilerun.tools.helpers.images --> tests.test_ios_vision_coordinate_contract {
        fit_dimensions_to_max_side,
    }
    mobilerun.tools.ui.ios_provider --> tests.test_ios_vision_coordinate_contract {
        IOSStateProvider,
    }
    mobilerun.tools.ui.provider --> tests.test_ios_vision_coordinate_contract {
        should_resize_model_screenshot,
    }
    mobilerun.agent.droid.droid_agent --> tests.test_ios_vision_coordinate_contract {
        _effective_disabled_tools,
    }
    mobilerun.config_manager.config_manager --> tests.test_ios_vision_coordinate_contract {
        DEFAULT_DISABLED_TOOLS,
    }
    mobilerun.cli.main --> tests.test_keyboard_cleanup;
    mobilerun.config_manager.config_manager --> tests.test_keyboard_cleanup {
        DeviceConfig,
        MobileConfig,
        TelemetryConfig,
    }
    mobilerun.agent.droid.droid_agent --> tests.test_keyboard_cleanup;
    mobilerun.agent.utils.tracing_setup --> tests.test_langfuse_v4;
    mobilerun.agent.utils.tracing_setup --> tests.test_langfuse_v4 { apply_session_context }
    mobilerun.config_manager.config_manager --> tests.test_langfuse_v4 {
        AgentConfig,
        MobileConfig,
        TelemetryConfig,
        TracingConfig,
    }
    mobilerun.telemetry.langfuse_processor --> tests.test_langfuse_v4;
    mobilerun.telemetry.langfuse_processor --> tests.test_langfuse_v4 {
        LangfuseSpanProcessor,
        _LangfuseSpanProcessor,
        _LangfuseTracerProvider,
    }
    mobilerun.agent.droid.droid_agent --> tests.test_langfuse_v4 { MobileAgent }
    mobilerun.agent.droid.events --> tests.test_langfuse_v4 { ResultEvent }
    mobilerun.tools.filters --> tests.test_langfuse_v4 { ConciseFilter }
    mobilerun.tools.formatters --> tests.test_langfuse_v4 { IndexedFormatter }
    mobilerun.tools.ui.provider --> tests.test_langfuse_v4;
    mobilerun.tools.ui.provider --> tests.test_langfuse_v4 { AndroidStateProvider }
    mobilerun.agent.providers.registry --> tests.test_llm_picker { OPENAI_GPT6_MODELS }
    mobilerun.agent.utils.llm_picker --> tests.test_llm_picker;
    mobilerun.agent.utils.llm_picker --> tests.test_llm_picker {
        _prepare_ollama_kwargs,
        load_llm,
        load_llms_from_profiles,
        normalize_provider_name,
    }
    mobilerun.config_manager.config_manager --> tests.test_llm_picker { LLMProfile }
    mobilerun.agent.providers.setup_service --> tests.test_llm_picker { DEFAULT_KWARGS_BY_VARIANT }
    mobilerun.macro.replay --> tests.test_macro_guarded_replay { MacroPlayer }
    mobilerun.macro.state --> tests.test_macro_guarded_replay { normalize_ui_state }
    mobilerun.agent.utils.actions --> tests.test_macro_recording_actions;
    mobilerun.agent.utils.actions --> tests.test_macro_recording_actions {
        click,
        open_app,
        type_secret,
        type_text,
        wait,
    }
    mobilerun.macro.recorder --> tests.test_macro_recording_actions { MacroRecorder }
    mobilerun.macro.matcher --> tests.test_macro_state_matcher { compare_states }
    mobilerun.macro.state --> tests.test_macro_state_matcher { normalize_ui_state }
    mobilerun.agent.trajectory.writer --> tests.test_macro_v2_schema { TrajectoryWriter }
    mobilerun.agent.utils.trajectory --> tests.test_macro_v2_schema { Trajectory }
    mobilerun.macro.state --> tests.test_macro_v2_schema {
        MACRO_SCHEMA_VERSION,
        UNSUPPORTED_SCHEMA_MESSAGE,
    }
    mobilerun.agent.manager.stateless_manager_agent --> tests.test_manager_prompt_selection {
        StatelessManagerAgent,
    }
    mobilerun.agent.utils.prompt_resolver --> tests.test_manager_prompt_selection { PromptResolver }
    mobilerun.config_manager.config_manager --> tests.test_manager_prompt_selection {
        AgentConfig,
        DEFAULT_MANAGER_SYSTEM_PROMPT,
        DEFAULT_STATELESS_MANAGER_SYSTEM_PROMPT,
        ManagerConfig,
    }
    mobilerun.config_manager.migrations --> tests.test_manager_prompt_selection {
        CURRENT_VERSION,
        migrate,
    }
    mobilerun.agent.droid.droid_agent --> tests.test_manager_response_validation { MobileAgent }
    mobilerun.agent.droid.events --> tests.test_manager_response_validation {
        ExecutorInputEvent,
        FinalizeEvent,
        ManagerInputEvent,
        ManagerPlanEvent,
    }
    mobilerun.agent.manager.manager_agent --> tests.test_manager_response_validation {
        ManagerAgent,
    }
    mobilerun.agent.manager.prompts --> tests.test_manager_response_validation {
        ManagerResponseValidationError,
        parse_manager_response,
        validate_manager_response,
    }
    mobilerun.agent.manager.stateless_manager_agent --> tests.test_manager_response_validation {
        StatelessManagerAgent,
    }
    mobilerun.mcp.client --> tests.test_mcp_stdio_compatibility;
    mobilerun.mcp.client --> tests.test_mcp_stdio_compatibility { MCPClientManager }
    mobilerun.mcp.adapter --> tests.test_mcp_stdio_compatibility { mcp_to_mobilerun_tools }
    mobilerun.mcp.config --> tests.test_mcp_stdio_compatibility { MCPConfig, MCPServerConfig }
    mobilerun.agent.providers.minimax --> tests.test_minimax_configuration;
    mobilerun.agent.providers.minimax --> tests.test_minimax_configuration {
        MINIMAX_CHINA_BASE_URL,
        MINIMAX_GLOBAL_BASE_URL,
        MINIMAX_LEGACY_BASE_URL,
    }
    mobilerun.cli.configure_wizard --> tests.test_minimax_configuration;
    mobilerun.cli.configure_wizard --> tests.test_minimax_configuration {
        ConfigureWizardCallbacks,
        ConfigureWizardState,
    }
    mobilerun.config_manager.config_manager --> tests.test_minimax_configuration;
    mobilerun.config_manager.config_manager --> tests.test_minimax_configuration {
        LLMProfile,
        MobileConfig,
    }
    mobilerun.agent.providers.registry --> tests.test_minimax_configuration {
        resolve_provider_variant,
    }
    mobilerun.agent.providers.setup_service --> tests.test_minimax_configuration {
        SetupSelection,
        apply_selection_to_roles,
        create_profile_for_variant,
        family_choices,
    }
    mobilerun.agent.utils.llm_picker --> tests.test_minimax_configuration { load_llm }
    mobilerun.config_manager.env_keys --> tests.test_minimax_configuration { ApiKeySources }
    mobilerun.agent.utils.actions --> tests.test_normalized_screenshot_coordinates {
        click_area,
        click_at,
        long_press_at,
        swipe,
    }
    mobilerun.agent.utils.signatures --> tests.test_normalized_screenshot_coordinates {
        build_tool_registry,
    }
    mobilerun.agent.utils.vision_sizing --> tests.test_normalized_screenshot_coordinates {
        model_uses_normalized_coordinates,
    }
    mobilerun.tools.ui.provider --> tests.test_normalized_screenshot_coordinates {
        AndroidStateProvider,
        resize_model_screenshot_with_grid,
    }
    mobilerun.tools.ui.screenshot_provider --> tests.test_normalized_screenshot_coordinates {
        ScreenshotOnlyStateProvider,
    }
    mobilerun.tools.ui.state --> tests.test_normalized_screenshot_coordinates { UIState }
    mobilerun.agent.droid.droid_agent --> tests.test_normalized_screenshot_coordinates;
    mobilerun.agent.droid.droid_agent --> tests.test_normalized_screenshot_coordinates {
        _effective_disabled_tools,
    }
    mobilerun.config_manager.config_manager --> tests.test_normalized_screenshot_coordinates {
        AgentConfig,
        DEFAULT_DISABLED_TOOLS,
        ExecutorConfig,
        FastAgentConfig,
        ManagerConfig,
        MobileConfig,
        TelemetryConfig,
    }
    mobilerun.tools.filters --> tests.test_normalized_screenshot_coordinates { ConciseFilter }
    mobilerun.tools.formatters --> tests.test_normalized_screenshot_coordinates { IndexedFormatter }
    mobilerun.agent.utils.oauth.anthropic_oauth_llm --> tests.test_oauth_login_timeout;
    mobilerun.agent.utils.oauth.anthropic_oauth_llm --> tests.test_oauth_login_timeout {
        AnthropicOAuthLLM,
    }
    mobilerun.agent.utils.oauth.gemini_oauth_code_assist_llm --> tests.test_oauth_login_timeout;
    mobilerun.agent.utils.oauth.gemini_oauth_code_assist_llm --> tests.test_oauth_login_timeout {
        GeminiOAuthCodeAssistLLM,
    }
    mobilerun.agent.utils.oauth.openai_oauth_llm --> tests.test_oauth_login_timeout;
    mobilerun.agent.utils.oauth.openai_oauth_llm --> tests.test_oauth_login_timeout { OpenAIOAuth }
    mobilerun.agent.utils.oauth.login_timeout --> tests.test_oauth_login_timeout {
        OAuthLoginDeadline,
    }
    mobilerun.config_manager.auth_profile_store --> tests.test_oauth_login_timeout {
        AuthProfileStore,
    }
    mobilerun.agent.utils.oauth.anthropic_oauth_llm --> tests.test_oauth_manual_env_var;
    mobilerun.agent.utils.oauth.gemini_oauth_code_assist_llm --> tests.test_oauth_manual_env_var;
    mobilerun.agent.utils.oauth.openai_oauth_llm --> tests.test_oauth_manual_env_var;
    mobilerun.agent.utils.oauth.login_timeout --> tests.test_oauth_manual_env_var {
        OAuthLoginDeadline,
    }
    mobilerun.agent.fast_agent.xml_parser --> tests.test_open_app_identifier {
        parse_tool_calls_detailed,
    }
    mobilerun.agent.utils.actions --> tests.test_open_app_identifier;
    mobilerun.agent.utils.actions --> tests.test_open_app_identifier { open_bundle_id }
    mobilerun.agent.utils.signatures --> tests.test_open_app_identifier { build_tool_registry }
    mobilerun.agent.providers --> tests.test_openai_oauth_llm { resolve_provider_variant }
    mobilerun.agent.providers.setup_service --> tests.test_openai_oauth_llm {
        SetupSelection,
        create_profile_for_variant,
    }
    mobilerun.agent.utils.oauth.openai_oauth_llm --> tests.test_openai_oauth_llm {
        DEFAULT_BACKEND_API_BASE,
        OpenAIOAuth,
    }
    mobilerun.agent.usage --> tests.test_openai_oauth_llm { get_usage_from_response }
    mobilerun.agent.utils.inference --> tests.test_openai_oauth_llm { _stream_response }
    mobilerun.agent.utils.tracing_setup --> tests.test_phoenix_tracing;
    mobilerun.telemetry.phoenix --> tests.test_phoenix_tracing;
    mobilerun.tools.ui.provider --> tests.test_portal_a11y_recovery;
    mobilerun.tools.ui.provider --> tests.test_portal_a11y_recovery {
        AndroidStateProvider,
        fetch_state_with_retry,
    }
    mobilerun --> tests.test_prompt_loader_sandbox;
    mobilerun.config_manager.prompt_loader --> tests.test_prompt_loader_sandbox { PromptLoader }
    mobilerun.agent.providers.registry --> tests.test_provider_defaults { resolve_provider_variant }
    mobilerun.agent.providers.setup_service --> tests.test_provider_defaults {
        SetupSelection,
        create_profile_for_variant,
    }
    mobilerun.agent.utils.llm_picker --> tests.test_provider_defaults { load_llm }
    mobilerun.cli.oauth_actions --> tests.test_provider_defaults;
    mobilerun.agent.providers.registry --> tests.test_provider_registry {
        list_models_for_variant,
        model_display_name_for_variant,
        normalize_model_id_for_variant,
        resolve_provider_variant,
    }
    mobilerun.config_manager.config_manager --> tests.test_provider_registry {
        LLMProfile,
        MobileConfig,
    }
    mobilerun --> tests.test_public_api_compatibility;
    mobilerun --> tests.test_public_api_compatibility { DroidAgentState }
    mobilerun.agent.droid --> tests.test_public_api_compatibility { MobileAgentState }
    mobilerun --> tests.test_sdk_debug_logging;
    mobilerun.agent.droid.droid_agent --> tests.test_sdk_debug_logging;
    mobilerun.agent.utils.portal_setup --> tests.test_sdk_debug_logging { portal_version_kwargs }
    mobilerun.config_manager.config_manager --> tests.test_sdk_debug_logging {
        AgentConfig,
        AppCardConfig,
        LoggingConfig,
        MobileConfig,
        TelemetryConfig,
    }
    mobilerun.cli.doctor --> tests.test_sdk_debug_logging;
    mobilerun.cli.main --> tests.test_sdk_debug_logging;
    mobilerun.cli.main --> tests.test_setup_portal_explicit_apk;
    mobilerun.tools.ui.provider --> tests.test_state_fetch_retry_policy;
    mobilerun.tools.ui.provider --> tests.test_state_fetch_retry_policy { fetch_state_with_retry }
    mobilerun.cli.device_commands --> tests.test_state_fetch_retry_policy;
    mobilerun.agent.usage --> tests.test_streaming_usage { get_usage_from_response, track_usage }
    mobilerun.agent.utils.inference --> tests.test_streaming_usage { acall_with_retries }
    mobilerun.agent.utils.llm_picker --> tests.test_streaming_usage { load_llm }
    mobilerun.telemetry.tracker --> tests.test_telemetry;
    mobilerun.telemetry.events --> tests.test_telemetry {
        MobileAgentFinalizeEvent,
        MobileAgentInitEvent,
        PackageVisitEvent,
    }
    mobilerun.agent.droid.state --> tests.test_telemetry;
    mobilerun.agent.droid.droid_agent --> tests.test_telemetry;
    mobilerun.config_manager.config_manager --> tests.test_telemetry {
        AgentConfig,
        MobileConfig,
        TelemetryConfig,
    }
    mobilerun.agent.droid.events --> tests.test_telemetry { FinalizeEvent }
    mobilerun.cli.main --> tests.test_telemetry;
    mobilerun.agent.utils.actions --> tests.test_type_action { type_text }
    mobilerun.agent.utils.signatures --> tests.test_type_action { build_tool_registry }
    mobilerun.tools.filters --> tests.test_ui_tree_null_children { ConciseFilter, DetailedFilter }
    mobilerun.tools.formatters --> tests.test_ui_tree_null_children { IndexedFormatter }
    mobilerun.tools.helpers.element_search --> tests.test_ui_tree_null_children { flatten_tree }
    mobilerun.agent.usage --> tests.test_usage {
        TokenCountingHandler,
        create_tracker,
        get_usage_from_response,
        track_usage,
    }
    mobilerun.agent.utils.llm_picker --> tests.test_usage { load_llm }
    mobilerun.agent.utils.oauth.gemini_oauth_code_assist_llm --> tests.test_usage {
        GeminiOAuthCodeAssistLLM,
    }
    mobilerun.cli.main --> tests.test_vision_only_run_cli { cli, run_command }
    mobilerun.config_manager.config_manager --> tests.test_vision_only_run_cli { MobileConfig }
    mobilerun.agent.utils.vision_sizing --> tests.test_vision_sizing {
        VisionResizePolicy,
        model_effective_dims,
    }
    mobilerun.tools.helpers.images --> tests.test_vision_sizing { anthropic_resized_size }
    mobilerun.agent.droid.droid_agent --> tests.test_visual_remote_connection {
        MobileAgent,
        _effective_disabled_tools,
    }
    mobilerun.agent.utils.actions --> tests.test_visual_remote_connection {
        click_area,
        click_at,
        long_press_at,
        swipe,
    }
    mobilerun.agent.utils.signatures --> tests.test_visual_remote_connection { build_tool_registry }
    mobilerun.config_manager.config_manager --> tests.test_visual_remote_connection { MobileConfig }
    mobilerun.config_manager.prompt_loader --> tests.test_visual_remote_connection { PromptLoader }
    mobilerun.tools.helpers.images --> tests.test_visual_remote_connection {
        image_dimensions,
        resize_image_to_max_side,
        resize_image_to_max_side_with_grid,
    }
    mobilerun.tools.ui.screenshot_provider --> tests.test_visual_remote_connection {
        ScreenshotOnlyStateProvider,
    }
    mobilerun.tools.ui.state --> tests.test_visual_remote_connection { UIState }
    include mobilerun.agent.droid.events ++> mobilerun.agent { ResultEvent }
    mobilerun.telemetry.events ++> mobilerun.telemetry.tracker { TelemetryEvent }
    mobilerun.macro.state ++> mobilerun.macro.recorder { build_screen_snapshot }
    mobilerun.tools.filters.base ++> mobilerun.tools.filters.concise_filter { TreeFilter }
    mobilerun.tools.filters.base ++> mobilerun.tools.filters.detailed_filter { TreeFilter }
    mobilerun.tools.ui.state ++> mobilerun.tools.ui.stealth_state { UIState }
    mobilerun.tools.helpers.coordinate ++> mobilerun.tools.ui.state { NORMALIZED_MAX, to_absolute }
    mobilerun.tools.helpers.geometry ++> mobilerun.tools.ui.state {
        find_clear_point,
        find_uncovered_point,
        rects_overlap,
    }
    mobilerun.agent.usage ++> mobilerun.agent.executor.events { UsageResult }
    mobilerun.agent.fast_agent.xml_parser ++> mobilerun.agent.fast_agent.events {
        ToolCallParseStatus,
    }
    mobilerun.agent.usage ++> mobilerun.agent.fast_agent.events { UsageResult }
    mobilerun.agent.fast_agent.xml_parser ++> mobilerun.agent.fast_agent.native_tools {
        ToolCall,
        ToolCallParseResult,
        ToolCallParseStatus,
        ToolResult,
        _coerce_param,
    }
    mobilerun.agent.usage ++> mobilerun.agent.manager.events { UsageResult }
    mobilerun.macro.state ++> mobilerun.macro.matcher { node_semantic_key }
    include mobilerun.log_handlers ++> mobilerun.cli.logs {
        CLILogHandler,
        TUILogHandler,
        configure_logging,
    }
    include mobilerun.tools.helpers.coordinate ++> mobilerun.tools.helpers {
        NORMALIZED_MAX,
        bounds_to_normalized,
        to_absolute,
        to_normalized,
    }
    include mobilerun.tools.helpers.geometry ++> mobilerun.tools.helpers {
        find_clear_point,
        rects_overlap,
    }
    include mobilerun.tools.helpers.images ++> mobilerun.tools.helpers { image_dimensions }
    include mobilerun.telemetry.events ++> mobilerun.telemetry {
        DroidAgentFinalizeEvent,
        DroidAgentInitEvent,
        MobileAgentFinalizeEvent,
        MobileAgentInitEvent,
        PackageVisitEvent,
    }
    include mobilerun.telemetry.tracker ++> mobilerun.telemetry {
        capture,
        flush,
        print_telemetry_message,
    }
    include mobilerun.tools.filters.base ++> mobilerun.tools.filters { TreeFilter }
    include mobilerun.tools.filters.concise_filter ++> mobilerun.tools.filters { ConciseFilter }
    include mobilerun.tools.filters.detailed_filter ++> mobilerun.tools.filters { DetailedFilter }
    mobilerun.agent.common.events ++> mobilerun.cli.event_handler {
        RecordUIStateEvent,
        ScreenshotEvent,
    }
    mobilerun.agent.droid.events ++> mobilerun.cli.event_handler {
        ExecutorResultEvent,
        FastAgentExecuteEvent,
        FastAgentResultEvent,
        FinalizeEvent,
    }
    mobilerun.agent.executor.events ++> mobilerun.cli.event_handler {
        ExecutorActionEvent,
        ExecutorActionResultEvent,
    }
    mobilerun.agent.fast_agent.events ++> mobilerun.cli.event_handler {
        FastAgentEndEvent,
        FastAgentInputEvent,
        FastAgentOutputEvent,
        FastAgentResponseEvent,
        FastAgentToolCallEvent,
    }
    mobilerun.agent.manager.events ++> mobilerun.cli.event_handler {
        ManagerContextEvent,
        ManagerPlanDetailsEvent,
        ManagerResponseEvent,
    }
    mobilerun.telemetry ++> mobilerun.agent.droid.state { PackageVisitEvent, capture }
    mobilerun.tools.helpers.coordinate ++> mobilerun.tools.formatters.indexed_formatter {
        bounds_to_normalized,
    }
    mobilerun.tools.helpers.geometry ++> mobilerun.tools.formatters.indexed_formatter {
        rects_overlap,
    }
    mobilerun.tools.formatters.base ++> mobilerun.tools.formatters.indexed_formatter {
        TreeFormatter,
    }
    mobilerun.agent.utils.errors ++> mobilerun.agent.utils.inference {
        describe_error,
        http_status_code as _http_status_code,
    }
    mobilerun.macro.state ++> mobilerun.agent.trajectory.writer { MACRO_SCHEMA_VERSION }
    mobilerun.agent.providers.anthropic ++> mobilerun.agent.providers.registry {
        ANTHROPIC_API_DEFAULT_MODEL,
        ANTHROPIC_API_MODELS,
        ANTHROPIC_OAUTH_DEFAULT_MODEL,
        ANTHROPIC_OAUTH_MODELS,
    }
    mobilerun.agent.providers.grok ++> mobilerun.agent.providers.registry {
        GROK_API_DEFAULT_MODEL,
        GROK_API_MODELS,
        GROK_OAUTH_DEFAULT_MODEL,
        GROK_OAUTH_LEGACY_MODELS,
        GROK_OAUTH_MODELS,
        XAI_API_BASE,
        normalize_grok_model_id,
    }
    mobilerun.agent.providers.minimax ++> mobilerun.agent.providers.registry {
        MINIMAX_DEFAULT_MODEL,
        MINIMAX_GLOBAL_BASE_URL,
    }
    mobilerun.agent.providers.types ++> mobilerun.agent.providers.registry {
        ProviderFamilySpec,
        ProviderVariantSpec,
    }
    mobilerun.config_manager.credential_paths ++> mobilerun.agent.providers.registry {
        ANTHROPIC_OAUTH_CREDENTIAL_PATH,
        GEMINI_OAUTH_CREDENTIAL_PATH,
        GROK_OAUTH_CREDENTIAL_PATH,
        OPENAI_OAUTH_CREDENTIAL_PATH,
    }
    mobilerun.config_manager.auth_profile_store ++> mobilerun.config_manager.env_keys {
        AuthProfileStore,
    }
    mobilerun.config_manager.credential_paths ++> mobilerun.config_manager.env_keys {
        AUTH_PROFILES_PATH as _DEFAULT_AUTH_PROFILES_PATH,
    }
    include mobilerun.tools.formatters.base ++> mobilerun.tools.formatters { TreeFormatter }
    include mobilerun.tools.formatters.indexed_formatter ++> mobilerun.tools.formatters {
        IndexedFormatter,
    }
    mobilerun.app_cards.app_card_provider ++> mobilerun.app_cards.providers.local_provider {
        AppCardProvider,
    }
    mobilerun.config_manager.path_resolver ++> mobilerun.app_cards.providers.local_provider {
        PathResolver,
    }
    mobilerun.app_cards.app_card_provider ++> mobilerun.app_cards.providers.server_provider {
        AppCardProvider,
    }
    mobilerun.agent.utils.errors ++> mobilerun.agent.oneflows.structured_output_agent {
        describe_error,
    }
    mobilerun.agent.utils.inference ++> mobilerun.agent.oneflows.structured_output_agent {
        astructured_predict_with_retries,
    }
    include mobilerun.agent.trajectory.writer ++> mobilerun.agent.trajectory {
        TrajectoryWriter,
        make_serializable,
    }
    mobilerun.agent.providers.grok ++> mobilerun.agent.utils.oauth.grok_oauth_llm {
        GROK_OAUTH_DEFAULT_MODEL,
        GROK_OAUTH_LEGACY_MODELS,
        GROK_OAUTH_MODELS,
        normalize_grok_model_id,
        sanitize_grok_responses_kwargs,
    }
    mobilerun.agent.utils.oauth.login_timeout ++> mobilerun.agent.utils.oauth.grok_oauth_llm {
        OAuthLoginDeadline,
        open_browser_async,
    }
    mobilerun.config_manager.auth_profile_store ++> mobilerun.agent.utils.oauth.grok_oauth_llm {
        AuthProfileStore,
    }
    mobilerun.config_manager.credential_paths ++> mobilerun.agent.utils.oauth.grok_oauth_llm {
        GROK_OAUTH_CREDENTIAL_PATH,
    }
    mobilerun.agent.providers.anthropic ++> mobilerun.agent.utils.vision_sizing {
        ANTHROPIC_HIGHRES_MODELS,
    }
    mobilerun.tools.helpers.images ++> mobilerun.agent.utils.vision_sizing {
        MODEL_SCREENSHOT_MAX_SIDE,
        anthropic_resized_size,
        fit_dimensions_to_max_side,
    }
    mobilerun.agent.providers.minimax ++> mobilerun.config_manager.config_manager {
        warn_if_legacy_minimax_endpoint,
    }
    mobilerun.agent.providers.registry ++> mobilerun.config_manager.config_manager {
        GEMINI_API_DEFAULT_MODEL,
        VARIANT_ENV_KEY_SLOT,
    }
    mobilerun.config_manager.env_keys ++> mobilerun.config_manager.config_manager {
        API_KEY_ENV_VARS,
        load_env_key_sources,
    }
    mobilerun.config_manager.path_resolver ++> mobilerun.config_manager.config_manager {
        PathResolver,
    }
    mobilerun.mcp.config ++> mobilerun.config_manager.config_manager { MCPConfig, MCPServerConfig }
    mobilerun.app_cards.app_card_provider ++> mobilerun.app_cards.providers.composite_provider {
        AppCardProvider,
    }
    mobilerun.app_cards.providers.local_provider ++> mobilerun.app_cards.providers.composite_provider {
        LocalAppCardProvider,
    }
    mobilerun.app_cards.providers.server_provider ++> mobilerun.app_cards.providers.composite_provider {
        ServerAppCardProvider,
    }
    mobilerun.agent.providers.registry ++> mobilerun.agent.utils.oauth.gemini_oauth_code_assist_llm {
        GEMINI_OAUTH_DEFAULT_MODEL,
        GEMINI_OAUTH_RETIRED_MODELS,
        gemini_model_omits_sampling_params,
        model_display_name_for_variant,
    }
    mobilerun.agent.utils.oauth.login_timeout ++> mobilerun.agent.utils.oauth.gemini_oauth_code_assist_llm {
        OAuthLoginDeadline,
        open_browser_async,
    }
    mobilerun.config_manager.auth_profile_store ++> mobilerun.agent.utils.oauth.gemini_oauth_code_assist_llm {
        AuthProfileStore,
    }
    mobilerun.config_manager.credential_paths ++> mobilerun.agent.utils.oauth.gemini_oauth_code_assist_llm {
        GEMINI_OAUTH_CREDENTIAL_PATH,
    }
    mobilerun.agent.providers.registry ++> mobilerun.agent.utils.oauth.openai_oauth_llm {
        OPENAI_ASTRA_DEFAULT_REASONING_EFFORT,
        OPENAI_GPT6_MODELS,
        OPENAI_OAUTH_DEFAULT_MODEL,
        OPENAI_OAUTH_UNSUPPORTED_MODELS,
        OPENAI_REASONING_EFFORTS,
        normalize_model_id_for_variant,
    }
    mobilerun.agent.utils.oauth.login_timeout ++> mobilerun.agent.utils.oauth.openai_oauth_llm {
        OAuthLoginDeadline,
        open_browser_async,
    }
    mobilerun.config_manager.auth_profile_store ++> mobilerun.agent.utils.oauth.openai_oauth_llm {
        AuthProfileStore,
    }
    mobilerun.config_manager.credential_paths ++> mobilerun.agent.utils.oauth.openai_oauth_llm {
        OPENAI_OAUTH_CREDENTIAL_PATH,
    }
    include mobilerun.agent.providers.minimax ++> mobilerun.agent.providers {
        MINIMAX_CHINA_BASE_URL,
        MINIMAX_GLOBAL_BASE_URL,
        MINIMAX_LEGACY_BASE_URL,
        warn_if_legacy_minimax_endpoint,
    }
    include mobilerun.agent.providers.registry ++> mobilerun.agent.providers {
        VARIANT_ENV_KEY_SLOT,
        get_provider_family,
        list_auth_modes,
        list_models_for_variant,
        list_provider_families,
        normalize_model_id_for_variant,
        resolve_provider_variant,
    }
    include mobilerun.agent.providers.types ++> mobilerun.agent.providers {
        ProviderFamilySpec,
        ProviderVariantSpec,
    }
    include mobilerun.mcp.adapter ++> mobilerun.mcp { mcp_to_mobilerun_tools }
    include mobilerun.mcp.client ++> mobilerun.mcp { MCPClientManager, MCPToolInfo }
    include mobilerun.mcp.config ++> mobilerun.mcp { MCPConfig, MCPServerConfig }
    mobilerun.config_manager.path_resolver ++> mobilerun.credential_manager.file_credential_manager {
        PathResolver,
    }
    mobilerun.credential_manager.credential_manager ++> mobilerun.credential_manager.file_credential_manager {
        CredentialManager,
        CredentialNotFoundError,
    }
    include mobilerun.app_cards.providers.composite_provider ++> mobilerun.app_cards.providers {
        CompositeAppCardProvider,
    }
    include mobilerun.app_cards.providers.local_provider ++> mobilerun.app_cards.providers {
        LocalAppCardProvider,
    }
    include mobilerun.app_cards.providers.server_provider ++> mobilerun.app_cards.providers {
        ServerAppCardProvider,
    }
    mobilerun.agent.providers ++> mobilerun.agent.providers.setup_service {
        VARIANT_ENV_KEY_SLOT,
        ProviderFamilySpec,
        ProviderVariantSpec,
        list_provider_families,
        resolve_provider_variant,
    }
    mobilerun.agent.providers.registry ++> mobilerun.agent.providers.setup_service {
        normalize_model_id_for_variant,
    }
    mobilerun.config_manager.config_manager ++> mobilerun.agent.providers.setup_service {
        LLMProfile,
        MobileConfig,
    }
    mobilerun.config_manager.env_keys ++> mobilerun.agent.providers.setup_service {
        load_env_keys,
        save_env_keys,
    }
    include mobilerun.credential_manager.credential_manager ++> mobilerun.credential_manager {
        CredentialManager,
        CredentialNotFoundError,
    }
    include mobilerun.credential_manager.file_credential_manager ++> mobilerun.credential_manager {
        FileCredentialManager,
    }
    mobilerun.config_manager.config_manager ++> mobilerun.config_manager.loader { MobileConfig }
    mobilerun.config_manager.migrations ++> mobilerun.config_manager.loader {
        CURRENT_VERSION,
        migrate,
    }
    mobilerun.agent.trajectory.writer ++> mobilerun.agent.utils.trajectory { make_serializable }
    mobilerun.macro.state ++> mobilerun.agent.utils.trajectory {
        MACRO_SCHEMA_VERSION,
        UNSUPPORTED_SCHEMA_MESSAGE,
    }
    mobilerun.agent.providers.anthropic ++> mobilerun.agent.utils.oauth.anthropic_oauth_llm {
        ANTHROPIC_OAUTH_DEFAULT_MODEL,
        anthropic_model_context_window,
        anthropic_model_omits_sampling_params,
        strip_anthropic_sampling_params,
    }
    mobilerun.agent.utils.oauth.login_timeout ++> mobilerun.agent.utils.oauth.anthropic_oauth_llm {
        OAuthLoginDeadline,
        open_browser_async,
    }
    mobilerun.config_manager.auth_profile_store ++> mobilerun.agent.utils.oauth.anthropic_oauth_llm {
        AuthProfileStore,
    }
    mobilerun.config_manager.credential_paths ++> mobilerun.agent.utils.oauth.anthropic_oauth_llm {
        ANTHROPIC_OAUTH_CREDENTIAL_PATH,
    }
    mobilerun.tools.helpers.coordinate ++> mobilerun.tools.ui.provider { NORMALIZED_STATE_NOTE }
    mobilerun.tools.helpers.images ++> mobilerun.tools.ui.provider {
        fit_dimensions_to_max_side,
        resize_image_to_dimensions_with_grid,
        resize_image_to_max_side_with_grid,
    }
    mobilerun.tools.ui.state ++> mobilerun.tools.ui.provider { UIState }
    mobilerun.tools.ui.stealth_state ++> mobilerun.tools.ui.provider { StealthUIState }
    mobilerun.agent.providers.registry ++> mobilerun.agent.utils.llm_google_genai {
        GEMINI_UNSUPPORTED_SAMPLING_PARAMS,
        gemini_model_omits_sampling_params,
    }
    include mobilerun.config_manager.config_manager ++> mobilerun.config_manager {
        AgentConfig,
        AppCardConfig,
        CredentialsConfig,
        DeviceConfig,
        DroidConfig,
        ExecutorConfig,
        FastAgentConfig,
        LLMProfile,
        LoggingConfig,
        ManagerConfig,
        MobileConfig,
        TelemetryConfig,
        ToolsConfig,
        TracingConfig,
    }
    include mobilerun.config_manager.loader ++> mobilerun.config_manager {
        ConfigLoader,
        OutdatedConfigError,
    }
    include mobilerun.config_manager.path_resolver ++> mobilerun.config_manager { PathResolver }
    include mobilerun.config_manager.prompt_loader ++> mobilerun.config_manager { PromptLoader }
    mobilerun.agent.utils.oauth.anthropic_oauth_llm ++> mobilerun.cli.oauth_actions {
        DEFAULT_SETUP_TOKEN_SCOPE,
        AnthropicOAuthLLM,
    }
    mobilerun.agent.utils.oauth.gemini_oauth_code_assist_llm ++> mobilerun.cli.oauth_actions {
        DEFAULT_MODEL as GEMINI_OAUTH_DEFAULT_MODEL,
        GeminiOAuthCodeAssistLLM,
    }
    mobilerun.agent.utils.oauth.grok_oauth_llm ++> mobilerun.cli.oauth_actions {
        DEFAULT_GROK_MODEL,
        GrokOAuth,
    }
    mobilerun.agent.utils.oauth.login_timeout ++> mobilerun.cli.oauth_actions { OAuthLoginDeadline }
    mobilerun.agent.utils.oauth.openai_oauth_llm ++> mobilerun.cli.oauth_actions {
        DEFAULT_OPENAI_OAUTH_CALLBACK_HOST,
        DEFAULT_OPENAI_OAUTH_CALLBACK_PATH,
        DEFAULT_OPENAI_OAUTH_CALLBACK_PORT,
        DEFAULT_OPENAI_OAUTH_CREDENTIAL_PATH,
        OpenAIOAuth,
    }
    mobilerun.config_manager.auth_profile_store ++> mobilerun.cli.oauth_actions { AuthProfileStore }
    mobilerun.agent.action_result ++> mobilerun.agent.tool_registry { ActionResult }
    mobilerun.agent.utils.errors ++> mobilerun.agent.tool_registry { describe_error }
    mobilerun.agent.providers.minimax ++> mobilerun.cli.configure_wizard {
        MINIMAX_CHINA_BASE_URL,
        MINIMAX_GLOBAL_BASE_URL,
    }
    mobilerun.agent.providers.registry ++> mobilerun.cli.configure_wizard {
        VARIANT_ENV_KEY_SLOT,
        model_display_name_for_variant,
        resolve_provider_variant,
    }
    mobilerun.agent.providers.setup_service ++> mobilerun.cli.configure_wizard {
        SetupSelection,
        apply_selection_to_roles,
        auth_mode_choices,
        family_choices,
        variant_models,
    }
    mobilerun.cli.configure_prompts ++> mobilerun.cli.configure_wizard {
        SelectChoice,
        select_prompt,
        text_prompt,
    }
    mobilerun.config_manager ++> mobilerun.cli.configure_wizard { ConfigLoader }
    mobilerun.config_manager.env_keys ++> mobilerun.cli.configure_wizard {
        load_env_key_sources,
        resolve_env_key,
    }
    mobilerun.agent.providers.anthropic ++> mobilerun.agent.utils.llm_anthropic {
        ANTHROPIC_UNSUPPORTED_SAMPLING_PARAMS,
        StreamUsage,
        anthropic_model_context_window,
        anthropic_model_omits_sampling_params,
        collect_stream_usage,
        record_stream_usage,
    }
    mobilerun.tools.helpers.coordinate ++> mobilerun.tools.ui.ios_provider {
        NORMALIZED_STATE_NOTE,
        bounds_to_normalized,
    }
    mobilerun.tools.helpers.images ++> mobilerun.tools.ui.ios_provider {
        fit_dimensions_to_max_side,
        image_dimensions,
    }
    mobilerun.tools.ui.state ++> mobilerun.tools.ui.ios_provider { UIState }
    mobilerun.tools.ui.provider ++> mobilerun.tools.ui.ios_provider { StateProvider }
    mobilerun.tools.helpers.images ++> mobilerun.tools.ui.screenshot_provider {
        fit_dimensions_to_max_side,
        image_dimensions,
    }
    mobilerun.tools.ui.state ++> mobilerun.tools.ui.screenshot_provider { UIState }
    mobilerun.tools.ui.provider ++> mobilerun.tools.ui.screenshot_provider { StateProvider }
    include mobilerun.tools.ui.ios_provider ++> mobilerun.tools.ui { IOSStateProvider }
    include mobilerun.tools.ui.provider ++> mobilerun.tools.ui {
        AndroidStateProvider,
        StateProvider,
    }
    include mobilerun.tools.ui.screenshot_provider ++> mobilerun.tools.ui {
        ScreenshotOnlyStateProvider,
    }
    include mobilerun.tools.ui.state ++> mobilerun.tools.ui { UIState }
    include mobilerun.tools.ui.stealth_state ++> mobilerun.tools.ui { StealthUIState }
    include mobilerun.tools.ui ++> mobilerun.tools { AndroidStateProvider, StateProvider, UIState }
    mobilerun.agent.providers.registry ++> mobilerun.agent.utils.llm_openai_responses {
        OPENAI_ASTRA_DEFAULT_REASONING_EFFORT,
        OPENAI_GPT6_CONTEXT_WINDOW,
        OPENAI_GPT6_MODELS,
        OPENAI_REASONING_EFFORTS,
    }
    mobilerun.agent.providers.grok ++> mobilerun.agent.utils.llm_openai_responses {
        sanitize_grok_responses_kwargs,
    }
    mobilerun.agent.providers.anthropic ++> mobilerun.agent.utils.llm_picker {
        ANTHROPIC_API_DEFAULT_MODEL,
        ANTHROPIC_MODELS_WITHOUT_FORCED_TOOL_CHOICE,
    }
    mobilerun.agent.providers.grok ++> mobilerun.agent.utils.llm_picker {
        GROK_API_DEFAULT_MODEL,
        GROK_CONTEXT_WINDOW,
        XAI_API_BASE,
        normalize_grok_model_id,
        sanitize_grok_responses_kwargs,
    }
    mobilerun.agent.providers.minimax ++> mobilerun.agent.utils.llm_picker {
        MINIMAX_DEFAULT_MODEL,
        MINIMAX_GLOBAL_BASE_URL,
        apply_minimax_defaults,
        is_minimax_base_url,
        warn_if_legacy_minimax_endpoint,
    }
    mobilerun.agent.providers.registry ++> mobilerun.agent.utils.llm_picker {
        GEMINI_API_DEFAULT_MODEL,
        OPENAI_API_DEFAULT_MODEL,
        OPENAI_OAUTH_UNSUPPORTED_MODELS,
        list_models_for_variant,
        normalize_model_id_for_variant,
    }
    mobilerun.agent.usage ++> mobilerun.agent.utils.llm_picker { track_usage }
    mobilerun.agent.utils.llm_picker ++> mobilerun.agent.utils.llm_loader {
        load_llm,
        load_llms_from_profiles,
    }
    mobilerun.config_manager.config_manager ++> mobilerun.agent.utils.llm_loader { MobileConfig }
    mobilerun.agent.utils.inference ++> mobilerun.agent.oneflows.app_starter_workflow {
        acomplete_with_retries,
    }
    mobilerun.agent.action_result ++> mobilerun.agent.utils.actions { ActionResult }
    mobilerun.agent.oneflows.app_starter_workflow ++> mobilerun.agent.utils.actions { AppStarter }
    mobilerun.agent.utils.errors ++> mobilerun.agent.utils.actions { describe_error }
    mobilerun.tools.helpers.coordinate ++> mobilerun.agent.utils.actions {
        NORMALIZED_MAX,
        to_normalized,
    }
    mobilerun.agent.tool_registry ++> mobilerun.agent.utils.signatures { ToolRegistry }
    mobilerun.agent.utils.actions ++> mobilerun.agent.utils.signatures {
        click,
        click_area,
        click_at,
        complete,
        long_press,
        long_press_at,
        open_app,
        open_bundle_id,
        swipe,
        system_button,
        type_secret,
        type_text,
        type_text_direct,
        `wait,
    }
    include mobilerun.agent.utils.chat_utils ++> mobilerun.agent.utils {
        filter_empty_messages,
        has_content,
        limit_history,
        to_chat_messages,
    }
    include mobilerun.agent.utils.prompt_resolver ++> mobilerun.agent.utils { PromptResolver }
    include mobilerun.agent.utils.signatures ++> mobilerun.agent.utils { build_tool_registry }
    include mobilerun.agent.utils.trajectory ++> mobilerun.agent.utils { Trajectory }
    tests.source_text --> tests.test_android_vision_coordinate_contract { module_source }
    tests.source_text --> tests.test_grok_oauth { module_source }
    tests.source_text --> tests.test_visual_remote_connection { module_source }
    mobilerun.agent.utils.trajectory ++> mobilerun.macro.replay { Trajectory }
    mobilerun.macro.handoff ++> mobilerun.macro.replay { run_agent_handoff }
    mobilerun.macro.matcher ++> mobilerun.macro.replay { StateMatchResult, compare_states }
    mobilerun.macro.state ++> mobilerun.macro.replay {
        MACRO_SCHEMA_VERSION,
        UNSUPPORTED_SCHEMA_MESSAGE,
        normalize_ui_state,
    }
    mobilerun.tools.filters ++> mobilerun.macro.replay { DetailedFilter }
    mobilerun.tools.formatters ++> mobilerun.macro.replay { IndexedFormatter }
    mobilerun.tools.ui.provider ++> mobilerun.macro.replay { AndroidStateProvider }
    mobilerun.agent.utils.android_device ++> mobilerun.macro.cli {
        AndroidDeviceSelectionError,
        resolve_android_serial,
    }
    mobilerun.agent.utils.trajectory ++> mobilerun.macro.cli { Trajectory }
    mobilerun.config_manager.path_resolver ++> mobilerun.macro.cli { PathResolver }
    mobilerun.macro.replay ++> mobilerun.macro.cli { MacroPlayer }
    mobilerun.macro.cli ++> mobilerun.macro.__main__ { macro_cli }
    mobilerun.config_manager.config_manager ++> mobilerun.agent.utils.tracing_setup {
        TracingConfig,
    }
    mobilerun.log_handlers ++> mobilerun { CLILogHandler }
    include mobilerun.agent ++> mobilerun { ResultEvent }
    include mobilerun.agent.droid ++> mobilerun { MobileAgent, MobileAgentState }
    mobilerun.agent.utils.errors ++> mobilerun { HtmlErrorPageFilter }
    include mobilerun.agent.utils.llm_picker ++> mobilerun { load_llm }
    include mobilerun.config_manager ++> mobilerun {
        AgentConfig,
        AppCardConfig,
        CredentialsConfig,
        DeviceConfig,
        ExecutorConfig,
        FastAgentConfig,
        LLMProfile,
        LoggingConfig,
        ManagerConfig,
        MobileConfig,
        TelemetryConfig,
        ToolsConfig,
        TracingConfig,
    }
    include mobilerun.macro.replay ++> mobilerun {
        MacroPlayer,
        replay_macro_file,
        replay_macro_folder,
    }
    include mobilerun.tools ++> mobilerun { AndroidDriver, DeviceDriver, RecordingDriver }
    include mobilerun.agent.droid.droid_agent ++> mobilerun.agent.droid { MobileAgent }
    include mobilerun.agent.droid.state ++> mobilerun.agent.droid { MobileAgentState }
    mobilerun.agent.action_context ++> mobilerun.agent.droid.droid_agent { ActionContext }
    mobilerun.agent.common.events ++> mobilerun.agent.droid.droid_agent {
        RecordUIStateEvent,
        ScreenshotEvent,
    }
    mobilerun.agent.droid.events ++> mobilerun.agent.droid.droid_agent {
        ExecutorInputEvent,
        ExecutorResultEvent,
        ExternalUserMessageDroppedEvent,
        FastAgentExecuteEvent,
        FastAgentResultEvent,
        FinalizeEvent,
        ManagerInputEvent,
        ManagerPlanEvent,
        ResultEvent,
    }
    mobilerun.agent.droid.state ++> mobilerun.agent.droid.droid_agent {
        MobileAgentState,
        QueuedUserMessage,
    }
    mobilerun.agent.executor ++> mobilerun.agent.droid.droid_agent { ExecutorAgent }
    mobilerun.agent.external ++> mobilerun.agent.droid.droid_agent { load_agent }
    mobilerun.agent.fast_agent ++> mobilerun.agent.droid.droid_agent { FastAgent }
    mobilerun.agent.fast_agent.events ++> mobilerun.agent.droid.droid_agent { FastAgentOutputEvent }
    mobilerun.agent.manager ++> mobilerun.agent.droid.droid_agent {
        ManagerAgent,
        StatelessManagerAgent,
    }
    mobilerun.agent.manager.prompts ++> mobilerun.agent.droid.droid_agent {
        ManagerResponseValidationError,
    }
    mobilerun.agent.oneflows.structured_output_agent ++> mobilerun.agent.droid.droid_agent {
        StructuredOutputAgent,
    }
    mobilerun.agent.trajectory ++> mobilerun.agent.droid.droid_agent { TrajectoryWriter }
    mobilerun.agent.utils.android_device ++> mobilerun.agent.droid.droid_agent {
        create_android_portal_http_driver,
        is_portal_http_url,
        resolve_android_serial,
    }
    mobilerun.agent.utils.errors ++> mobilerun.agent.droid.droid_agent { describe_error }
    mobilerun.agent.utils.llm_loader ++> mobilerun.agent.droid.droid_agent {
        load_agent_llms,
        merge_llms_with_config,
    }
    mobilerun.agent.utils.portal_setup ++> mobilerun.agent.droid.droid_agent {
        portal_version_kwargs,
    }
    mobilerun.agent.utils.prompt_resolver ++> mobilerun.agent.droid.droid_agent { PromptResolver }
    mobilerun.agent.utils.signatures ++> mobilerun.agent.droid.droid_agent { build_tool_registry }
    mobilerun.agent.utils.tracing_setup ++> mobilerun.agent.droid.droid_agent {
        record_langfuse_screenshot,
        session_context,
        setup_tracing,
    }
    mobilerun.agent.utils.trajectory ++> mobilerun.agent.droid.droid_agent { Trajectory }
    mobilerun.agent.utils.vision_sizing ++> mobilerun.agent.droid.droid_agent {
        VisionResizePolicy,
        model_uses_normalized_coordinates,
    }
    mobilerun.config_manager.config_manager ++> mobilerun.agent.droid.droid_agent {
        DEFAULT_DISABLED_TOOLS,
        AgentConfig,
        CredentialsConfig,
        DeviceConfig,
        LoggingConfig,
        MobileConfig,
        TelemetryConfig,
        ToolsConfig,
        TracingConfig,
    }
    mobilerun.credential_manager ++> mobilerun.agent.droid.droid_agent {
        CredentialManager,
        FileCredentialManager,
    }
    mobilerun.log_handlers ++> mobilerun.agent.droid.droid_agent {
        CLILogHandler,
        configure_logging,
    }
    mobilerun.macro.recorder ++> mobilerun.agent.droid.droid_agent { MacroRecorder }
    mobilerun.mcp.adapter ++> mobilerun.agent.droid.droid_agent { mcp_to_mobilerun_tools }
    mobilerun.mcp.client ++> mobilerun.agent.droid.droid_agent { MCPClientManager }
    mobilerun.mcp.config ++> mobilerun.agent.droid.droid_agent { MCPConfig }
    mobilerun.telemetry ++> mobilerun.agent.droid.droid_agent {
        MobileAgentFinalizeEvent,
        MobileAgentInitEvent,
        capture,
        flush,
    }
    mobilerun.telemetry.phoenix ++> mobilerun.agent.droid.droid_agent { clean_span }
    mobilerun.tools.filters ++> mobilerun.agent.droid.droid_agent { ConciseFilter, DetailedFilter }
    mobilerun.tools.formatters ++> mobilerun.agent.droid.droid_agent { IndexedFormatter }
    mobilerun.tools.ui.ios_provider ++> mobilerun.agent.droid.droid_agent { IOSStateProvider }
    mobilerun.tools.ui.provider ++> mobilerun.agent.droid.droid_agent { AndroidStateProvider }
    mobilerun.tools.ui.screenshot_provider ++> mobilerun.agent.droid.droid_agent {
        ScreenshotOnlyStateProvider,
    }
    include mobilerun.agent.droid.events ++> mobilerun.agent.executor {
        ExecutorInputEvent,
        ExecutorResultEvent,
    }
    include mobilerun.agent.executor.events ++> mobilerun.agent.executor {
        ExecutorActionEvent,
        ExecutorActionResultEvent,
        ExecutorContextEvent,
        ExecutorResponseEvent,
    }
    include mobilerun.agent.executor.executor_agent ++> mobilerun.agent.executor { ExecutorAgent }
    mobilerun.agent.executor.events ++> mobilerun.agent.executor.executor_agent {
        ExecutorActionEvent,
        ExecutorActionResultEvent,
        ExecutorContextEvent,
        ExecutorResponseEvent,
    }
    mobilerun.agent.executor.prompts ++> mobilerun.agent.executor.executor_agent {
        parse_executor_response,
    }
    mobilerun.agent.usage ++> mobilerun.agent.executor.executor_agent { get_usage_from_response }
    mobilerun.agent.utils.errors ++> mobilerun.agent.executor.executor_agent { describe_error }
    mobilerun.agent.utils.inference ++> mobilerun.agent.executor.executor_agent {
        acall_with_retries,
    }
    mobilerun.agent.utils.prompt_resolver ++> mobilerun.agent.executor.executor_agent {
        PromptResolver,
    }
    mobilerun.config_manager.config_manager ++> mobilerun.agent.executor.executor_agent {
        AgentConfig,
    }
    mobilerun.config_manager.prompt_loader ++> mobilerun.agent.executor.executor_agent {
        PromptLoader,
    }
    mobilerun.tools.ui.provider ++> mobilerun.agent.executor.executor_agent {
        resize_model_screenshot_async,
    }
    include mobilerun.agent.fast_agent.fast_agent ++> mobilerun.agent.fast_agent { FastAgent }
    mobilerun.agent.action_result ++> mobilerun.agent.fast_agent.fast_agent { ActionResult }
    mobilerun.agent.common.constants ++> mobilerun.agent.fast_agent.fast_agent { LLM_HISTORY_LIMIT }
    mobilerun.agent.common.events ++> mobilerun.agent.fast_agent.fast_agent {
        RecordUIStateEvent,
        ScreenshotEvent,
    }
    mobilerun.agent.droid.events ++> mobilerun.agent.fast_agent.fast_agent {
        ExternalUserMessageAppliedEvent,
        ExternalUserMessageDroppedEvent,
    }
    mobilerun.agent.fast_agent.events ++> mobilerun.agent.fast_agent.fast_agent {
        FastAgentEndEvent,
        FastAgentInputEvent,
        FastAgentOutputEvent,
        FastAgentResponseEvent,
        FastAgentToolCallEvent,
    }
    mobilerun.agent.fast_agent.native_tools ++> mobilerun.agent.fast_agent.fast_agent {
        native_tool_kwargs,
        parse_native_tool_calls,
        tool_result_messages,
    }
    mobilerun.agent.fast_agent.xml_parser ++> mobilerun.agent.fast_agent.fast_agent {
        ToolCallParseStatus,
        ToolResult,
        extract_add_memory,
        format_tool_calls,
        format_tool_results,
        parse_tool_calls_detailed,
    }
    mobilerun.agent.usage ++> mobilerun.agent.fast_agent.fast_agent { get_usage_from_response }
    mobilerun.agent.utils.chat_utils ++> mobilerun.agent.fast_agent.fast_agent { limit_history }
    mobilerun.agent.utils.inference ++> mobilerun.agent.fast_agent.fast_agent { acall_with_retries }
    mobilerun.agent.utils.prompt_resolver ++> mobilerun.agent.fast_agent.fast_agent {
        PromptResolver,
    }
    mobilerun.agent.utils.tracing_setup ++> mobilerun.agent.fast_agent.fast_agent {
        record_langfuse_screenshot,
    }
    mobilerun.config_manager.config_manager ++> mobilerun.agent.fast_agent.fast_agent {
        AgentConfig,
        TracingConfig,
    }
    mobilerun.config_manager.prompt_loader ++> mobilerun.agent.fast_agent.fast_agent {
        PromptLoader,
    }
    mobilerun.tools.ui.provider ++> mobilerun.agent.fast_agent.fast_agent {
        resize_model_screenshot_async,
    }
    include mobilerun.agent.droid.events ++> mobilerun.agent.manager {
        ManagerInputEvent,
        ManagerPlanEvent,
    }
    include mobilerun.agent.manager.events ++> mobilerun.agent.manager {
        ManagerContextEvent,
        ManagerPlanDetailsEvent,
        ManagerResponseEvent,
    }
    include mobilerun.agent.manager.manager_agent ++> mobilerun.agent.manager { ManagerAgent }
    include mobilerun.agent.manager.prompts ++> mobilerun.agent.manager { parse_manager_response }
    include mobilerun.agent.manager.stateless_manager_agent ++> mobilerun.agent.manager {
        StatelessManagerAgent,
    }
    mobilerun.agent.common.events ++> mobilerun.agent.manager.manager_agent {
        RecordUIStateEvent,
        ScreenshotEvent,
    }
    mobilerun.agent.droid.events ++> mobilerun.agent.manager.manager_agent {
        ExternalUserMessageAppliedEvent,
    }
    mobilerun.agent.manager.events ++> mobilerun.agent.manager.manager_agent {
        ManagerContextEvent,
        ManagerPlanDetailsEvent,
        ManagerResponseEvent,
    }
    mobilerun.agent.manager.prompts ++> mobilerun.agent.manager.manager_agent {
        ManagerResponseValidationError,
        parse_manager_response,
        validate_manager_response,
    }
    mobilerun.agent.usage ++> mobilerun.agent.manager.manager_agent { get_usage_from_response }
    mobilerun.agent.utils.chat_utils ++> mobilerun.agent.manager.manager_agent {
        filter_empty_messages,
    }
    mobilerun.agent.utils.errors ++> mobilerun.agent.manager.manager_agent { describe_error }
    mobilerun.agent.utils.inference ++> mobilerun.agent.manager.manager_agent { acall_with_retries }
    mobilerun.agent.utils.prompt_resolver ++> mobilerun.agent.manager.manager_agent {
        PromptResolver,
    }
    mobilerun.agent.utils.tracing_setup ++> mobilerun.agent.manager.manager_agent {
        record_langfuse_screenshot,
    }
    mobilerun.app_cards.app_card_provider ++> mobilerun.agent.manager.manager_agent {
        AppCardProvider,
        DisabledAppCardProvider,
    }
    mobilerun.app_cards.providers ++> mobilerun.agent.manager.manager_agent {
        CompositeAppCardProvider,
        LocalAppCardProvider,
        ServerAppCardProvider,
    }
    mobilerun.config_manager.prompt_loader ++> mobilerun.agent.manager.manager_agent {
        PromptLoader,
    }
    mobilerun.tools.ui.provider ++> mobilerun.agent.manager.manager_agent {
        resize_model_screenshot_async,
    }
    mobilerun.agent.common.events ++> mobilerun.agent.manager.stateless_manager_agent {
        RecordUIStateEvent,
        ScreenshotEvent,
    }
    mobilerun.agent.manager.events ++> mobilerun.agent.manager.stateless_manager_agent {
        ManagerContextEvent,
        ManagerPlanDetailsEvent,
        ManagerResponseEvent,
    }
    mobilerun.agent.manager.prompts ++> mobilerun.agent.manager.stateless_manager_agent {
        ManagerResponseValidationError,
        parse_manager_response,
        validate_manager_response,
    }
    mobilerun.agent.usage ++> mobilerun.agent.manager.stateless_manager_agent {
        get_usage_from_response,
    }
    mobilerun.agent.utils.chat_utils ++> mobilerun.agent.manager.stateless_manager_agent {
        to_chat_messages,
    }
    mobilerun.agent.utils.errors ++> mobilerun.agent.manager.stateless_manager_agent {
        describe_error,
    }
    mobilerun.agent.utils.inference ++> mobilerun.agent.manager.stateless_manager_agent {
        acall_with_retries,
    }
    mobilerun.agent.utils.prompt_resolver ++> mobilerun.agent.manager.stateless_manager_agent {
        PromptResolver,
    }
    mobilerun.agent.utils.tracing_setup ++> mobilerun.agent.manager.stateless_manager_agent {
        record_langfuse_screenshot,
    }
    mobilerun.config_manager.prompt_loader ++> mobilerun.agent.manager.stateless_manager_agent {
        PromptLoader,
    }
    mobilerun.tools.ui.provider ++> mobilerun.agent.manager.stateless_manager_agent {
        resize_model_screenshot_async,
    }
    mobilerun ++> mobilerun.agent.utils.portal_setup { __version__ }
    mobilerun.agent.utils.android_device ++> mobilerun.cli.device_commands {
        AndroidDeviceSelectionError,
        create_android_portal_http_driver,
        is_portal_http_url,
        resolve_android_serial,
    }
    mobilerun.agent.utils.portal_setup ++> mobilerun.cli.device_commands { portal_version_kwargs }
    mobilerun.config_manager ++> mobilerun.cli.device_commands { ConfigLoader }
    mobilerun.log_handlers ++> mobilerun.cli.device_commands { configure_logging }
    mobilerun.tools.filters ++> mobilerun.cli.device_commands { ConciseFilter }
    mobilerun.tools.formatters ++> mobilerun.cli.device_commands { IndexedFormatter }
    mobilerun.tools.ui.ios_provider ++> mobilerun.cli.device_commands { IOSStateProvider }
    mobilerun.tools.ui.provider ++> mobilerun.cli.device_commands { AndroidStateProvider }
    mobilerun ++> mobilerun.cli.doctor { __version__ as _PACKAGE_VERSION }
    mobilerun ++> mobilerun.telemetry.langfuse_processor { __version__ }
    mobilerun ++> mobilerun.cli.main { MobileAgent, ResultEvent }
    mobilerun.agent.external ++> mobilerun.cli.main { list_agents }
    mobilerun.agent.utils.android_device ++> mobilerun.cli.main {
        AndroidDeviceSelectionError,
        create_android_portal_http_driver,
        is_portal_http_url,
        resolve_android_serial,
    }
    mobilerun.agent.utils.errors ++> mobilerun.cli.main { describe_error }
    mobilerun.agent.utils.llm_picker ++> mobilerun.cli.main { load_llm }
    mobilerun.agent.utils.oauth.openai_oauth_llm ++> mobilerun.cli.main {
        DEFAULT_OPENAI_OAUTH_CALLBACK_HOST,
        DEFAULT_OPENAI_OAUTH_CALLBACK_PATH,
        DEFAULT_OPENAI_OAUTH_CALLBACK_PORT,
        DEFAULT_OPENAI_OAUTH_CREDENTIAL_PATH,
    }
    mobilerun.agent.utils.portal_setup ++> mobilerun.cli.main { portal_version_kwargs }
    mobilerun.cli.configure_wizard ++> mobilerun.cli.main {
        ConfigureWizardCallbacks,
        run_configure_wizard,
    }
    mobilerun.cli.device_commands ++> mobilerun.cli.main {
        CLOUD_API_KEY_ENV,
        DEFAULT_CLOUD_BASE_URL,
        device_cli,
        resolve_cloud_api_key,
    }
    mobilerun.cli.event_handler ++> mobilerun.cli.main { EventHandler }
    mobilerun.cli.oauth_actions ++> mobilerun.cli.main {
        run_anthropic_setup_token_oauth,
        run_gemini_oauth_login,
        run_grok_oauth_login,
        run_openai_oauth_login,
        save_anthropic_setup_token,
    }
    mobilerun.config_manager ++> mobilerun.cli.main { ConfigLoader, MobileConfig }
    mobilerun.config_manager.credential_paths ++> mobilerun.cli.main {
        ANTHROPIC_OAUTH_CREDENTIAL_PATH,
        GEMINI_OAUTH_CREDENTIAL_PATH,
        GROK_OAUTH_CREDENTIAL_PATH,
    }
    mobilerun.log_handlers ++> mobilerun.cli.main { CLILogHandler, configure_logging }
    mobilerun.macro.cli ++> mobilerun.cli.main { macro_cli }
    mobilerun.telemetry ++> mobilerun.cli.main { print_telemetry_message }
    mobilerun.cli.main ++> mobilerun.__main__ { cli }
    include mobilerun.cli.main ++> mobilerun.cli { cli }
    mobilerun.agent.utils.oauth.loopback ++> mobilerun.agent.utils.oauth.anthropic_oauth_llm {
        LoopbackCallback,
    }
    mobilerun.agent.utils.oauth.loopback ++> mobilerun.agent.utils.oauth.gemini_oauth_code_assist_llm {
        LoopbackCallback,
    }
    mobilerun.agent.utils.oauth.loopback ++> mobilerun.agent.utils.oauth.openai_oauth_llm {
        LoopbackCallback,
    }
}

graph spaces {
    space mobilerun: cpython { "."; }
    package mobilerun { ship mobilerun; }
    space mobilerun_dev: cpython { tests.*; }
}
