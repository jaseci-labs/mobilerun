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

glob logger: any = logging.getLogger("mobilerun");

glob OPEN_TAG: any = "<function_calls>";

glob CLOSE_TAG: any = "</function_calls>";

glob _PARAM_RE: any = re.compile(
    "(<parameter\\s+name=(?:\"[^\"]*\"|'[^']*')\\s*>)(.*?)(</parameter>)", re.DOTALL
);

glob _PARAM_OPEN_RE: any = re.compile("<parameter(?=[\\s>/])");

glob _DSML_MARKUP_PATTERN: any = "(?:<|＜)\\s*[/／]?\\s*｜+DSML｜+";

glob _DSML_MARKUP_RE: any = re.compile(_DSML_MARKUP_PATTERN, re.IGNORECASE);

glob _TOOL_CALL_MARKUP_RE: any = re.compile(
    "(?:<|＜)\\s*[/／]?\\s*(?:function_calls?|tool_calls?|invoke|parameter)\\b|"
        + _DSML_MARKUP_PATTERN,
    re.IGNORECASE,
);

glob _CANONICAL_BLOCK_TAGS: any = ("<invoke", "</invoke", "<parameter", "</parameter");

glob _PROSE_PUNCTUATION: any = "`.,;:!?)";

glob _BLOCK_CONTENT_RE: any = re.compile(
    "(?:<|＜)\\s*[/／]?\\s*(?:function_call|tool_calls?|invoke|parameter)\\b|" + _DSML_MARKUP_PATTERN,
    re.IGNORECASE,
);

glob _ADD_MEMORY_RE: any;

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
) -> Tuple[builtins.str, List[ToolCall]] {
    if OPEN_TAG not in text {
        return (text.strip(), []);
    }

    result: any = parse_tool_calls_detailed(text, param_types);
    return (result.thought, result.calls);
}

def parse_tool_calls_detailed(
    text: builtins.str, param_types: Optional[Dict[builtins.str, builtins.str]] = None
) -> ToolCallParseResult {
    if OPEN_TAG not in text {
        markup_match: any = _TOOL_CALL_MARKUP_RE.search(text);
        if markup_match {
            return ToolCallParseResult(
                thought=text[:markup_match.start()].strip(),
                calls=[],
                status=ToolCallParseStatus.MALFORMED,
            );
        }
        return ToolCallParseResult(
            thought=text.strip(), calls=[], status=ToolCallParseStatus.NO_MARKUP
        );
    }

    parts: any = text.split(OPEN_TAG);
    leading: any = _TOOL_CALL_MARKUP_RE.search(parts[0]);
    if leading {
        end: any = len(parts[0]);
        return ToolCallParseResult(
            thought=parts[0][:leading.start()].strip(),
            calls=[],
            status=ToolCallParseStatus.MALFORMED,
            end=end,
            ignored_blocks=_count_tool_call_blocks(text, end),
        );
    }

    text_before: any = parts[0].strip();
    part: any = parts[1];
    part_start: any = len(parts[0]) + len(OPEN_TAG);

    close_idx: any = part.find(CLOSE_TAG);
    if close_idx == -1 {
        end = part_start + len(part) if len(parts) > 2 else None;
        return ToolCallParseResult(
            thought=text_before,
            calls=[],
            status=ToolCallParseStatus.MALFORMED,
            end=end,
            ignored_blocks=_count_tool_call_blocks(text, end) if end is not None else 0,
        );
    }

    block: any = part[:close_idx].strip();
    calls: List[ToolCall] = [];
    if block and not _has_noncanonical_markup(block) {
        calls = _parse_tool_call_block(block, param_types);
    }

    end = part_start + close_idx + len(CLOSE_TAG);
    return ToolCallParseResult(
        thought=text_before,
        calls=calls,
        status=ToolCallParseStatus.VALID if calls else ToolCallParseStatus.MALFORMED,
        end=end,
        ignored_blocks=_count_tool_call_blocks(text, end),
    );
}

def _count_tool_call_blocks(text: builtins.str, end: builtins.int) -> builtins.int {
    parts = text[end:].split(OPEN_TAG);
    count: any = 1 if _BLOCK_CONTENT_RE.search(parts[0]) else 0;
    parts[0] = text[:end] + parts[0];
    return count
        + sum(1 for i in range(1, len(parts)) if not _is_prose_mention(parts[i - 1], parts[i]));
}

def _is_prose_mention(before: builtins.str, after: builtins.str) -> builtins.bool {
    if CLOSE_TAG in after {
        return False;
    }
    line_before: any = before[before.rfind("\n") + 1:].strip();
    line_after: any = after.split("\n", 1)[0].strip();
    return `bool(line_before and line_after)
        and (line_after[0].isalpha() or line_after[0] in _PROSE_PUNCTUATION);
}

def format_tool_results(results: List[ToolResult]) -> builtins.str {
    lines: any = ["<function_results>"];

    for result in results {
        if result.is_error {
            lines.append(
                f"<result>\n<name>{result.name}</name>\n<error>{result.output}</error>\n</result>"
            );
        } else {
            lines.append(
                f"<result>\n<name>{result.name}</name>\n<output>{result.output}</output>\n</result>"
            );
        }
    }

    lines.append("</function_results>");
    return "\n".join(lines);
}

def format_tool_calls(calls: List[ToolCall]) -> builtins.str {
    lines: any = [OPEN_TAG];
    for call in calls {
        lines.append(f"<invoke name=\"{call.name}\">");
        for (name, value) in call.parameters.items() {
            lines.append(f"<parameter name=\"{name}\">{_format_param_value(value)}</parameter>");
        }
        lines.append("</invoke>");
    }
    lines.append(CLOSE_TAG);
    return "\n".join(lines);
}

with entry {
    _ADD_MEMORY_RE = re.compile("<add_memory(?:\\s+[^>]*)?>(.+?)</add_memory>", re.DOTALL);
}

def extract_add_memory(text: builtins.str) -> builtins.str {
    matches: any = _ADD_MEMORY_RE.findall(text);
    if not matches {
        return "";
    }
    return "\n".join(m.strip() for m in matches if m.strip());
}

def _parse_tool_call_block(
    block: builtins.str, param_types: Optional[Dict[builtins.str, builtins.str]]
) -> List[ToolCall] {
    block = _sanitize_param_content(block);
    if "<!" in block or "<?" in block {
        logger.warning("Comment or declaration in tool call XML block, skipping block");
        return [];
    }

    try {
        `root: any = ET.fromstring(f"<root>{block}</root>");
    } except (ET.ParseError, UnicodeError) {
        logger.warning("Failed to parse tool call XML block, skipping");
        return [];
    }

    if _has_text_outside_parameters(`root) {
        logger.warning("Text outside tool calls in XML block, skipping block");
        return [];
    }

    for child in `root {
        if child.tag != "invoke" {
            logger.warning(
                "Unexpected <%s> element in tool call XML block, skipping block", child.tag
            );
            return [];
        }
    }

    calls: List[ToolCall] = [];
    for invoke in `root.findall("invoke") {
        name: any = invoke.get("name", "");
        if not name {
            logger.warning("Tool call without a name in XML block, skipping block");
            return [];
        }

        params: Dict[builtins.str, Any] = {};
        error: Optional[builtins.str] = None;
        for param in invoke {
            param_name: any = param.get("name", "");
            if param.tag != "parameter" or not param_name or len(param) {
                logger.warning("Invalid tool call parameter in XML block, skipping block");
                return [];
            }
            try {
                params[param_name] = _coerce_param(param_name, param.text or "", param_types);
            } except ValueError as e {
                error = `str(e);
                break;
            }
        }

        calls.append(ToolCall(name=name, parameters=params, error=error));
    }
    return calls;
}

def _has_text_outside_parameters(`root: ET.Element) -> builtins.bool {
    texts: any = [`root.text];
    for invoke in `root {
        texts += [invoke.tail, invoke.text];
        texts += [param.tail for param in invoke];
    }
    return `any(text and text.strip() for text in texts);
}

def _has_noncanonical_markup(block: builtins.str) -> builtins.bool {
    payload_spans: List[Tuple[builtins.int, builtins.int]] = [];
    for parameter in _PARAM_RE.finditer(block) {
        payload: any = parameter.group(2);
        if _PARAM_OPEN_RE.search(payload) {
            continue;
        }
        payload_spans.append(parameter.span(2));
    }

    for marker_ in _TOOL_CALL_MARKUP_RE.finditer(block) {
        marker = marker_;
        if marker.group(0) in _CANONICAL_BLOCK_TAGS {
            continue;
        }
        if not `any(
            operator.le(start, marker.start()) and operator.le(marker.end(), end)
            for (start, end) in payload_spans,
        ) {
            return True;
        }
    }
    return False;
}

def _format_param_value(value: Any) -> builtins.str {
    if isinstance(value, `bool) {
        return "true" if value else "false";
    }
    if isinstance(value, (`list, `dict)) {
        return escape(json.dumps(value, separators=(",", ":")));
    }
    if value is None {
        return "";
    }
    return escape(`str(value));
}

def _sanitize_param_content(block: builtins.str) -> builtins.str {
    def _escape(m: re.Match) -> builtins.str {
        (pre, content, post) = (m.group(1), m.group(2), m.group(3));
        clean: any = content.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;");
        return pre + clean + post;
    }

    return _PARAM_RE.sub(_escape, block);
}

def _coerce_param(
    name: builtins.str,
    value: builtins.str,
    param_types: Optional[Dict[builtins.str, builtins.str]] = None,
) -> Any {
    if param_types is None {
        return value;
    }

    expected: any = param_types.get(name, "string");

    if expected == "boolean" {
        return operator.eq(value.strip().lower(), "true");
    }

    if expected == "number" {
        value = value.strip();
        try {
            return `int(value);
        } except ValueError {
            try {
                return `float(value);
            } except ValueError {
                raise ValueError(f"parameter '{name}' expected number, got '{value}'") from None;
            }
        }
    }

    if expected == "list" {
        value = value.strip();
        try {
            parsed: any = json.loads(value);
            if isinstance(parsed, `list) {
                return parsed;
            }
            return [parsed];
        } except (json.JSONDecodeError, ValueError) {
            raise ValueError(f"parameter '{name}' expected list, got '{value}'") from None;
        }
    }

    return value;
}
