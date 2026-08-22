# DevOps Interview Solution

This repository contains my solution for the Kubernetes deployment and DevOps review exercise.

I kept the setup local with Kind and focused on the main areas of the exercise: Docker, Kubernetes, CI/CD, releases, versioning, and the review of the provided shell script and Kubernetes manifest.

No cloud infrastructure is required.

---

## Architecture

### CI / Release

```text
                          GitHub
                           |
                       git push
                           |
                           v
                +----------------------+
                |    GitHub Actions    |
                |         CI           |
                +----------------------+
                   |                |
                   v                v
             Docker build     K8s validation


                         git tag v1.0.0
                                |
                                v
                +----------------------+
                |    GitHub Actions    |
                |       Release        |
                +----------------------+
                           |
                           v
                         GHCR
                           |
                           v
              Versioned container image
              
### Local Kubernetes

```text
                  Docker Image
                       |
                       v
              +-------------------+
              |   Kind Cluster    |
              |                   |
              |  Control Plane    |
              |                   |
              |  +-------------+  |
              |  |   Worker 1  |  |
              |  |    Pod 1    |  |
              |  +-------------+  |
              |                   |
              |  +-------------+  |
              |  |   Worker 2  |  |
              |  |    Pod 2    |  |
              |  +-------------+  |
              |         |         |
              |         v         |
              |  +-------------+  |
              |  |  ClusterIP  |  |
              |  |   Service   |  |
              |  +-------------+  |
              +-------------------+
```

GitHub Actions handles CI and releases. Kind is used locally to run and test the application.

---

## Project Structure

```text
.
├── .github/
│   └── workflows/
│       ├── ci.yml
│       └── release.yml
├── app/
│   ├── Dockerfile
│   └── index.html
├── kind/
│   └── cluster.yaml
├── k8s/
│   └── nginx.yaml
├── shell/
│   └── script.sh
├── CHANGELOG.md
└── README.md
```

---

## Running Locally

Create the Kind cluster:

```bash
kind create cluster --config kind/cluster.yaml
```

Check the nodes:

```bash
kubectl get nodes
```

Build the application image:

```bash
docker build -t devops-interview-app:1.0.0 ./app
```

Load the image into Kind:

```bash
kind load docker-image devops-interview-app:1.0.0 --name devops-interview
```

Deploy the application:

```bash
kubectl apply -f k8s/nginx.yaml
```

Check the rollout:

```bash
kubectl rollout status deployment/devops-interview-app
```

For local access:

```bash
kubectl port-forward service/devops-interview-app 8080:80
```

Then:

```bash
curl http://localhost:8080
```

---

## Kubernetes

The Deployment runs two replicas and includes:

- Rolling update strategy
- Readiness and liveness probes
- CPU and memory requests/limits
- Versioned container image

The application is exposed through a `ClusterIP` Service.

I also tested Kubernetes self-healing by deleting a running Pod and verifying that a replacement was created.

The rolling update configuration is:

```yaml
strategy:
  type: RollingUpdate
  rollingUpdate:
    maxUnavailable: 0
    maxSurge: 1
```

---

## CI

The CI workflow is:

```text
.github/workflows/ci.yml
```

It runs on pushes and pull requests.

It currently:

1. Checks out the repository
2. Builds the Docker image
3. Validates the Kubernetes manifest with kubeconform

The CI job does not depend on the local Kind cluster.

---

## Release

The release workflow is:

```text
.github/workflows/release.yml
```

A release is triggered by a Semantic Versioning Git tag:

```bash
git tag v1.0.0
git push origin v1.0.0
```

The workflow builds the image, pushes the versioned image to GHCR, and creates a GitHub Release.

Example:

```text
ghcr.io/rohitison/devops-interview-app:1.0.0
```

I use versioned image tags rather than `latest` so that each release points to a specific image.

Release changes are documented in `CHANGELOG.md`.

---

## Review: Shell Script

The original `shell/script.sh` had several issues:

- Missing shebang
- Inconsistent variable names
- Incorrect variable expansion
- `LOG_FILE` / `LOGFILE` mismatch
- Incorrect logging destination
- No strict shell error handling

I changed it to use:

```bash
#!/usr/bin/env bash
set -euo pipefail
```

and timestamped logging with `printf`.

The main goals were to make the script fail fast and keep it easier to maintain.

---

## Review: Kubernetes Manifest

The original Kubernetes manifest had several issues:

- Deployment selector and Pod labels did not match
- Port configuration was inconsistent with the Nginx application
- Service configuration was incomplete
- Service selectors were incorrect/incomplete
- Image was not versioned
- No readiness probe
- No liveness probe
- No resource requests or limits
- No explicit rolling update strategy

I corrected these issues while keeping the manifest relatively simple.

One Kubernetes detail worth noting is that `containerPort` is metadata. Setting it to `8000` does not make Nginx listen on port `8000`; the actual problem was the mismatch between the declared port and the port used by the application.

---

## Design Decisions

### Why Kind?

The exercise requires a local Kubernetes cluster. Kind provides a simple multi-node Kubernetes environment using Docker.

### Why two replicas?

Two replicas allow basic redundancy, rolling updates, and self-healing to be demonstrated.

### Why ClusterIP?

The application does not need to be exposed outside the cluster for this exercise, so `ClusterIP` keeps the setup simple.

### Why versioned images?

Versioned image tags make releases easier to trace and reproduce than a mutable `latest` tag.

### Why separate CI and Release?

CI validates normal changes. A release only happens when a version tag is created.

### Why not Terraform or GitOps?

They were not required for this exercise. The cluster configuration and Kubernetes desired state are already stored declaratively in Git, so I kept the implementation focused rather than adding more tooling.