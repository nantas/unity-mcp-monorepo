#!/usr/bin/env bash
set -e

# AnkleBreaker Unity MCP Plugin Snapshot Installer (macOS/Linux)
# Usage: ./scripts/install-plugin.sh <path-to-unity-project>

UNITY_PROJECT="${1:-}"
if [ -z "$UNITY_PROJECT" ]; then
    echo "Usage: $0 <path-to-unity-project>"
    exit 1
fi

# Resolve paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MONOREPO_ROOT="$(dirname "$SCRIPT_DIR")"
PLUGIN_SRC="$MONOREPO_ROOT/plugin"
TARGET_DIR="$UNITY_PROJECT/Packages/com.anklebreaker.unity-mcp"

# Validate source exists
if [ ! -d "$PLUGIN_SRC" ]; then
    echo "Error: Plugin source not found at $PLUGIN_SRC"
    exit 1
fi

echo "Installing AnkleBreaker Unity MCP plugin..."
echo "  Source: $PLUGIN_SRC"
echo "  Target: $TARGET_DIR"

# Remove existing installation
if [ -e "$TARGET_DIR" ]; then
    echo "Removing existing installation..."
    rm -rf "$TARGET_DIR"
fi

# Ensure target parent exists
mkdir -p "$(dirname "$TARGET_DIR")"

# Copy plugin, excluding development-only files
mkdir -p "$TARGET_DIR"
rsync -a \
    --exclude='.git' \
    --exclude='.github' \
    --exclude='docs' \
    --exclude='CHANGELOG.md' \
    --exclude='.gitignore' \
    --exclude='*.md' \
    "$PLUGIN_SRC/" "$TARGET_DIR/"

# Preserve README.md and its .meta explicitly
if [ -f "$PLUGIN_SRC/README.md" ]; then
    cp "$PLUGIN_SRC/README.md" "$TARGET_DIR/"
fi
if [ -f "$PLUGIN_SRC/README.md.meta" ]; then
    cp "$PLUGIN_SRC/README.md.meta" "$TARGET_DIR/"
fi

echo "Done. Plugin installed at: $TARGET_DIR"
