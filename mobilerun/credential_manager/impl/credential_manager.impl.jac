impl CredentialNotFoundError.__repr__ -> str {
    return (getattr(builtins.super(CredentialNotFoundError, self), "__repr__") as any)();
}

impl CredentialNotFoundError.__eq__(other: any) -> bool {
    return self is other;
}

impl CredentialNotFoundError.__hash__ -> int {
    return id(self);
}

impl CredentialManager.resolve_key(key: builtins.str) -> builtins.str {}

impl CredentialManager.get_keys -> List[builtins.str] {}
