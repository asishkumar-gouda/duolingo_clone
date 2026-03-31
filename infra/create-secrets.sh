#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ENV_FILE="$REPO_ROOT/.env"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "ERROR: .env file not found at $ENV_FILE"
  exit 1
fi

echo "Creating K8s secret from .env file..."

kubectl create namespace duolingo-app --dry-run=client -o yaml | kubectl apply -f -

kubectl create secret generic duolingo-clone-secrets \
  -n duolingo-app \
  --from-env-file="$ENV_FILE" \
  --dry-run=client -o yaml | kubectl apply -f -

echo "Secret 'duolingo-clone-secrets' created/updated in duolingo-app namespace."
