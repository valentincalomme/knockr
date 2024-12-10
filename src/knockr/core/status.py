class Status:
    """Status of a particular url."""

    def __init__(self, *, live: bool = False) -> None:
        self.__live = live

    @property
    def live(self) -> bool:
        """Whether the response indicates that the URL is live."""
        return self.__live
