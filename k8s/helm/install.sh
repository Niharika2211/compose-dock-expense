#!/bin/bash
install_or_upgrade() {
    RELEASE_NAME=$1
    CHART_PATH=$2
    VALUES_FILE=$3
    NAMESPACE=$4

    if helm list -n "$NAMESPACE" | grep -q "^$RELEASE_NAME"; then
        echo "Upgrading $RELEASE_NAME..."
        helm upgrade "$RELEASE_NAME" "$CHART_PATH" -f "$VALUES_FILE" -n "$NAMESPACE"
    else
        echo "Installing $RELEASE_NAME..."
        helm install "$RELEASE_NAME" "$CHART_PATH" -f "$VALUES_FILE" -n "$NAMESPACE"
    fi
}

NAMESPACE="expense"

install_or_upgrade "backend" "." "dev/backend.yaml" "$NAMESPACE"
install_or_upgrade "frontend" "." "dev/frontend.yaml" "$NAMESPACE"
