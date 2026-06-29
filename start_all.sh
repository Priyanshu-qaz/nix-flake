#!/usr/bin/env bash

set -e

# 1️⃣ Variables
CLUSTER_NAME="zipkin"
KIND_CONFIG="kind-config.yaml"
DAPR_BIN="$HOME/bin"
IMAGES=("core-service" "engagement-service" "interaction-service" "frontend-service")
YAMLS=("core-service.yaml" "core-deployment.yaml" "engagement-service.yaml" "engagement-deployment.yaml" "frontend-service.yaml" "frontend-deployment.yaml" "interaction-service.yaml" "interaction-deployment.yaml" "zipkin-deployment.yaml" "dapr-tracing.yaml")
PORT_FORWARD_CMDS=(
    "kubectl port-forward svc/dapr-dashboard 8080:8080 -n dapr-system"
    "kubectl port-forward svc/zipkin 9411:9411 -n observability"
)

# 2️⃣ Check if Kind cluster exists
if kind get clusters | grep -q "^${CLUSTER_NAME}$"; then
    echo "Kind cluster '${CLUSTER_NAME}' already exists."
else
    echo "Creating Kind cluster '${CLUSTER_NAME}'..."
    kind create cluster --name "$CLUSTER_NAME" --config "$KIND_CONFIG"
fi

# 3️⃣ Create namespaces if not exist
kubectl get ns dapr-system >/dev/null 2>&1 || kubectl create ns dapr-system
kubectl get ns observability >/dev/null 2>&1 || kubectl create ns observability

# 4️⃣ Install Dapr CLI if not exists
if ! command -v dapr &>/dev/null; then
    mkdir -p "$DAPR_BIN"
    curl -L https://github.com/dapr/cli/releases/download/v1.16.1/dapr_linux_amd64.tar.gz -o dapr.tar.gz
    tar -xvzf dapr.tar.gz -C "$DAPR_BIN"
    export PATH="$DAPR_BIN:$PATH"
fi

# 5️⃣ Initialize Dapr on Kubernetes if not initialized
if ! kubectl get ns | grep -q "dapr-system"; then
    dapr init -k
fi

# 6️⃣ Save Podman images to tar (skip if already exist)
for img in "${IMAGES[@]}"; do
    TAR_FILE="${img}.tar"
    if [ ! -f "$TAR_FILE" ]; then
        podman save -o "$TAR_FILE" "localhost/$img:local"
    fi
done

# 7️⃣ Load images into Kind cluster
for img in "${IMAGES[@]}"; do
    kind load image-archive "${img}.tar" --name "$CLUSTER_NAME"
done

# 8️⃣ Apply YAMLs
for yaml in "${YAMLS[@]}"; do
    kubectl apply -f "$yaml"
done

# 9️⃣ Port forwarding (run in background)
for cmd in "${PORT_FORWARD_CMDS[@]}"; do
    $cmd &
done

echo "✅ All setup complete. Dapr dashboard: http://localhost:8080, Zipkin: http://localhost:9411"

