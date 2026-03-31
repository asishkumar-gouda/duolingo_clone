#!/usr/bin/env bash
set -euo pipefail

# --- Configuration ---
REGISTRY="localhost:5001"
IMAGE_NAME="duolingo-clone"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
VALUES_FILE="$REPO_ROOT/deploy/values.yaml"
CHART_FILE="$REPO_ROOT/deploy/Chart.yaml"
ENV_FILE="$REPO_ROOT/.env"

# --- Source NEXT_PUBLIC_ vars for build args ---
if [[ -f "$ENV_FILE" ]]; then
  set -a
  source "$ENV_FILE"
  set +a
fi

# --- Determine version ---
VERSION="${1:-}"
if [[ -z "$VERSION" ]]; then
  VERSION="$(git -C "$REPO_ROOT" describe --tags --abbrev=0 2>/dev/null || echo "")"
fi
if [[ -z "$VERSION" ]]; then
  echo "ERROR: No version specified and no git tag found."
  echo "Usage: $0 <version>  (e.g., $0 v1.0.0)"
  exit 1
fi

# Strip leading 'v' for Docker tag
DOCKER_TAG="${VERSION#v}"
FULL_IMAGE="${REGISTRY}/${IMAGE_NAME}:${DOCKER_TAG}"

echo "=== Deploying version: ${VERSION} (image tag: ${DOCKER_TAG}) ==="
echo ""

# --- Pre-flight checks ---
if ! curl -sf "http://${REGISTRY}/v2/" > /dev/null 2>&1; then
  echo "ERROR: Registry at ${REGISTRY} is not reachable."
  echo "Run 'bash infra/setup-cluster.sh' first."
  exit 1
fi

if ! kubectl cluster-info > /dev/null 2>&1; then
  echo "ERROR: No Kubernetes cluster found."
  exit 1
fi

# --- Build ---
echo "=== Step 1/4: Building Docker image ==="
docker build \
  -t "${FULL_IMAGE}" \
  -t "${REGISTRY}/${IMAGE_NAME}:latest" \
  --build-arg NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY="${NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY:-}" \
  --build-arg NEXT_PUBLIC_APP_URL="${NEXT_PUBLIC_APP_URL:-http://localhost}" \
  "$REPO_ROOT"

# --- Push ---
echo ""
echo "=== Step 2/4: Pushing to local registry ==="
docker push "${FULL_IMAGE}"
docker push "${REGISTRY}/${IMAGE_NAME}:latest"

# --- Update Helm values ---
echo ""
echo "=== Step 3/4: Updating Helm values ==="
sed -i "s|^  tag:.*|  tag: \"${DOCKER_TAG}\"|" "$VALUES_FILE"
sed -i "s|^appVersion:.*|appVersion: \"${DOCKER_TAG}\"|" "$CHART_FILE"

# --- Git commit and push ---
echo ""
echo "=== Step 4/4: Committing and pushing ==="
cd "$REPO_ROOT"
git add deploy/values.yaml deploy/Chart.yaml
if git diff --cached --quiet; then
  echo "No changes to commit (image tag unchanged)."
else
  git commit -m "ci: update image tag to ${DOCKER_TAG}"
  git push origin HEAD
fi

echo ""
echo "=== Deploy complete ==="
echo "Image: ${FULL_IMAGE}"
echo "ArgoCD will detect the commit and sync automatically."
