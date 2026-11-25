impl _ensure_image_bytes(
    image_source: Union[builtins.str, Path, Image.Image, builtins.bytes]
) -> builtins.bytes {
    if isinstance(image_source, `bytes) {
        return image_source;
    }
    if isinstance(image_source, (`str, Path)) {
        image: any = Image.open(image_source);
    } elif isinstance(image_source, Image.Image) {
        image = image_source;
    } else {
        raise ValueError(f"Unsupported image type: {`type(image_source)}");
    }
    if image.mode == "I" {
        image = image.convert("I;16");
    }

    buffer: any = BytesIO();
    image.save(buffer, format="PNG");
    return buffer.getvalue();
}

impl to_chat_messages(messages: builtins.list[builtins.dict]) -> builtins.list[ChatMessage] {
    chat_messages: any = [];

    for msg in messages {
        blocks: any = [];
        for item in msg.get("content", []) {
            if "text" in item {
                blocks.append(TextBlock(text=item["text"]));
            } elif "image" in item {
                image_bytes: any = _ensure_image_bytes(item["image"]);
                blocks.append(ImageBlock(image=image_bytes));
            }
        }

        chat_messages.append(ChatMessage(role=msg["role"], blocks=blocks));
    }

    return chat_messages;
}

impl has_content(message: ChatMessage) -> builtins.bool {
    for block in message.blocks {
        if isinstance(block, TextBlock) and block.text and block.text.strip() {
            return True;
        }
        if isinstance(block, ImageBlock) and block.image {
            return True;
        }
    }
    return False;
}

impl filter_empty_messages(messages: builtins.list[ChatMessage]) -> builtins.list[ChatMessage] {
    return [msg for msg in messages if has_content(msg)];
}

impl limit_history(
    messages: builtins.list[ChatMessage],
    max_messages: builtins.int,
    preserve_first: builtins.bool = True,
) -> builtins.list[ChatMessage] {
    if len(messages) <= max_messages {
        return messages;
    }

    if preserve_first and messages {
        first: any = messages[0];
        tail: any = _drop_orphaned_tool_results(messages[-max_messages + 1:]);
        if first not in tail {
            return [first] + tail;
        }
        return tail;
    }

    return _drop_orphaned_tool_results(messages[-max_messages:]);
}

impl _drop_orphaned_tool_results(
    messages: builtins.list[ChatMessage]
) -> builtins.list[ChatMessage] {
    start: any = 0;
    while start < len(messages) and messages[start].role == "tool" {
        start += 1;
    }
    return messages[start:];
}
