#!/bin/bash
# Build the grok-badge helper (Swift) into launcher/bin/grok-badge.
# Usage: launcher/scripts/build.sh
set -euo pipefail
launcher_dir="$(cd "$(dirname "$0")/.." && pwd)"
mkdir -p "$launcher_dir/bin"
swiftc -O -framework AppKit -o "$launcher_dir/bin/grok-badge" "$launcher_dir/src/GrokBadge.swift"
echo "built $launcher_dir/bin/grok-badge"
