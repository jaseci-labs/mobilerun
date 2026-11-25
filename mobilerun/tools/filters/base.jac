import builtins;

import from abc { ABC, abstractmethod }

import from typing { Any, Dict, Optional }

"""Interface for filtering accessibility trees."""
class TreeFilter(ABC) {
    """Filter tree and return filtered tree with hierarchy preserved."""
    @abstractmethod
    def filter(
        a11y_tree: Dict[builtins.str, Any], device_context: Dict[builtins.str, Any]
    ) -> Optional[Dict[builtins.str, Any]];

    """Return filter name."""
    @abstractmethod
    def get_name -> builtins.str;
}
