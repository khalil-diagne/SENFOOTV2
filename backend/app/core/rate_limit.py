import time
from collections import defaultdict, deque

from fastapi import HTTPException, Request


class InMemoryRateLimiter:
    def __init__(self, max_requests: int, window_seconds: int) -> None:
        self.max_requests = max_requests
        self.window_seconds = window_seconds
        self._hits: dict[str, deque[float]] = defaultdict(deque)

    def check(self, key: str) -> None:
        now = time.monotonic()
        window_start = now - self.window_seconds
        hits = self._hits[key]
        while hits and hits[0] <= window_start:
            hits.popleft()
        if len(hits) >= self.max_requests:
            raise HTTPException(
                status_code=429,
                detail="Trop de tentatives. Réessayez dans quelques instants.",
            )
        hits.append(now)


login_limiter = InMemoryRateLimiter(max_requests=5, window_seconds=60)
register_limiter = InMemoryRateLimiter(max_requests=3, window_seconds=60)


def client_ip(request: Request) -> str:
    if request.client and request.client.host:
        return request.client.host
    return "unknown"
