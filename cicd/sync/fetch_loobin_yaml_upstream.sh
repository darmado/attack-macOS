#!/bin/sh
# Fetch a single upstream LOOBin YAML from infosecB/LOOBins into standby.
#
# Browse binaries: https://www.loobins.io/binaries/
# Upstream source: https://github.com/infosecB/LOOBins/tree/main/LOOBins
#
# Usage (from repo root):
#   sh cicd/sync/fetch_loobin_yaml_upstream.sh log
#   LOOBINS_BRANCH=main sh cicd/sync/fetch_loobin_yaml_upstream.sh GetFileInfo
#
# Writes: attackmacos/standby/LOOBins/<name>.yml
#
# Note: upstream file names are case-sensitive (e.g. GetFileInfo.yml).

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)
OUT_DIR="$ROOT/attackmacos/standby/LOOBins"
BRANCH="${LOOBINS_BRANCH:-main}"
BASE="https://raw.githubusercontent.com/infosecB/LOOBins/${BRANCH}/LOOBins"

if [ "$#" -lt 1 ] || [ -z "$1" ]; then
	echo "Usage: $0 <binary-name>" >&2
	echo "Example: $0 log" >&2
	exit 1
fi

name="$1"
url="${BASE}/${name}.yml"
mkdir -p "$OUT_DIR"
out="$OUT_DIR/${name}.yml"
tmp="$out.part.$$"
if ! curl -fsSL "$url" -o "$tmp"; then
	rm -f "$tmp"
	echo "Failed to download: $url" >&2
	echo "Check the name matches the file under LOOBins/ on GitHub." >&2
	exit 1
fi
mv "$tmp" "$out"
echo "Wrote $out"
