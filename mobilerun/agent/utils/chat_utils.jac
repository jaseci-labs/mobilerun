import builtins;

import logging;

import from io { BytesIO }

import from pathlib { Path }

import from typing { Union }

import from llama_index.core.base.llms.types { ChatMessage, ImageBlock, TextBlock }

import from PIL { Image }

glob logger: any;

with entry {
    logger = logging.getLogger("mobilerun");
}

"""Convert image to bytes."""
def _ensure_image_bytes(
    image_source: Union[builtins.str, Path, Image.Image, builtins.bytes]
) -> builtins.bytes;

"""
    Convert dict messages to ChatMessage list.

    Args:
        messages: List of message dicts

    Returns:
        List of ChatMessage objects
    """
def to_chat_messages(messages: builtins.list[builtins.dict]) -> builtins.list[ChatMessage];

def has_content(message: ChatMessage) -> builtins.bool;

def filter_empty_messages(messages: builtins.list[ChatMessage]) -> builtins.list[ChatMessage];

def limit_history(
    messages: builtins.list[ChatMessage],
    max_messages: builtins.int,
    preserve_first: builtins.bool = True,
) -> builtins.list[ChatMessage];

"""Drop leading tool results whose tool call was trimmed away."""
def _drop_orphaned_tool_results(messages: builtins.list[ChatMessage]) -> builtins.list[ChatMessage];
