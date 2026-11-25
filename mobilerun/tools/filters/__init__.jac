"""Filter exports."""

import builtins;

"""Factory to get filter by name."""
def get_filter(name: builtins.str, **kwargs) -> TreeFilter;

glob __all__: any = ["TreeFilter", "ConciseFilter", "DetailedFilter", "get_filter"];
