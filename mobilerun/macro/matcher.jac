
import from dataclasses { dataclass }

import from typing { Any, Dict, Tuple }

@dataclass(frozen=True)
class StateMatchResult {
    has matches: bool;

    has score: float;

    has reason: str;
}

def compare_states(
    saved_state: Dict[str, Any], current_state: Dict[str, Any], threshold: float = 0.85
) -> StateMatchResult {
    saved_keys: any = _node_key_set(saved_state);
    current_keys: any = _node_key_set(current_state);

    if saved_keys or current_keys {
        intersection: any = len(saved_keys & current_keys);
        union: any = len(saved_keys | current_keys);
        node_score: any = intersection / union if union else 1.0;
    } else {
        node_score = 1.0;
    }

    phone_score: any = _phone_score(saved_state, current_state);
    score: any = round(node_score * 0.85 + phone_score * 0.15, 4);

    if score >= threshold {
        return StateMatchResult(True, score, f"state matched with score {score:.2f}");
    }

    return StateMatchResult(
        False, score, f"state similarity {score:.2f} below threshold {threshold:.2f}"
    );
}

def _node_key_set(state: Dict[str, Any]) -> set[Tuple[Any, ...]] {
    return {
        node_semantic_key(`node)
        for `node in state.get("nodes", [])
        if `any(part is not None and (part != "") for part in node_semantic_key(`node))
    };
}

def _phone_score(saved_state: Dict[str, Any], current_state: Dict[str, Any]) -> float {
    saved_phone = saved_state.get("phone_state") or {};
    current_phone = current_state.get("phone_state") or {};
    fields: any = [
        field
        for field in ("package", "activity")
        if saved_phone.get(field) is not None or current_phone.get(field) is not None
    ];
    if not fields {
        return 1.0;
    }
    matches: any = sum(1 for field in fields if saved_phone.get(field) == current_phone.get(field));
    return matches / len(fields);
}
