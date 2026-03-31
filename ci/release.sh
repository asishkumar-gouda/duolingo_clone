#!/usr/bin/env bash
set -euo pipefail

VERSION="${1:?Usage: $0 <version> (e.g., $0 v1.0.0)}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "=== Creating release ${VERSION} ==="
echo ""

# Create annotated tag
cd "$REPO_ROOT"
git tag -a "${VERSION}" -m "Release ${VERSION}"

# Run deploy pipeline
bash "$SCRIPT_DIR/deploy.sh" "${VERSION}"

# Push the tag to remote
git push origin "${VERSION}"

echo ""
echo "=== Release ${VERSION} complete ==="
