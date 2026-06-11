#!/usr/bin/env bash

# Script to generate options.json from nix-darwin
# Fetches the latest nix-darwin repository and generates options.json
# Usage: bash scripts/generate-options.sh [--source /path/to/flake] [--repo https://github.com/nix-darwin/nix-darwin]

set -euo pipefail

SOURCE_DIR=""
REPO_URL="https://github.com/nix-darwin/nix-darwin"
NIXPKGS_INPUT="github:NixOS/nixpkgs/nixpkgs-unstable"
TEMP_DIR=""

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --source)
      SOURCE_DIR="$2"
      shift 2
      ;;
    --repo)
      REPO_URL="$2"
      shift 2
      ;;
    *)
      SOURCE_DIR="$1"
      shift
      ;;
  esac
done

# If no source dir specified, clone/fetch from nix-darwin
if [[ -z "$SOURCE_DIR" ]]; then
  TEMP_DIR="$(mktemp -d)"
  trap "rm -rf '$TEMP_DIR'" EXIT

  echo "Cloning nix-darwin from $REPO_URL..."
  git clone --depth 1 "$REPO_URL" "$TEMP_DIR" || {
    echo "Error: Failed to clone nix-darwin repository"
    exit 1
  }
  SOURCE_DIR="$TEMP_DIR"
else
  # Resolve to absolute path
  SOURCE_DIR="$(cd "$SOURCE_DIR" && pwd)"
fi

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

SYSTEM="$(nix eval --impure --expr 'builtins.currentSystem')"

# nix-darwin master tracks the next release and needs a matching nixpkgs input.
echo "Building options JSON..."
nix build "$SOURCE_DIR#packages.${SYSTEM}.optionsJSON" \
  --override-input nixpkgs "$NIXPKGS_INPUT" \
  --no-link -o /tmp/nix-darwin-options || {
  echo "Error: Failed to build options JSON"
  exit 1
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
