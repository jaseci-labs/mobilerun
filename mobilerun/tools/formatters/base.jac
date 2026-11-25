import builtins;

import from abc { ABC, abstractmethod }

import from typing { Any, Dict, List, Optional, Tuple }

"""Interface for formatting filtered trees."""
class TreeFormatter(ABC) {
    """Format filtered tree to standard output format.

        Args:
            filtered_tree: Filtered accessibility tree (or None)
            phone_state: Raw phone state dictionary

        Returns:
            Tuple of:
            - formatted_text (str): Complete formatted device state for prompts
            - focused_text (str): Text content of focused element (empty if none)
            - a11y_tree (List[Dict]): Flattened/Processed accessibility tree with indices
            - phone_state (Dict): Raw phone state dict
        """
    @abstractmethod
    def format(
        filtered_tree: Optional[Dict[builtins.str, Any]], phone_state: Dict[builtins.str, Any]
    ) -> Tuple[builtins.str, builtins.str, List[Dict[builtins.str, Any]], Dict[builtins.str, Any]];
}
