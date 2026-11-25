import builtins;

import from abc { ABC, abstractmethod }

import from typing { List }

"""Raised when a credential key is not found."""
class CredentialNotFoundError(KeyError) {}

"""Abstract base class for credential resolution."""
class CredentialManager(ABC) {
    """
        Resolve and return the value for the given credential key.

        Args:
            key: Credential identifier

        Returns:
            The credential value as a string

        Raises:
            CredentialNotFoundError: If key doesn't exist
        """
    @abstractmethod
    async def resolve_key(key: builtins.str) -> builtins.str;

    """
        Get all available credential keys.

        Returns:
            List of credential identifiers
        """
    @abstractmethod
    async def get_keys -> List[builtins.str];
}
