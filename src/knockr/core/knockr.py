import http.client
import urllib.parse

from knockr.core.status import Status


class Knockr:
    """Object in charge of "knocking" at the URLs' doors."""

    def __init__(self, timeout: float = 5.0) -> None:
        self.__timeout = timeout

    @property
    def timeout(self) -> float:
        """Timeout allowed for an HTTP connection."""
        return self.__timeout

    def get_status(self, url: str) -> Status:
        """Retrieve the status of a particular URL."""
        # Parse the URL to extract its components
        parsed_url = urllib.parse.urlparse(url)

        # Determine the connection type (http or https)
        conn = (
            http.client.HTTPSConnection(parsed_url.netloc, timeout=self.timeout)
            if parsed_url.scheme == "https"
            else http.client.HTTPConnection(parsed_url.netloc, timeout=self.timeout)
        )
        try:
            # Send a HEAD request
            conn.request("HEAD", parsed_url.path or "/")
            response = conn.getresponse()

            return Status(live=response.status < 400)  # noqa: PLR2004

        except Exception:  # noqa: BLE001
            return Status(live=False)

        finally:
            conn.close()
