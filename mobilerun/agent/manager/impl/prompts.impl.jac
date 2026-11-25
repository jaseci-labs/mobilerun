impl ManagerResponseValidationError.__repr__ -> str {
    return (getattr(builtins.super(ManagerResponseValidationError, self), "__repr__") as any)();
}

impl ManagerResponseValidationError.__eq__(other: any) -> bool {
    return self is other;
}

impl ManagerResponseValidationError.__hash__ -> int {
    return id(self);
}

impl _find_tag_matches(
    response: builtins.str, tag: builtins.str
) -> builtins.list[re.Match[builtins.str]] {
    pattern: any = re.compile(
        f"<{tag}\\b(?P<attrs>[^>]*)>(?P<body>.*?)</{tag}>", re.IGNORECASE | re.DOTALL
    );
    return `list(pattern.finditer(response));
}

impl _tag_content(`match: re.Match[builtins.str]) -> builtins.str {
    return `match.group("body").strip();
}

impl _success_from_attrs(attrs: builtins.str) -> builtins.bool | None {
    success_attributes: builtins.list[builtins.tuple[builtins.str | None, builtins.str]] = [];
    position: any = 0;

    while position < len(attrs) {
        if not attrs[position:].strip() {
            break;
        }

        `match: any = _ATTRIBUTE_RE.match(attrs, position);
        if not `match {
            return None;
        }

        if `match.group("name").lower() == "success" {
            value: any = `match.group("quoted_value") or `match.group("bare_value");
            success_attributes.append((`match.group("quote"), value or ""));
        }
        position = `match.end();
    }

    if len(success_attributes) != 1 {
        return None;
    }

    quote: any;
    (quote, value) = success_attributes[0] as any;
    if quote is None or value.lower() not in {"true", "false"} {
        return None;
    }
    return operator.eq(value.lower(), "true");
}

impl _find_top_level_manager_result_tags(
    response: builtins.str
) -> builtins.tuple[builtins.list[builtins.dict[builtins.str, builtins.str]], builtins.list[builtins.str]] {
    `match: any;
    stack: builtins.list[builtins.dict[builtins.str, builtins.str | builtins.int]] = [];
    results: builtins.list[builtins.dict[builtins.str, builtins.str]] = [];
    errors: any = [
        "malformed <" + format(`match.group("tag").lower(), "") + "> tag"
        for `match in _SPACED_MANAGER_RESULT_TAG_RE.finditer(response)
    ];
    errors.extend(
        "unterminated "
            + format("closing " if `match.group("closing") else "", "")
            + "<"
            + format(`match.group("tag").lower(), "")
            + "> tag"
        for `match in _TRAILING_UNTERMINATED_MANAGER_RESULT_TAG_RE.finditer(response),
    );

    for `match in _TAG_TOKEN_RE.finditer(response) {
        tag: any = `match.group("tag").lower();
        attrs: any = `match.group("attrs");
        is_closing: any = `bool(`match.group("closing"));
        is_self_closing: any = not is_closing and attrs.rstrip().endswith("/");
        if is_self_closing {
            attrs = attrs.rstrip()[:-1];
        }

        if is_closing {
            if attrs.strip() {
                if tag in _MANAGER_RESULT_TAGS {
                    errors.append(f"malformed closing <{tag}> tag");
                }
                continue;
            }

            if not stack or stack[-1]["tag"] != tag {
                if tag in _MANAGER_RESULT_TAGS {
                    errors.append(f"unmatched closing <{tag}> tag");
                }
                continue;
            }

            opening: any = stack.pop();
            if opening["tag"] in _MANAGER_RESULT_TAGS and opening["depth"] == 0 {
                results.append({
                    "tag": `str(opening["tag"]),
                    "attrs": `str(opening["attrs"]),
                    "body": response[`int(opening["body_start"]):`match.start()],
                });
            }
            continue;
        }

        if is_self_closing {
            if tag in _MANAGER_RESULT_TAGS {
                errors.append(f"self-closing <{tag}> tag");
            }
            continue;
        }

        has_open_top_level_result: any = `any(
            opening["tag"] in _MANAGER_RESULT_TAGS and operator.eq(opening["depth"], 0)
            for opening in stack,
        );
        if has_open_top_level_result and tag not in _MANAGER_RESPONSE_ENVELOPE_TAGS {
            continue;
        }

        depth: any = len(stack);
        if tag in _MANAGER_RESULT_TAGS and depth {
            errors.append(f"nested <{tag}> tag");
        }
        stack.append({
            "tag": tag,
            "attrs": attrs,
            "depth": depth,
            "start": `match.start(),
            "body_start": `match.end(),
        });
    }

    for opening in stack {
        if opening["tag"] in _MANAGER_RESULT_TAGS {
            errors.append("unclosed <" + format(opening["tag"], "") + "> tag");
        }
    }

    return (results, errors);
}

impl parse_manager_response(response: builtins.str) -> builtins.dict {
    """Extract content between XML-style tags (handles attributes)."""
    def extract(tag: builtins.str) -> builtins.str {
        matches: any = _find_tag_matches(response, tag);
        if matches {
            return _tag_content(matches[0]);
        }
        return "";
    }

    """Extract and combine content from all occurrences of a tag."""
    def extract_all(tag: builtins.str) -> builtins.str {
        matches: any = [_tag_content(`match) for `match in _find_tag_matches(response, tag)];
        if not matches {
            return "";
        }
        return "\n".join(`match for `match in matches if `match);
    }

    thought: any = extract("thought");
    memory_section: any = extract_all("add_memory");
    progress_summary: any = extract("progress_summary");
    result_tags: any;
    result_tag_errors: any;
    (result_tags, result_tag_errors) = _find_top_level_manager_result_tags(response) as any;
    plan_matches: any = [tag for tag in result_tags if tag["tag"] == "plan"];
    final_matches: any = [tag for tag in result_tags if tag["tag"] in FINAL_RESPONSE_TAGS];
    plan: any = plan_matches[0]["body"].strip() if plan_matches else "";

    final_match: any = None;
    for `match in final_matches {
        if `match["body"].strip() {
            final_match = `match;
            break;
        }
    }
    if final_match is None and final_matches {
        final_match = final_matches[0];
    }

    answer: any = final_match["body"].strip() if final_match else "";
    success: any = None;
    final_tag: any = None;
    if final_match {
        final_tag = final_match["tag"];
        success = _success_from_attrs(final_match["attrs"]);
    }

    final_counts: any = {
        tag: sum(1 for `match in final_matches if `match["tag"] == tag)
        for tag in FINAL_RESPONSE_TAGS
    };
    current_goal_text: any = plan;
    script_match: any = re.search("^\\s*<script>(.*?)</script>", current_goal_text, re.DOTALL);

    if script_match {
        current_subgoal: any = f"<script>{script_match.group(1).strip()}</script>";
    } else {
        plan_lines: any = [line.strip() for line in current_goal_text.splitlines() if line.strip()];
        if plan_lines {
            first_line: any = plan_lines[0];
        } else {
            first_line = current_goal_text.strip();
        }
        first_line = re.sub("^\\s*\\d+\\.\\s*", "", first_line);
        first_line = re.sub("^\\s*[-*]\\s*", "", first_line);
        first_line = re.sub("^\\s*•\\s*", "", first_line);

        current_subgoal = first_line.strip();
    }

    return {
        "thought": thought,
        "plan": plan,
        "memory": memory_section,
        "current_subgoal": current_subgoal,
        "answer": answer,
        "success": success,
        "progress_summary": progress_summary,
        "final_tag": final_tag,
        "result_tag_errors": result_tag_errors,
        "tag_counts": {
            "plan": len(plan_matches),
            "request_accomplished": final_counts["request_accomplished"],
            "answer": final_counts["answer"],
            "final": len(final_matches),
        },
    };
}

impl validate_manager_response(parsed: builtins.dict) -> ManagerResponseValidation {
    plan: any = (parsed.get("plan") or "").strip();
    answer: any = (parsed.get("answer") or "").strip();
    success: any = parsed.get("success");
    result_tag_errors: any = parsed.get("result_tag_errors") or [];
    tag_counts: any = parsed.get("tag_counts") or {};
    plan_count: any = tag_counts.get("plan", 1 if plan else 0);
    final_count: any = tag_counts.get("final", 1 if answer else 0);

    if result_tag_errors {
        return ManagerResponseValidation(
            is_valid=False,
            error_message="Manager response contains malformed or nested control tags. Provide one complete, top-level <plan> or final answer tag.",
        );
    }

    if plan_count > 1 {
        return ManagerResponseValidation(
            is_valid=False,
            error_message="Manager response contains multiple <plan> tags. Provide exactly one <plan>, or exactly one final answer tag.",
        );
    }

    if final_count > 1 {
        return ManagerResponseValidation(
            is_valid=False,
            error_message="Manager response contains multiple final answer tags. Provide exactly one <request_accomplished> or <answer> tag.",
        );
    }

    if plan_count == 1 and final_count == 1 {
        return ManagerResponseValidation(
            is_valid=False,
            error_message="Manager response must provide exactly one of <plan> or a final answer tag, not both.",
        );
    }

    if plan_count == 1 and not plan {
        return ManagerResponseValidation(
            is_valid=False, error_message="Manager <plan> tag must not be empty."
        );
    }

    if final_count == 1 and not answer {
        return ManagerResponseValidation(
            is_valid=False, error_message="Manager final answer tag must not be empty."
        );
    }

    if answer {
        if success is None {
            return ManagerResponseValidation(
                is_valid=False,
                error_message="Final answer tag must include success=\"true\" or success=\"false\".",
            );
        }
        return ManagerResponseValidation(is_valid=True);
    }

    if plan {
        return ManagerResponseValidation(is_valid=True);
    }

    return ManagerResponseValidation(
        is_valid=False,
        error_message="Manager response must provide exactly one of <plan> or a final answer tag.",
    );
}
