import builtins;

import operator;

import json;

import logging;

import re;

import xml.etree.ElementTree as ET;

import from dataclasses { dataclass, field }

import from enum { Enum }

import from html { escape }

import from typing { Any, Dict, List, Optional, Tuple }

glob logger: any;

glob OPEN_TAG: any;

glob CLOSE_TAG: any;

glob _PARAM_RE: any;

glob _PARAM_OPEN_RE: any;

glob _DSML_MARKUP_PATTERN: any;

glob _DSML_MARKUP_RE: any;

glob _TOOL_CALL_MARKUP_RE: any;

glob _CANONICAL_BLOCK_TAGS: any;

glob _PROSE_PUNCTUATION: any;

glob _BLOCK_CONTENT_RE: any;

glob _ADD_MEMORY_RE: any;

with entry {
    logger = logging.getLogger("mobilerun");

    OPEN_TAG = "<function_calls>";
    CLOSE_TAG = "</function_calls>";

    _PARAM_RE = re.compile(
        "(<parameter\\s+name=(?:\"[^\"]*\"|'[^']*')\\s*>)(.*?)(</parameter>)", re.DOTALL
    );
    _PARAM_OPEN_RE = re.compile("<parameter(?=[\\s>/])");

    _DSML_MARKUP_PATTERN = "(?:<|＜)\\s*[/／]?\\s*｜+DSML｜+";
    _DSML_MARKUP_RE = re.compile(_DSML_MARKUP_PATTERN, re.IGNORECASE);
    _TOOL_CALL_MARKUP_RE = re.compile(
        "(?:<|＜)\\s*[/／]?\\s*(?:function_calls?|tool_calls?|invoke|parameter)\\b|"
            + _DSML_MARKUP_PATTERN,
        re.IGNORECASE,
    );
    _CANONICAL_BLOCK_TAGS = ("<invoke", "</invoke", "<parameter", "</parameter");
    _PROSE_PUNCTUATION = "`.,;:!?)";
    _BLOCK_CONTENT_RE = re.compile(
        "(?:<|＜)\\s*[/／]?\\s*(?:function_call|tool_calls?|invoke|parameter)\\b|"
            + _DSML_MARKUP_PATTERN,
        re.IGNORECASE,
    );
}

"""A parsed tool invocation from the LLM response."""
@dataclass
class ToolCall {
    has name: builtins.str;

    has parameters: Dict[builtins.str, Any] = field(default_factory=dict[any, any]);

    has error: Optional[builtins.str] = None;

    has call_id: Optional[builtins.str] = None;
}

"""Classification of tool-call markup in an LLM response."""
class ToolCallParseStatus(builtins.str, Enum) {
    static has VALID: any = "valid";

    static has NO_MARKUP: any = "no_markup";

    static has MALFORMED: any = "malformed";
}

"""Detailed result used internally to distinguish missing and invalid markup.

    ``end`` is the text offset where the first tool-call block ends;
    ``ignored_blocks`` counts later blocks that contain tool-call markup.
    """
@dataclass(frozen=True)
class ToolCallParseResult {
    has thought: builtins.str;

    has calls: List[ToolCall];

    has status: ToolCallParseStatus;

    has end: Optional[builtins.int] = None;

    has ignored_blocks: builtins.int = 0;
}

"""Result from executing a single tool."""
@dataclass
class ToolResult {
    has name: builtins.str;

    has output: builtins.str;

    has is_error: builtins.bool = False;
}

def parse_tool_calls(
    text: builtins.str, param_types: Optional[Dict[builtins.str, builtins.str]] = None
) -> Tuple[builtins.str, List[ToolCall]];

def parse_tool_calls_detailed(
    text: builtins.str, param_types: Optional[Dict[builtins.str, builtins.str]] = None
) -> ToolCallParseResult;

def _count_tool_call_blocks(text: builtins.str, end: builtins.int) -> builtins.int;

def _is_prose_mention(before: builtins.str, after: builtins.str) -> builtins.bool;

def format_tool_results(results: List[ToolResult]) -> builtins.str;

def format_tool_calls(calls: List[ToolCall]) -> builtins.str;

with entry {
    _ADD_MEMORY_RE = re.compile("<add_memory(?:\\s+[^>]*)?>(.+?)</add_memory>", re.DOTALL);
}

def extract_add_memory(text: builtins.str) -> builtins.str;

def _parse_tool_call_block(
    block: builtins.str, param_types: Optional[Dict[builtins.str, builtins.str]]
) -> List[ToolCall];

def _has_text_outside_parameters(`root: ET.Element) -> builtins.bool;

def _has_noncanonical_markup(block: builtins.str) -> builtins.bool;

def _format_param_value(value: Any) -> builtins.str;

def _sanitize_param_content(block: builtins.str) -> builtins.str;

def _coerce_param(
    name: builtins.str,
    value: builtins.str,
    param_types: Optional[Dict[builtins.str, builtins.str]] = None,
) -> Any;
