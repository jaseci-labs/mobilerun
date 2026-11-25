import builtins;

def get_filter(name: builtins.str, **kwargs) -> TreeFilter {
    filters: any = {"concise": ConciseFilter, "detailed": DetailedFilter};

    filter_class: any = filters.get(name.lower());
    if filter_class is None {
        raise ValueError(f"Unknown filter: {name}. Available: {`list(filters.keys())}");
    }

    return filter_class(**kwargs);
}

glob __all__: any = ["TreeFilter", "ConciseFilter", "DetailedFilter", "get_filter"];
