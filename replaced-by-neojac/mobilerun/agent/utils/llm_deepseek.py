"""MobilerunDeepSeek, kept apart so its provider package loads only when used."""

from typing import ClassVar
from llama_index.llms.openai_like import OpenAILike


class MobilerunDeepSeek(OpenAILike):
    supports_native_tool_calls: ClassVar[bool] = True
    native_tool_api: ClassVar[str] = "chat_completions"
