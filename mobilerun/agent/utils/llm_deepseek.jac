import builtins;

import from typing { ClassVar }

import from llama_index.llms.openai_like { OpenAILike }

class MobilerunDeepSeek(OpenAILike) {
    has supports_native_tool_calls: ClassVar[builtins.bool] = True;

    has native_tool_api: ClassVar[builtins.str] = "chat_completions";
}
