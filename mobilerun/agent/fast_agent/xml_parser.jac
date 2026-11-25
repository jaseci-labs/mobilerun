"""XML tool-call parsing and result formatting.

Parses LLM responses containing <function_calls> blocks into structured
ToolCall objects, and formats tool results as <function_results> XML
for injection back into the conversation.
"""

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

"""Parse tool calls from LLM response text.

    Args:
        text: Raw LLM response text.
        param_types: Optional {param_name: type_string} map for coercion.
                     If None, all values are kept as strings.

    Returns:
        Tuple of (text_before_tool_calls, list_of_tool_calls).
        If no tool calls found, returns (full_text, []).
    """
def parse_tool_calls(
    text: builtins.str, param_types: Optional[Dict[builtins.str, builtins.str]] = None
) -> Tuple[builtins.str, List[ToolCall]];

"""Parse tool calls and classify whether markup was absent, valid, or malformed.

    Only the first tool-call block is parsed: the first <function_calls>
    always starts it. If it is malformed (including any tool-call markup
    before that opener), the result is malformed even when a later block is
    valid.
    """
def parse_tool_calls_detailed(
    text: builtins.str, param_types: Optional[Dict[builtins.str, builtins.str]] = None
) -> ToolCallParseResult;

"""Count blocks after offset ``end``; prose mentioning the tag is not a block."""
def _count_tool_call_blocks(text: builtins.str, end: builtins.int) -> builtins.int;

"""Whether an unclosed opener sits mid-sentence before a word or punctuation.

    An opener closed before the next one, or followed by anything else (a
    tag, JSON, brackets, quotes), is a block.
    """
def _is_prose_mention(before: builtins.str, after: builtins.str) -> builtins.bool;

"""Format tool results as XML for injection into conversation.

    Args:
        results: List of tool results to format.

    Returns:
        XML string with <function_results> wrapper.
    """
def format_tool_results(results: List[ToolResult]) -> builtins.str;

"""Format parsed tool calls as XML for logging/trajectory output."""
def format_tool_calls(calls: List[ToolCall]) -> builtins.str;

with entry {
    _ADD_MEMORY_RE = re.compile("<add_memory(?:\\s+[^>]*)?>(.+?)</add_memory>", re.DOTALL);
}

"""Extract and combine content from all ``<add_memory>`` tags in LLM response text."""
def extract_add_memory(text: builtins.str) -> builtins.str;

def _parse_tool_call_block(
    block: builtins.str, param_types: Optional[Dict[builtins.str, builtins.str]]
) -> List[ToolCall];

"""Return whether the block has text anywhere except inside parameter values."""
def _has_text_outside_parameters(`root: ET.Element) -> builtins.bool;

"""Return whether tool-call markup other than plain <invoke>/<parameter>
    tags (DSML, full-width or alternate tags) occurs outside a trustworthy
    parameter payload."""
def _has_noncanonical_markup(block: builtins.str) -> builtins.bool;

def _format_param_value(value: Any) -> builtins.str;

"""Escape XML-unsafe characters inside parameter values.

    Parameter values often contain raw code or text with <, >, &
    which would break XML parsing. This escapes content inside
    <parameter> tags only, leaving the XML structure intact.
    """
def _sanitize_param_content(block: builtins.str) -> builtins.str;

"""Coerce string parameter value to expected type.

    Args:
        name: Parameter name.
        value: Raw string value from XML.
        param_types: Optional type map. If None, returns value as-is.
    """
def _coerce_param(
    name: builtins.str,
    value: builtins.str,
    param_types: Optional[Dict[builtins.str, builtins.str]] = None,
) -> Any;
