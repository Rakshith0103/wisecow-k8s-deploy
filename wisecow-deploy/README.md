# Wisecow — Containerized & Deployed on Kubernetes with CI/CD and TLS

This repository contains the solution for the AccuKnox DevOps Trainee practical
assessment: containerizing, deploying, and securing the
[Wisecow](https://github.com/nyrahul/wisecow) application on Kubernetes,
plus supporting DevOps scripts and an optional KubeArmor zero-trust policy.

## Repository structure

```
.
├── Dockerfile                       # Container image for wisecow
├── wisecow.sh                       # Original app entrypoint script
├── k8s/
│   ├── deployment.yaml              # Deployment manifest
│   ├── service.yaml                 # ClusterIP Service
│   ├── ingress.yaml                 # Ingress with TLS termination
│   └── generate-tls-secret.sh       # Helper: self-signed cert + k8s TLS secret
├── .github/workflows/ci-cd.yml      # CI: build & push image; CD: deploy to cluster
├── scripts/
│   ├── system_health_monitor.sh     # PS2: CPU / memory / disk / process monitor
│   └── app_health_checker.sh        # PS2: HTTP-based app up/down checker
└── kubearmor/
    └── wisecow-policy.yaml          # PS3 (optional): zero-trust runtime policy
```

## Part 1 — Containerization & Kubernetes Deployment

### Build and test the image locally

```bash
docker build -t wisecow:local .
docker run -p 4499:4499 wisecow:local
curl http://localhost:4499
```

### Deploy to a local cluster (Kind or Minikube)

```bash
# 1. Push the image to a registry your cluster can pull from
docker tag wisecow:local <DOCKERHUB_USERNAME>/wisecow:latest
docker push <DOCKERHUB_USERNAME>/wisecow:latest

# 2. Update the image reference in k8s/deployment.yaml to match, then apply:
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml

# 3. (Kind only) make sure an ingress controller is installed, e.g.:
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

# 4. Generate the self-signed TLS cert + secret, then apply the Ingress:
cd k8s && ./generate-tls-secret.sh && cd ..
kubectl apply -f k8s/ingress.yaml

# 5. Point wisecow.local at your cluster and test over HTTPS:
echo "127.0.0.1 wisecow.local" | sudo tee -a /etc/hosts
curl -k https://wisecow.local
```

## Part 2 — CI/CD (`.github/workflows/ci-cd.yml`)

- **CI**: On every push to `main`, the workflow builds the Docker image and
  pushes it to GitHub Container Registry (`ghcr.io/<owner>/<repo>`), tagged
  both `latest` and with the commit SHA.
- **CD**: A second job updates the running Kubernetes Deployment to the newly
  built image via `kubectl set image`, using a `KUBE_CONFIG` repository
  secret (base64-encoded kubeconfig). This requires the cluster to be
  reachable from GitHub's runners — for a purely local Kind/Minikube setup,
  either use a self-hosted runner or run the `kubectl set image` step
  manually after each build.

## Part 3 — DevOps Scripts (`scripts/`)

**`system_health_monitor.sh`** — checks CPU, memory, disk usage, and running
process count against configurable thresholds; logs an alert to console and
`system_health_monitor.log` when any threshold is exceeded.

```bash
./scripts/system_health_monitor.sh
```

**`app_health_checker.sh`** — checks whether a target URL is responding with
a healthy HTTP status, with retries and logging. Can be pointed directly at
the deployed Wisecow service:

```bash
./scripts/app_health_checker.sh https://wisecow.local
```

## Part 4 — Zero-Trust KubeArmor Policy (optional, `kubearmor/`)

`wisecow-policy.yaml` restricts the wisecow pod to only the processes it
actually needs (`wisecow.sh`, `cowsay`, `fortune`, `nc`) and blocks common
lateral-movement tools (`apt`, `curl`, `wget`, `python3`, `perl`) plus writes
to sensitive paths (`/etc`, `/root`).

```bash
# Requires KubeArmor installed on the cluster:
# https://docs.kubearmor.io/kubearmor/quick-links/deployment_guide

kubectl apply -f kubearmor/wisecow-policy.yaml

# Trigger a violation to capture for the assignment, e.g.:
kubectl exec -it <wisecow-pod> -- curl https://example.com
# Screenshot the resulting KubeArmor alert/violation log.
```
