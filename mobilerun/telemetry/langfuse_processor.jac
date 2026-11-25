import builtins;

import operator;

import base64;

import json;

import logging;

import from contextvars { ContextVar }

import from copy { copy }

import from typing { Any, Optional }

import from opentelemetry { trace }

import from opentelemetry.attributes { BoundedAttributes }

import from opentelemetry.context { Context }

import from opentelemetry.sdk.trace { ReadableSpan, Span, SpanProcessor }

glob _current_agent: ContextVar[Optional["MobileAgent"]] = ContextVar(
    "_current_agent", default=None
);

glob _root_span_context: ContextVar[Optional[Context]] = ContextVar(
    "_root_span_context", default=None
);

glob _last_step_span_context: ContextVar[Optional[Context]] = ContextVar(
    "_last_step_span_context", default=None
);

glob MAX_IMAGE_SIZE_KB: any = 10000;

glob logger: any = logging.getLogger("mobilerun");

def set_current_agent(agent: "MobileAgent") -> None {
    _current_agent.set(agent);
}

def set_root_span_context(span: Span) -> None {
    try {
        _root_span_context.set(trace.set_span_in_context(span));
    } except Exception {}
}

def get_root_span_context -> Optional[Context] {
    return _root_span_context.get();
}

def set_last_step_span_context(span: Span) -> None {
    try {
        _last_step_span_context.set(trace.set_span_in_context(span));
    } except Exception {}
}

def get_last_step_span_context -> Optional[Context] {
    return _last_step_span_context.get();
}

"""Wrap the SDK processor without adding an exporter, queue, or uploader."""
class _LangfuseSpanProcessor(SpanProcessor) {
    def init(processor: SpanProcessor, normalizer: LangfuseSpanProcessor) {
        self.processor = processor;
        self.normalizer = normalizer;
    }

    def on_start(span: Span, parent_context: Optional[Context] = None) -> None {
        self.normalizer.on_start(span, parent_context);
        self.processor.on_start(span, parent_context);
    }

    def _on_ending(span: Span) -> None {
        on_ending: any = getattr(self.processor, "_on_ending", None);
        if on_ending is not None {
            on_ending(span);
        }
    }

    def on_end(span: ReadableSpan) -> None {
        snapshot: any = copy(span);
        snapshot._attributes = BoundedAttributes(
            attributes=`dict(span.attributes or {}),
            immutable=False,
            extended_attributes=getattr(span._attributes, "_extended_attributes", False),
        );
        snapshot._attributes.dropped = span.dropped_attributes;
        self.normalizer.on_end(snapshot);
        snapshot._attributes._immutable = True;
        self.processor.on_end(snapshot);
    }

    def force_flush(timeout_millis: builtins.int = 30000) -> builtins.bool {
        return self.processor.force_flush(timeout_millis);
    }

    def shutdown -> None {
        self.processor.shutdown();
    }
}

"""Let the public Langfuse client register its processor on our provider."""
class _LangfuseTracerProvider {
    has _provider: any,
        _normalizer: any;

    def init(provider, normalizer: LangfuseSpanProcessor) {
        self._provider = provider;
        self._normalizer = normalizer;
    }

    def add_span_processor(processor: SpanProcessor) -> None {
        self._provider.add_span_processor(_LangfuseSpanProcessor(processor, self._normalizer));
    }

    def __getattr__(name) -> any {
        return getattr(self._provider, name);
    }
}

"""Enrich live spans and normalize writable Langfuse export snapshots.

    This processor deliberately does not export, batch, upload, or own threads.
    Use it through _LangfuseTracerProvider so on_end only receives private copies.
    """
class LangfuseSpanProcessor(SpanProcessor) {
    def init(agent: Optional["MobileAgent"] = None) {
        if agent is not None {
            set_current_agent(agent);
        }
    }

    has agent: Optional["MobileAgent"] {
        getter {
            return _current_agent.get();
        }
    }

    def _extract_agent_input -> Optional[builtins.dict] {
        agent: any = self.agent;
        if not agent {
            return None;
        }

        try {
            input_data: builtins.dict[builtins.str, Any] = {};

            if agent.shared_state.instruction {
                input_data["goal"] = agent.shared_state.instruction;
            }

            input_data["reasoning"] = agent.config.agent.reasoning;

            if agent.config.device {
                device: any = agent.config.device;
                input_data["device"] = {
                    "platform": device.platform,
                    "serial": device.serial,
                    "use_tcp": device.use_tcp,
                };
            }

            if agent.output_model {
                input_data["output_model"] = agent.output_model.__name__;
            }

            input_data["droidrun_version"] = "v" + __version__;

            if agent.config.agent.after_sleep_action {
                input_data["after_action_sleep"] = agent.config.agent.after_sleep_action;
            }

            vision_state: any = {
                "manager": getattr(agent.config.agent.manager, "vision", False),
                "executor": getattr(agent.config.agent.executor, "vision", False),
                "fast_agent": getattr(agent.config.agent.fast_agent, "vision", False),
            };
            input_data["vision_enabled"] = `any(vision_state.values());
            input_data["vision"] = vision_state;

            llm_attrs: any = ["manager_llm", "executor_llm"]
                if agent.config.agent.reasoning
                else ["fast_agent_llm"];
            llm_attrs.append("app_opener_llm");
            if agent.output_model {
                llm_attrs.append("structured_output_llm");
            }

            active_llms: any = [];
            for llm_attr in llm_attrs {
                llm: any = getattr(agent, llm_attr, None);
                if llm is None {
                    continue;
                }

                role: any = llm_attr.replace("_llm", "");
                llm_info: any = {
                    "role": role,
                    "provider": llm.class_name() if hasattr(llm, "class_name") else "unknown",
                };
                if role in vision_state {
                    llm_info["vision"] = vision_state[role];
                }

                if hasattr(llm, "model") {
                    llm_info["model"] = llm.model;
                } elif hasattr(llm, "metadata") and hasattr(llm.metadata, "model_name") {
                    llm_info["model"] = llm.metadata.model_name;
                }

                if hasattr(llm, "temperature") {
                    llm_info["temperature"] = llm.temperature;
                }

                active_llms.append(llm_info);
            }

            input_data["llms"] = active_llms;
            return input_data;
        } except Exception as error {
            logger.warning("Failed to extract Langfuse agent metadata (%s)", `type(error).__name__);
            return None;
        }
    }

    def on_start(span: Span, parent_context: Optional[Context] = None) -> None {
        del parent_context;

        attrs: any = getattr(span, "_attributes", None);
        if attrs is None or not self.agent {
            return;
        }

        try {
            attrs.pop("input.value", None);

            if span.name == "MobileAgent.run" {
                set_root_span_context(span);
                attrs["langfuse.release"] = "v" + __version__;
                input_data: any = self._extract_agent_input();
                if input_data {
                    attrs["langfuse.observation.input"] = json.dumps(input_data);
                    attrs["langfuse.trace.tags"] = ["reasoning"]
                        if input_data.get("reasoning")
                        else ["fast"];
                    attrs["droidrun.vision.enabled"] = input_data["vision_enabled"];
                }
            } elif span.name
                in (
                    "ManagerAgent.run",
                    "StatelessManagerAgent.run",
                    "FastAgent.run",
                    "ExecutorAgent.run",
                )
            {
                set_last_step_span_context(span);
                agent: any = self.agent;
                memory: any = agent.shared_state.agent_memory;
                input_data = {
                    "memory_size": len(memory) if memory else 0,
                    "message_history_count": len(agent.shared_state.message_history) + 1,
                };

                if span.name == "ExecutorAgent.run" {
                    input_data["subgoal"] = agent.shared_state.current_subgoal or "Unknown";
                }

                attrs["langfuse.observation.input"] = json.dumps(input_data);
                if agent.shared_state.error_flag_plan {
                    attrs["langfuse.trace.tags"] = ["error_recovery"];
                }
            }
        } except Exception as error {
            logger.warning("Failed to add Langfuse span metadata (%s)", `type(error).__name__);
        }
    }

    def on_end(span: ReadableSpan) -> None {
        attrs: any = getattr(span, "_attributes", None);
        if attrs is None {
            return;
        }

        try {
            if span.name.endswith("_done") {
                attrs["langfuse.observation.level"] = "DEBUG";
            }

            if span.name
                in (
                    "MobileAgent.run",
                    "ManagerAgent.run",
                    "StatelessManagerAgent.run",
                    "ExecutorAgent.run",
                    "FastAgent.run",
                )
            {
                attrs.pop("input.value", None);
            } elif span.name.endswith((".chat", ".achat", ".stream_chat", ".astream_chat")) {
                self._format_chat(span);
            } elif span.name.endswith((
                ".complete",
                ".acomplete",
                ".stream_complete",
                ".astream_complete",
            )) {
                self._format_complete(span);
            } elif span.name == "droidrun.screenshot" {
                self._process_screenshot_span(span);
            }

            output: any = attrs.pop("output.value", None);
            if output is not None and not attrs.get("langfuse.observation.output") {
                attrs["langfuse.observation.output"] = output;
            }
        } except Exception as error {
            logger.warning("Failed to preprocess a span for Langfuse (%s)", `type(error).__name__);
        }
    }

    def shutdown -> None {}

    def force_flush(timeout_millis: builtins.int = 30000) -> builtins.bool {
        del timeout_millis;
        return True;
    }

    def _format_complete(span: ReadableSpan) -> None {
        attrs: any = getattr(span, "_attributes", None);
        if attrs is None {
            return;
        }

        prompts: any = attrs.pop("llm.prompts", None);
        if isinstance(prompts, (`list, `tuple)) and prompts {
            attrs["input.value"] = prompts[0];
        }
        self._process_field(attrs, "input");
        self._process_field(attrs, "output");
    }

    def _format_chat(span: ReadableSpan) -> None {
        attrs: any = getattr(span, "_attributes", None);
        if attrs is None {
            return;
        }

        self._process_field(attrs, "input");
        self._process_field(attrs, "output");
    }

    def _process_field(attrs: builtins.dict, field: builtins.str) -> None {
        field_key: any = f"{field}.value";
        value: any = attrs.get(field_key);
        if not isinstance(value, `str) {
            return;
        }

        try {
            data: any = json.loads(value);
            if self._has_blocks_to_transform(data) {
                self._transform_and_set_field(attrs, field, data);
                return;
            }
            (sanitized, contains_data_uri) = self._sanitize_serialized_data_uris(data) as any;
            if contains_data_uri {
                attrs[f"langfuse.observation.{field}"] = json.dumps(sanitized);
                attrs.pop(field_key, None);
                return;
            }
        } except (json.JSONDecodeError, ValueError) {}

        attrs[f"langfuse.observation.{field}"] = value;
        attrs.pop(field_key, None);
    }

    static def _has_blocks_to_transform(data: builtins.object) -> builtins.bool {
        if not isinstance(data, `dict) or not isinstance(data.get("messages"), `list) {
            return False;
        }

        return `any(
            isinstance(message, `dict)
                and (
                    "blocks" in message
                    or isinstance(message.get("json"), `dict) and "blocks" in message["json"]
                )
            for message in data["messages"],
        );
    }

    def _transform_and_set_field(
        attrs: builtins.dict, field: builtins.str, data: builtins.dict
    ) -> None {
        prefix: any = f"llm.{field}_messages.";
        for key in [key for key in attrs if key.startswith(prefix)] {
            del attrs[key];
        }

        formatted: any = self._transform_blocks_to_content(data);
        attrs[f"langfuse.observation.{field}"] = formatted;
        attrs.pop(f"{field}.value", None);
    }

    def _transform_blocks_to_content(data: builtins.dict) -> builtins.str {
        processed: any = self._convert_message_array(data["messages"]);
        return json.dumps({"messages": processed});
    }

    def _convert_message_array(messages: builtins.list) -> builtins.list {
        restructured_messages: any = [];

        for original_message in messages {
            if not isinstance(original_message, `dict) {
                continue;
            }

            message: any = original_message;
            if "content" in message and "blocks" not in message {
                restructured_messages.append(message);
                continue;
            }

            if isinstance(message.get("json"), `dict) and "blocks" in message["json"] {
                message = message.copy();
                message.update(message.pop("json"));
            }

            if "blocks" not in message or "role" not in message {
                if "role" in message {
                    restructured_messages.append(message);
                }
                continue;
            }

            blocks: any = message["blocks"];
            if not isinstance(blocks, `list) or not blocks {
                restructured_messages.append(message);
                continue;
            }

            role: any = message["role"];
            if len(blocks) == 1
                and isinstance(blocks[0], `dict)
                and blocks[0].get("block_type") == "text"
                and "text" in blocks[0]
            {
                restructured_messages.append({"role": role, "content": blocks[0]["text"]});
                continue;
            }

            content_blocks: any = self._convert_blocks_to_content(blocks);
            if content_blocks {
                restructured_messages.append({"role": role, "content": content_blocks});
            } elif `any(
                isinstance(block, `dict) and operator.eq(block.get("block_type"), "image")
                for block in blocks,
            ) {
                restructured_messages.append({"role": role, "content": []});
            } else {
                restructured_messages.append(message);
            }
        }

        return restructured_messages;
    }

    def _convert_blocks_to_content(blocks: builtins.list) -> builtins.list {
        content_blocks: any = [];

        for block in blocks {
            if not isinstance(block, `dict) {
                continue;
            }

            block_type: any = block.get("block_type");
            if block_type == "text" and "text" in block {
                content_blocks.append({"type": "text", "text": block["text"]});
            } elif block_type == "image" {
                image_block: any = self._prepare_image_for_native_upload(block);
                if image_block {
                    content_blocks.append(image_block);
                }
            } elif block_type == "tool_call" and "tool_name" in block and "tool_kwargs" in block {
                content_blocks.append({
                    "type": "tool_call",
                    "tool_call": {"name": block["tool_name"], "arguments": block["tool_kwargs"]},
                });
            }
        }

        return content_blocks;
    }

    class def _sanitize_serialized_data_uris(value: Any) -> builtins.tuple[Any, builtins.bool] {
        if isinstance(value, `str) {
            (header, separator, _payload) = value.partition(",") as any;
            is_base64_data_uri: any = value.startswith("data:")
                and `bool(separator)
                and header.endswith(";base64");
            if not is_base64_data_uri {
                return (value, False);
            }

            prepared: any = cls._prepare_image_for_native_upload({
                "image": value,
                "image_mimetype": "application/octet-stream",
            });
            return (value if prepared else "", True);
        }

        if isinstance(value, `list) {
            sanitized_items: any = [];
            contains_data_uri: any = False;
            for item in value {
                (sanitized, found) = cls._sanitize_serialized_data_uris(item) as any;
                sanitized_items.append(sanitized);
                contains_data_uri = contains_data_uri or found;
            }
            return (sanitized_items, contains_data_uri);
        }

        if isinstance(value, `dict) {
            sanitized_mapping: any = {};
            contains_data_uri = False;
            for (key, item) in value.items() {
                (sanitized, found) = cls._sanitize_serialized_data_uris(item) as any;
                sanitized_mapping[key] = sanitized;
                contains_data_uri = contains_data_uri or found;
            }
            return (sanitized_mapping, contains_data_uri);
        }

        return (value, False);
    }

    def _process_screenshot_span(span: ReadableSpan) -> None {
        attrs: any = getattr(span, "_attributes", None);
        if attrs is None {
            return;
        }

        image: any = attrs.get("droidrun.screenshot.image_base64");
        mime_type: any = attrs.get("droidrun.screenshot.mime_type", "image/png");
        if not image {
            return;
        }

        image_content: any = self._prepare_image_for_native_upload({
            "image": image,
            "image_mimetype": mime_type,
        });
        if image_content {
            attrs["langfuse.observation.output"] = json.dumps({
                "messages": [{"role": "assistant", "content": [image_content]}],
            });
        }

        attrs.pop("droidrun.screenshot.image_base64", None);
        attrs.pop("droidrun.screenshot.mime_type", None);
        attrs.pop("output.value", None);
    }

    static def _prepare_image_for_native_upload(block: builtins.dict) -> Optional[builtins.dict] {
        image: any = block.get("image");
        if image is not None {
            mime_type: any = block.get("image_mimetype");
            if not isinstance(image, `str) {
                logger.warning("Image data is invalid; skipping upload");
                return None;
            }

            encoded: any = image;
            if image.startswith("data:") and "," in image {
                (header, encoded) = image.split(",", 1) as any;
                if header.endswith(";base64") {
                    mime_type = header[5:-7];
                } else {
                    logger.warning("Image data URI is not base64 encoded; skipping upload");
                    return None;
                }
            } elif not isinstance(mime_type, `str) {
                logger.warning("Image MIME type is invalid; skipping upload");
                return None;
            }

            try {
                image_bytes: any = base64.b64decode(encoded, validate=True);
            } except (ValueError, TypeError) {
                logger.warning("Image data is not valid base64; skipping upload");
                return None;
            }

            size_kb: any = len(image_bytes) / 1024;
            if size_kb > MAX_IMAGE_SIZE_KB {
                logger.warning(
                    "Image size (%.1fKB) exceeds limit (%dKB); skipping upload",
                    size_kb,
                    MAX_IMAGE_SIZE_KB,
                );
                return None;
            }

            data_uri: any = f"data:{mime_type};base64,{encoded}";
            return {"type": "image_url", "image_url": {"url": data_uri}};
        }

        url: any = block.get("url");
        if isinstance(url, `str) {
            if url.startswith("data:") {
                return LangfuseSpanProcessor._prepare_image_for_native_upload({
                    "image": url,
                    "image_mimetype": "application/octet-stream",
                });
            }
            return {"type": "image_url", "image_url": {"url": url}};
        }

        path: any = block.get("path");
        if isinstance(path, `str) {
            logger.warning("Using a local image path; it may not resolve in Langfuse");
            return {"type": "image_url", "image_url": {"url": f"file://{path}"}};
        }

        return None;
    }
}
