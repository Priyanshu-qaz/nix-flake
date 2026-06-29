#!/bin/bash
set -e

echo "==== Step 1: Creating KIND cluster ===="
kind create cluster --name zipkin --config kind-config.yaml || {
    echo "Cluster already exists. Continuing..."
}

echo "==== Step 2: Checking clusters ===="
kind get clusters
kubectl get nodes

echo "==== Step 3: Creating namespaces ===="
kubectl create namespace dapr-system --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace observability --dry-run=client -o yaml | kubectl apply -f -

echo "==== Step 4: Initializing Dapr ===="
dapr init -k
kubectl get pods -n dapr-system

echo "==== Step 5: Removing old images ===="
rm -f core-service.tar engagement-service.tar interaction-service.tar frontend-service.tar

echo "==== Step 6: Retagging ALL images for KIND (AUTOMATIC) ===="

# Function to tag image safely
tag_image() {
  local source_repo="$1"
  local target_repo="$2"

  if podman images --format "{{.Repository}}:{{.Tag}}" | grep -q "$source_repo:latest"; then
    echo "Tagging $source_repo:latest -> $target_repo:local"
    podman tag "$source_repo:latest" "$target_repo:local"
  else
    # If image has <none> tag, tag by image ID
    IMG_ID=$(podman images --format "{{.Repository}} {{.ID}}" | grep "$source_repo" | awk '{print $2}')
    if [ -n "$IMG_ID" ]; then
      echo "Tagging IMAGE ID $IMG_ID -> $target_repo:local"
      podman tag "$IMG_ID" "$target_repo:local"
    else
      echo "WARNING: Image $source_repo not found locally!"
    fi
  fi
}

# Tag all required images
tag_image "harbor.nbt.local/vizor/core-service" "localhost/core-service"
tag_image "harbor.nbt.local/vizor/engagement-service" "localhost/engagement-service"
tag_image "harbor.nbt.local/vizor/interaction-service" "localhost/interaction-service"
tag_image "harbor.nbt.local/vizor/frontend" "localhost/frontend"

echo "==== Step 7: Saving Podman images ===="
podman save -o core-service.tar localhost/core-service:local
podman save -o engagement-service.tar localhost/engagement-service:local
podman save -o interaction-service.tar localhost/interaction-service:local
podman save -o frontend-service.tar localhost/frontend:local

echo "==== Step 8: Loading images into KIND ===="
kind load image-archive core-service.tar --name zipkin
kind load image-archive engagement-service.tar --name zipkin
kind load image-archive interaction-service.tar --name zipkin
kind load image-archive frontend-service.tar --name zipkin

echo "==== Step 9: Deploying Core Service ===="
kubectl apply -f core-service.yaml
kubectl apply -f core-deployment.yaml

echo "==== Step 10: Deploying Engagement Service ===="
kubectl apply -f engagement-service.yaml
kubectl apply -f engagement-deployment.yaml

echo "==== Step 11: Deploying Frontend Service ===="
kubectl apply -f frontend-service.yaml
kubectl apply -f frontend-deployment.yaml

echo "==== Step 12: Deploying Interaction Service ===="
kubectl apply -f interaction-service.yaml
kubectl apply -f interaction-deployment.yaml

echo "==== Step 13: Deploying Dapr Tracing + Zipkin ===="
kubectl apply -f dapr-tracing.yaml
kubectl apply -f zipkin-deployment.yaml

echo "==== Step 14: Deploying RBAC + Secrets for Dapr ===="
kubectl apply -f dapr-rbac.yaml
kubectl apply -f kubernetes-secret-store.yaml
kubectl apply -f vizor-secrets.yaml

echo "==== Step 15: Cluster Status ===="
kubectl get pods -A
kubectl get svc -A

echo "==== Deployment Completed Successfully! ===="

