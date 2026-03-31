# Tag-Based Deploy Pipeline

A fully automated GitOps deployment pipeline for the Duolingo Clone. Push a git tag, and the app deploys itself — from Docker build to Kubernetes rollout.

```
git tag -a v1.0.3 -m "new release"
git push origin v1.0.3
```

That's it. Jenkins builds, pushes, updates the Helm chart, and ArgoCD rolls it out to the cluster.

---

## Architecture

```
Developer                  Jenkins                    Registry             Kubernetes
   │                          │                          │                     │
   │  git tag v1.0.3          │                          │                     │
   │  git push origin v1.0.3  │                          │                     │
   │──────────────────────────>│                          │                     │
   │   (pre-push hook          │                          │                     │
   │    triggers Jenkins)      │                          │                     │
   │                          │  Build Docker Image       │                     │
   │                          │  (BuildKit cached)        │                     │
   │                          │────────────────────────-->│                     │
   │                          │  Push to localhost:5001   │                     │
   │                          │                           │                     │
   │                          │  Update Helm chart tag    │                     │
   │                          │  Commit & push to GitHub  │                     │
   │                          │──────────────────────────────────────────────-->│
   │                          │                           │    ArgoCD detects   │
   │                          │                           │    Helm change and  │
   │                          │                           │    auto-syncs pods  │
   │                          │                           │         ✓           │
```

### Pipeline Stages

| Stage | What it does |
|-------|-------------|
| **Validate Tag** | Ensures the `TAG` parameter is provided (e.g., `v1.0.3`) |
| **Clone Repository** | Checks out the `main` branch from GitHub |
| **Build Docker Image** | Multi-stage Docker build with BuildKit caching for fast rebuilds |
| **Push to Registry** | Pushes versioned + `latest` tag to local registry (`localhost:5001`) |
| **Update Helm Values** | Updates `deploy/values.yaml` image tag and `deploy/Chart.yaml` appVersion |
| **Commit & Push** | Commits Helm changes to GitHub using PAT credentials, triggering ArgoCD |

---

## Local Infrastructure Setup

Everything runs locally using a Kind (Kubernetes in Docker) cluster:

| Component | Address | Purpose |
|-----------|---------|---------|
| **Kind Cluster** | `localhost:80` (NodePort 30080) | Runs the app in Kubernetes |
| **Jenkins** | `localhost:8081` | CI/CD pipeline server |
| **Docker Registry** | `localhost:5001` | Stores built Docker images |
| **Registry UI** | `localhost:5002` | Browse registry images |
| **ArgoCD** | `localhost:8080` (NodePort 30443) | GitOps controller, watches Helm chart |

### Prerequisites

- Docker Desktop with Kubernetes support
- [Kind](https://kind.sigs.k8s.io/) for local K8s clusters
- [kubectl](https://kubernetes.io/docs/tasks/tools/) for cluster management
- [Helm](https://helm.sh/) for chart management

---

## Project Structure

```
├── Jenkinsfile                  # Pipeline definition (6 stages)
├── Dockerfile                   # Multi-stage build with BuildKit caching
├── docker-compose.yml           # Alternative: standalone Docker deployment
├── deploy/                      # Helm chart for Kubernetes
│   ├── Chart.yaml               # Chart metadata + appVersion
│   ├── values.yaml              # Image tag, replicas, probes, resources
│   └── templates/
│       ├── deployment.yaml      # K8s Deployment (2 replicas, rolling update)
│       ├── service.yaml         # NodePort service on port 30080
│       ├── configmap.yaml       # Non-sensitive env vars
│       ├── _helpers.tpl         # Template helpers (labels, names)
│       └── NOTES.txt            # Post-install instructions
└── .git/hooks/
    └── pre-push                 # Auto-triggers Jenkins on tag push
```

---

## Helm Chart

The Helm chart in `deploy/` defines the Kubernetes deployment:

```yaml
# values.yaml (key settings)
replicaCount: 2

image:
  repository: localhost:5001/duolingo-clone
  tag: "1.0.3"            # Updated automatically by Jenkins
  pullPolicy: IfNotPresent

service:
  type: NodePort
  port: 80
  targetPort: 3000
  nodePort: 30080          # Accessible at localhost:80 via Kind port mapping

strategy:
  type: RollingUpdate       # Zero-downtime deployments
  rollingUpdate:
    maxUnavailable: 0
    maxSurge: 1

probes:
  liveness:
    path: /api/health
  readiness:
    path: /api/health
```

**Key features:**
- **Rolling updates** with zero downtime (`maxUnavailable: 0`)
- **Health checks** on `/api/health` for liveness and readiness
- **Non-root container** running as UID 1001
- **Resource limits** to prevent runaway memory/CPU usage

---

## Docker Build Optimization

The Dockerfile uses **BuildKit cache mounts** to dramatically speed up rebuilds:

```dockerfile
# npm cache persists across builds — packages don't re-download
RUN --mount=type=cache,target=/root/.npm \
  npm ci

# Next.js build cache persists — unchanged chunks skip recompilation
RUN --mount=type=cache,target=/app/.next/cache \
  npm run build
```

| Build | Time | Why |
|-------|------|-----|
| First build (cold) | ~17 min | Downloads all npm packages + full Next.js compile |
| Subsequent builds (cached) | ~3-4 min | BuildKit reuses npm store + Next.js build cache |
| No code changes | ~30 sec | Docker layer cache hits everything |

---

## Git Hook: Auto-Trigger on Tag Push

The `pre-push` hook at `.git/hooks/pre-push` detects version tag pushes and triggers Jenkins automatically:

```bash
# Flow:
git tag -a v1.0.3 -m "description"
git push origin v1.0.3
# → Hook detects refs/tags/v* pattern
# → Calls Jenkins API: /job/duolingo-clone-deploy/buildWithParameters?TAG=v1.0.3
# → Jenkins pipeline starts immediately
```

> **Note:** The hook uses the Jenkins remote trigger token (`duolingo-deploy-token`) configured in the job.

---

## How to Deploy a New Version

### 1. Make your code changes and commit

```bash
git add .
git commit -m "feat: your changes here"
git push origin main
```

### 2. Tag and push to deploy

```bash
git tag -a v1.1.0 -m "release: description of changes"
git push origin v1.1.0
```

The pipeline runs automatically. Monitor it at `http://localhost:8081/job/duolingo-clone-deploy/`.

### 3. Verify the deployment

```bash
# Check pods are running with new version
kubectl get pods -l app.kubernetes.io/name=duolingo-clone

# Check the image tag on running pods
kubectl describe pod -l app.kubernetes.io/name=duolingo-clone | grep Image:

# View app at
curl http://localhost
```

---

## Managing Tags

```bash
# List all tags with messages
git tag -n

# Show details of a specific release
git show v1.0.3

# See what changed between releases
git log v1.0.2..v1.0.3 --oneline

# List tags by date (newest first)
git tag -l --sort=-creatordate

# Delete a tag (local + remote)
git tag -d v1.0.3
git push origin --delete v1.0.3
```

---

## Jenkins Credentials

The pipeline uses a GitHub PAT stored as a Jenkins credential (`github-pat`) to push Helm chart updates back to the repository. To set this up:

1. Generate a [GitHub Personal Access Token](https://github.com/settings/tokens) with `repo` scope
2. In Jenkins (`localhost:8081`), go to **Manage Jenkins** > **Credentials** > **System** > **Global credentials**
3. Add a **Username with password** credential:
   - **ID:** `github-pat`
   - **Username:** your GitHub username
   - **Password:** your PAT

---

## Troubleshooting

| Issue | Fix |
|-------|-----|
| Jenkins can't access Docker | `docker exec -u root jenkins chgrp docker /var/run/docker.sock && chmod 660 /var/run/docker.sock` |
| `neon()` error during build | Ensure `.env` exists in Jenkins workspace with `DATABASE_URL` |
| Git push fails in pipeline | Check the `github-pat` credential is configured in Jenkins |
| ArgoCD not syncing | Check ArgoCD dashboard at `localhost:8080` and verify the app is watching the correct repo/path |
| Pods stuck in `CrashLoopBackOff` | Check logs: `kubectl logs -l app.kubernetes.io/name=duolingo-clone` |
| Registry push fails | Verify `kind-registry` container is running: `docker ps \| grep registry` |
