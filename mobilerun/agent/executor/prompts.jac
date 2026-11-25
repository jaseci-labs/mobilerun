import builtins;

def parse_executor_response(response: builtins.str) -> builtins.dict {
    thought: any = response.split("### Thought")[-1].split("### Action")[0].replace(
        "\n", " "
    ).replace("  ", " ").replace("###", "").strip();
    action_raw: any = response.split("### Action")[-1].split("### Description")[0].replace(
        "\n", " "
    ).replace("  ", " ").replace("###", "").strip();
    start_idx: any = action_raw.find("{");
    end_idx: any = action_raw.rfind("}");
    if start_idx != -1 and end_idx != -1 {
        action: any = action_raw[start_idx:end_idx + 1];
    } else {
        action = action_raw;
    }
    description: any = response.split("### Description")[-1].replace("\n", " ").replace(
        "  ", " "
    ).replace("###", "").strip();

    return {"thought": thought, "action": action, "description": description};
}
