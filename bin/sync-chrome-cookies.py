#!/usr/bin/env python3
"""Extract Chrome cookies and convert to Playwright storage state JSON.

Reads cookies from Chrome using rookiepy (works while Chrome is running),
filters for target domains, and writes a Playwright-compatible
storage-state JSON file.
"""

import json
import sys
from pathlib import Path

import rookiepy

TARGET_DOMAINS = [
    ".substack.com",
    ".medium.com",
    ".x.com",
    ".twitter.com",
    ".oreilly.com",
]

OUTPUT_PATH = Path.home() / ".playwright-profile" / "storage-state.json"

EMPTY_STATE = {"cookies": [], "origins": []}


def domain_matches(cookie_domain: str) -> bool:
    for target in TARGET_DOMAINS:
        if cookie_domain == target or cookie_domain.endswith(target):
            return True
    return False


def to_playwright_cookie(c: dict) -> dict:
    return {
        "name": c["name"],
        "value": c["value"],
        "domain": c["domain"],
        "path": c.get("path", "/"),
        "expires": c.get("expires", -1),
        "httpOnly": bool(c.get("httponly", c.get("httpOnly", False))),
        "secure": bool(c.get("secure", False)),
        "sameSite": c.get("samesite", c.get("sameSite", "Lax")),
    }


def main() -> int:
    OUTPUT_PATH.parent.mkdir(parents=True, exist_ok=True)

    try:
        cookies = rookiepy.chrome(TARGET_DOMAINS)
    except Exception as e:
        print(f"Warning: cookie extraction failed: {e}", file=sys.stderr)
        OUTPUT_PATH.write_text(json.dumps(EMPTY_STATE, indent=2))
        return 0  # graceful fallback

    filtered = [to_playwright_cookie(c) for c in cookies if domain_matches(c.get("domain", ""))]

    state = {"cookies": filtered, "origins": []}
    OUTPUT_PATH.write_text(json.dumps(state, indent=2))
    print(f"Synced {len(filtered)} cookies to {OUTPUT_PATH}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
