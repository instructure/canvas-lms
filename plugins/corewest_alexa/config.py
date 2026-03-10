"""
Configuration for the Core West Alexa API plugin.
Settings are loaded from environment variables with sensible defaults.
"""

import os
from dataclasses import dataclass, field
from typing import List


@dataclass
class Settings:
    # Canvas LMS connection
    canvas_api_url: str = field(
        default_factory=lambda: os.getenv("CANVAS_API_URL", "http://localhost:3000")
    )
    canvas_api_token: str = field(
        default_factory=lambda: os.getenv("CANVAS_API_TOKEN", "")
    )

    # Caching
    cache_ttl_seconds: int = field(
        default_factory=lambda: int(os.getenv("CACHE_TTL_SECONDS", "300"))
    )

    # Server
    debug: bool = field(
        default_factory=lambda: os.getenv("DEBUG", "false").lower() == "true"
    )
    host: str = field(
        # Defaults to 0.0.0.0 for Docker/container deployments.
        # Restrict to 127.0.0.1 in production environments not behind a
        # reverse proxy, and ensure proper firewall / network segmentation.
        default_factory=lambda: os.getenv("HOST", "0.0.0.0")
    )
    port: int = field(
        default_factory=lambda: int(os.getenv("PORT", "8000"))
    )

    # CORS
    allowed_origins: List[str] = field(
        default_factory=lambda: os.getenv(
            "ALLOWED_ORIGINS", "*"
        ).split(",")
    )

    # Fallback / mock data
    use_mock_data: bool = field(
        default_factory=lambda: os.getenv("USE_MOCK_DATA", "true").lower() == "true"
    )


settings = Settings()
