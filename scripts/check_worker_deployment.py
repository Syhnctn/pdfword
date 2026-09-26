"""Pre-deploy check: compares the deployed worker against this source tree.

The production worker on Render is built from ``backend/ocr_worker`` by
``render.yaml``. When that image is older than the checked-out code, the app
silently loses features (for example ``POST /internal/convert`` starts returning
404 and every conversion falls back to a degraded path). This script reports
that drift so it can be caught before shipping.

Usage:
    python scripts/check_worker_deployment.py
    python scripts/check_worker_deployment.py --worker https://my-worker.onrender.com
"""

from __future__ import annotations

import argparse
import json
import re
import sys
import urllib.error
import urllib.request
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[1]
WORKER_MAIN = REPO_ROOT / "backend" / "ocr_worker" / "main.py"

DEFAULT_WORKER = "https://pdfword-ocr-worker.onrender.com"

# Endpoints the Flutter client depends on. A missing one degrades or breaks
# conversion even though /healthz keeps returning 200.
REQUIRED_PATHS = (
    "/healthz",
    "/internal/process",
    "/internal/convert",
)

TIMEOUT_SEC = 120


def local_version() -> str:
    source = WORKER_MAIN.read_text(encoding="utf-8-sig")
    match = re.search(r'version\s*=\s*"([^"]+)"', source)
    return match.group(1) if match else "unknown"


def fetch_openapi(worker: str) -> dict:
    request = urllib.request.Request(
        f"{worker.rstrip('/')}/openapi.json",
        headers={"Accept": "application/json"},
    )
    with urllib.request.urlopen(request, timeout=TIMEOUT_SEC) as response:
        return json.loads(response.read().decode("utf-8"))


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--worker", default=DEFAULT_WORKER)
    args = parser.parse_args()

    source_version = local_version()
    print(f"local worker version : {source_version}")

    try:
        spec = fetch_openapi(args.worker)
    except (urllib.error.URLError, TimeoutError, OSError) as exc:
        print(f"FAIL: {args.worker} is unreachable ({exc}).")
        return 2

    deployed_version = str(spec.get("info", {}).get("version", "unknown"))
    deployed_paths = set(spec.get("paths", {}))
    print(f"deployed version     : {deployed_version}")

    missing = [path for path in REQUIRED_PATHS if path not in deployed_paths]
    for path in REQUIRED_PATHS:
        mark = "missing" if path in missing else "ok"
        print(f"  {path:<24} {mark}")

    up_to_date = deployed_version == source_version and not missing
    if up_to_date:
        print("OK: deployed worker matches this source tree.")
        return 0

    print()
    print("DRIFT DETECTED: the deployed worker is older than this source tree.")
    if missing:
        print(f"  missing endpoints: {', '.join(missing)}")
    print("  redeploy on Render (Blueprint autoDeploy, or Dashboard > Manual Deploy)")
    print("  then re-run: python scripts/check_worker_deployment.py")
    return 1


if __name__ == "__main__":
    sys.exit(main())
