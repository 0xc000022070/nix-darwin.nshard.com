#!/usr/bin/env bash

# Script to generate options.json from nix-darwin
# Usage: bash scripts/generate-options.sh [--source /path/to/flake]

set -euo pipefail

SOURCE_DIR="${1:-.}"
if [[ "$SOURCE_DIR" == "--source" ]]; then
  SOURCE_DIR="${2:-.}"
fi

# Resolve to absolute path
SOURCE_DIR="$(cd "$SOURCE_DIR" && pwd)"

OUTPUT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/public/data"
mkdir -p "$OUTPUT_DIR"

echo "Generating options.json from $SOURCE_DIR..."

# Check if nix is available
if ! command -v nix &> /dev/null; then
  echo "Error: nix command not found. Please install Nix to generate options.json"
  exit 1
fi

# Check if we have a flake
if [[ ! -f "$SOURCE_DIR/flake.nix" ]]; then
  echo "Error: flake.nix not found in $SOURCE_DIR"
  exit 1
fi

# Build the optionsJSON package
echo "Building options JSON..."
nix build "$SOURCE_DIR#docs.optionsJSON" --no-link -o /tmp/nix-darwin-options || {
  echo "Error: Failed to build options JSON"
  echo "Trying alternative build path..."
  nix build "$SOURCE_DIR#packages.$(nix eval --impure --expr 'builtins.currentSystem').optionsJSON" --no-link -o /tmp/nix-darwin-options || {
    echo "Error: Could not build options JSON"
    exit 1
  }
}

# Extract the options.json file
if [[ -f /tmp/nix-darwin-options/share/doc/darwin/options.json ]]; then
  cp /tmp/nix-darwin-options/share/doc/darwin/options.json "$OUTPUT_DIR/options.json"
  echo "Successfully generated options.json at $OUTPUT_DIR/options.json"

  # Show some stats
  NUM_OPTIONS=$(jq 'keys | length' "$OUTPUT_DIR/options.json" 2>/dev/null || echo "?")
  echo "Found $NUM_OPTIONS options"
elif [[ -f /tmp/nix-darwin-options/options.json ]]; then
  cp /tmp/nix-darwin-options/options.json "$OUTPUT_DIR/options.json"
  echo "Successfully generated options.json at $OUTPUT_DIR/options.json"
else
  echo "Error: Could not find options.json in build output"
  ls -la /tmp/nix-darwin-options/ || true
  exit 1
fi
