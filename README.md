# Wisecow — Containerized and Deployed on Kubernetes
This repository contains my solution for the AccuKnox DevOps Trainee practical assessment: containerizing and deploying the [Wisecow](https://github.com/nyrahul/wisecow) application on Kubernetes, with automated CI, plus a supporting DevOps health-check script.
## What's completed
**Problem Statement 1:**
- Dockerized the Wisecow app (see `Dockerfile`)
- Deployed to Kubernetes using a Deployment (2 replicas) and a Service (see `k8s/`)
- Verified the app is reachable and serving correct responses through the cluster
- Set up GitHub Actions CI (see `.github/workflows/ci-cd.yml`) that automatically builds and pushes the Docker image to GitHub Container Registry on every push to `main` — verified working (green build)
**Problem Statement 2:**
- Implemented and ran `scripts/app_health_checker.sh` against the live deployed service, confirming it returns HTTP 200 (UP), with timestamped logging
**Not completed (due to time constraints):**
- TLS/Ingress (Challenge Goal)
- Problem Statement 3 / KubeArmor zero-trust policy (Optional bonus)
## How I ran it
```bash
# Build
docker build -t wisecow:local .
# Push (to my own Docker Hub)
docker tag wisecow:local rakshith0103/wisecow:latest
docker push rakshith0103/wisecow:latest
# Create local cluster
kind create cluster --name wisecow-cluster
# Deploy
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
# Verify
kubectl get pods
kubectl port-forward svc/wisecow-service 8080:80
# In another terminal
curl --http1.0 http://localhost:8080
# Run health check script
bash scripts/app_health_checker.sh http://localhost:8080
```
## Notes / things I learned while building this
- The Dockerfile runs as a non-root user for security; this required explicitly chown-ing the /app directory so the app could create its named pipe.
- fortune-mod alone doesn't include actual quote data on Ubuntu — needed fortunes-min as well.
- The app doesn't set a Content-Length header, so HTTP/1.1 clients (like default curl) may hang waiting for the connection to close. Using --http1.0 avoids this.
- GHCR image tags must be lowercase — added a step to the GitHub Actions workflow to lowercase the repository name before tagging, since GitHub usernames can contain uppercase letters.
