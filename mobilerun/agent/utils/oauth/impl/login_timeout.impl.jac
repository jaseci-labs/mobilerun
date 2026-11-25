impl OAuthLoginDeadline.init(
    timeout_seconds: float,
    *,
    timeout_message: str = "OAuth login timed out.",
    clock: Callable[[], float] | None = None,
    sleeper: Callable[[float], None] | None = None,
    _expires_at: float | None = None,
) {
    timeout: any = `float(timeout_seconds);
    if not math.isfinite(timeout) or timeout <= 0 {
        raise ValueError("OAuth login timeout must be a finite positive number.");
    }
    self._clock = clock or time.monotonic;
    self._sleeper = sleeper or time.sleep;
    self._timeout_message = timeout_message;
    self._expires_at = self._clock() + timeout if _expires_at is None else _expires_at;
}

impl OAuthLoginDeadline.remaining(*, cap: float | None = None) -> float {
    remaining: any = self._expires_at - self._clock();
    if remaining <= 0 {
        raise TimeoutError(self._timeout_message);
    }
    if cap is None {
        return remaining;
    }
    maximum: any = `float(cap);
    if not math.isfinite(maximum) or maximum <= 0 {
        raise ValueError("OAuth request timeout cap must be finite and positive.");
    }
    return min(remaining, maximum);
}

impl OAuthLoginDeadline.check -> None {
    self.remaining();
}

impl OAuthLoginDeadline.sleep(delay_seconds: float) -> None {
    delay: any = max(0.0, `float(delay_seconds));
    if delay {
        self._sleeper(min(delay, self.remaining()));
    }
    self.check();
}

impl OAuthLoginDeadline.limited_to(timeout_seconds: float) -> OAuthLoginDeadline {
    timeout: any = `float(timeout_seconds);
    if not math.isfinite(timeout) or timeout <= 0 {
        raise ValueError("OAuth login timeout cap must be finite and positive.");
    }
    return OAuthLoginDeadline(
        timeout,
        timeout_message=self._timeout_message,
        clock=self._clock,
        sleeper=self._sleeper,
        _expires_at=min(self._expires_at, self._clock() + timeout),
    );
}

impl open_browser_async(url: str, opener: Callable[[str], object]) -> None {
    def _open -> None {
        try {
            opener(url);
        } except Exception {
            return;
        }
    }

    threading.Thread(target=_open, daemon=True).start();
}
