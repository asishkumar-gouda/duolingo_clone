#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CLUSTER_NAME="duolingo-dev"
REGISTRY_NAME="kind-registry"
REGISTRY_PORT="5001"
REGISTRY_UI_PORT="5002"
JENKINS_PORT="8081"

echo "=== Duolingo Clone - Local K8s + CI/CD Setup ==="
echo ""

# --- Step 1: Local Docker Registry (with CORS for UI) ---
echo "--- Step 1/8: Setting up local Docker registry ---"
if docker inspect "$REGISTRY_NAME" >/dev/null 2>&1; then
  echo "Registry '$REGISTRY_NAME' already exists."
else
  docker run -d --restart=always \
    -p "127.0.0.1:${REGISTRY_PORT}:5000" \
    --name "$REGISTRY_NAME" \
    -e REGISTRY_HTTP_HEADERS_Access-Control-Allow-Origin='["*"]' \
    -e REGISTRY_HTTP_HEADERS_Access-Control-Allow-Methods='["HEAD","GET","OPTIONS","DELETE"]' \
    -e REGISTRY_HTTP_HEADERS_Access-Control-Allow-Headers='["Authorization","Accept","Cache-Control"]' \
    -e REGISTRY_HTTP_HEADERS_Access-Control-Expose-Headers='["Docker-Content-Digest"]' \
    -e REGISTRY_STORAGE_DELETE_ENABLED=true \
    registry:2
  echo "Registry started on localhost:${REGISTRY_PORT}"
fi

# --- Step 2: Registry UI ---
echo ""
echo "--- Step 2/8: Setting up Registry UI ---"
if docker inspect registry-ui >/dev/null 2>&1; then
  echo "Registry UI already exists."
else
  docker run -d --restart=always \
    -p "127.0.0.1:${REGISTRY_UI_PORT}:80" \
    --name registry-ui \
    -e REGISTRY_TITLE="Duolingo Registry" \
    -e NGINX_PROXY_PASS_URL="http://${REGISTRY_NAME}:5000" \
    -e SINGLE_REGISTRY=true \
    -e DELETE_IMAGES=true \
    joxit/docker-registry-ui
  echo "Registry UI started on http://localhost:${REGISTRY_UI_PORT}"
fi

# --- Step 3: Jenkins ---
echo ""
echo "--- Step 3/8: Setting up Jenkins ---"
if docker inspect jenkins >/dev/null 2>&1; then
  echo "Jenkins already exists."
else
  echo "Building Jenkins image with Docker CLI..."
  docker build -t jenkins-docker -f "$SCRIPT_DIR/jenkins.Dockerfile" "$SCRIPT_DIR"

  # MSYS_NO_PATHCONV prevents Git Bash on Windows from mangling /var/run paths
  MSYS_NO_PATHCONV=1 docker run -d --restart=always \
    -p "127.0.0.1:${JENKINS_PORT}:8080" \
    -p "127.0.0.1:50000:50000" \
    --name jenkins \
    -v jenkins_home:/var/jenkins_home \
    -v /var/run/docker.sock:/var/run/docker.sock \
    jenkins-docker
  echo "Jenkins started on http://localhost:${JENKINS_PORT}"
  echo ""
  echo "  Waiting for Jenkins to initialize (this takes ~60s on first run)..."
  sleep 10
  echo "  Jenkins initial admin password:"
  for i in $(seq 1 12); do
    if docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword 2>/dev/null; then
      break
    fi
    sleep 5
  done
  echo ""
fi

# --- Step 4: Kind Cluster ---
echo ""
echo "--- Step 4/8: Creating Kind cluster ---"
if kind get clusters 2>/dev/null | grep -q "^${CLUSTER_NAME}$"; then
  echo "Cluster '$CLUSTER_NAME' already exists."
else
  kind create cluster --name "$CLUSTER_NAME" --config "$SCRIPT_DIR/kind-config.yaml"
fi

# --- Step 5: Connect containers to Kind network ---
echo ""
echo "--- Step 5/8: Connecting containers to Kind network ---"
docker network connect kind "$REGISTRY_NAME" 2>/dev/null || true
docker network connect kind registry-ui 2>/dev/null || true
docker network connect kind jenkins 2>/dev/null || true
echo "All containers connected to Kind network."

# --- Step 6: Registry ConfigMap ---
echo ""
echo "--- Step 6/8: Applying registry ConfigMap ---"
kubectl apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: local-registry-hosting
  namespace: kube-public
data:
  localRegistryHosting.v1: |
    host: "localhost:${REGISTRY_PORT}"
    help: "https://kind.sigs.k8s.io/docs/user/local-registry/"
EOF

# --- Step 7: Install ArgoCD ---
echo ""
echo "--- Step 7/8: Installing ArgoCD ---"
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
echo "Waiting for ArgoCD server to be ready (this may take a few minutes)..."
kubectl rollout status deployment/argocd-server -n argocd --timeout=300s

# Expose ArgoCD as NodePort so it's always accessible (no port-forward needed)
kubectl patch svc argocd-server -n argocd --type='json' \
  -p='[{"op":"replace","path":"/spec/type","value":"NodePort"},{"op":"replace","path":"/spec/ports/0/nodePort","value":30443}]'

# --- Step 8: Apply ArgoCD Application ---
echo ""
echo "--- Step 8/8: Creating ArgoCD Application ---"
kubectl apply -f "$SCRIPT_DIR/argocd-app.yaml"

# --- Done ---
echo ""
echo "============================================"
echo "  Setup Complete! All UIs accessible:"
echo "============================================"
echo ""
echo "  App (after deploy):  http://localhost"
echo "  ArgoCD:              https://localhost:8080"
echo "  Jenkins:             http://localhost:${JENKINS_PORT}"
echo "  Registry UI:         http://localhost:${REGISTRY_UI_PORT}"
echo ""
echo "ArgoCD credentials:"
echo "  User: admin"
echo -n "  Pass: "
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
echo ""
echo ""
echo "Next steps:"
echo "  1. bash infra/create-secrets.sh                 (create K8s secrets)"
echo "  2. Open http://localhost:${JENKINS_PORT}         (setup Jenkins)"
echo "  3. Create a Pipeline job pointing to the Jenkinsfile in this repo"
echo "  4. Run the pipeline with TAG=v0.1.0              (first deploy)"
