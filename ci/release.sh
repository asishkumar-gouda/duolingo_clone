#!/usr/bin/env bash
set -euo pipefail

VERSION="${1:?Usage: $0 <version> (e.g., $0 v1.0.0)}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT"

echo "=== Creating release ${VERSION} ==="
echo ""

# Ensure we're on a clean working tree
if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "ERROR: Working tree is not clean. Commit or stash your changes first."
  exit 1
fi

# Create annotated tag
git tag -a "${VERSION}" -m "Release ${VERSION}"
echo "Tag ${VERSION} created."

# Push the tag — the pre-push hook will automatically trigger the Jenkins pipeline
echo ""
echo "Pushing tag to remote..."
git push origin "${VERSION}"

echo ""
echo "=== Release ${VERSION} pushed ==="
echo ""
echo "What happens next:"
echo "  1. Git pre-push hook triggered Jenkins pipeline with TAG=${VERSION}"
echo "  2. Jenkins builds Docker image and pushes to local registry"
echo "  3. Jenkins updates Helm values and commits to main"
echo "  4. ArgoCD detects the commit and auto-syncs to Kubernetes"
echo ""
echo "Monitor the deploy:"
echo "  Jenkins:  http://localhost:8081/job/duolingo-clone-deploy/"
echo "  ArgoCD:   https://localhost:8080"
