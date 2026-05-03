#!/bin/sh
# Download the upstream LOOBins JSON catalog into the repo standby area.
# Default source: https://www.loobins.io/loobins.json
#
# Usage: from repo root, bash cicd/sync/sync_loobins_json.sh
# Override: LOOBINS_JSON_URL=https://example/loobins.json bash cicd/sync/sync_loobins_json.sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)
OUT_DIR="$ROOT/attackmacos/standby/LOOBins"
OUT_FILE="$OUT_DIR/loobins.json"
URL="${LOOBINS_JSON_URL:-https://www.loobins.io/loobins.json}"

mkdir -p "$OUT_DIR"
tmp="$OUT_FILE.part.$$"
if ! curl -fsSL "$URL" -o "$tmp"; then
  rm -f "$tmp"
  echo "Failed to download: $URL" >&2
  exit 1
fi
mv "$tmp" "$OUT_FILE"
echo "Wrote $OUT_FILE ($(wc -c < "$OUT_FILE" | tr -d ' ') bytes)"
