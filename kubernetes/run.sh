#!/usr/bin/env bash
# Create Jenkins service account + RBAC and fetch token (idempotent)

set -euo pipefail

NAMESPACE="${1:-jenkins}"          # Pass namespace as first arg (default: jenkins)
SA_NAME="${SA_NAME:-jenkins}"      # Override via env if needed
ROLE_FILES=(jenkins-pipeline-role.yaml jenkins-pipeline-rolebinding.yaml jenkins-pipeline-cluster-role-binding.yaml)  # Add cluster role binding file
KUBECTL="${KUBECTL:-kubectl}"
TOKEN_OUT="${TOKEN_OUT:-${SA_NAME}.token}"
CERT_OUT="${CERT_OUT:-k8s-server.crt}"  # Output file for Kubernetes server certificate

log() { printf '[%s] %s\n' "$(date +'%Y-%m-%dT%H:%M:%S')" "$*"; }
need() { command -v "$1" >/dev/null || { echo "Missing command: $1" >&2; exit 1; }; }
run() { log "$*"; "$@"; }

need "$KUBECTL"

# ========================================
# Create Namespace if doesn't exist
# ========================================
log "----------------------------------------"
log "Checking if namespace '$NAMESPACE' exists..."
if ! $KUBECTL get ns "$NAMESPACE" >/dev/null 2>&1; then
    run $KUBECTL create namespace "$NAMESPACE"
    log "Namespace '$NAMESPACE' created."
else
    log "Namespace '$NAMESPACE' already exists."
fi

# ========================================
# Create ServiceAccount if doesn't exist
# ========================================
log "----------------------------------------"
log "Checking if ServiceAccount '$SA_NAME' exists in namespace '$NAMESPACE'..."
if ! $KUBECTL -n "$NAMESPACE" get sa "$SA_NAME" >/dev/null 2>&1; then
    run $KUBECTL -n "$NAMESPACE" create serviceaccount "$SA_NAME"
    log "ServiceAccount '$SA_NAME' created."
else
    log "ServiceAccount '$SA_NAME' already exists."
fi

# ========================================
# Apply RBAC manifests (Role, RoleBinding, ClusterRoleBinding)
# ========================================
log "----------------------------------------"
log "Applying RBAC roles from the following files: ${ROLE_FILES[*]}"
for f in "${ROLE_FILES[@]}"; do
    if [[ -f $f ]]; then
        run $KUBECTL -n "$NAMESPACE" apply -f "$f"
        log "Applied RBAC manifest: $f"
    else
        log "Skipping missing file: $f"
    fi
done

# ========================================
# Token Generation
# ========================================
log "----------------------------------------"
log "Generating token for ServiceAccount '$SA_NAME'..."

if TOKEN="$($KUBECTL -n "$NAMESPACE" create token "$SA_NAME" 2>/dev/null)"; then
    log "Token successfully generated."
else
    log "Token creation failed; falling back to legacy secret method..."
    SECRET="$($KUBECTL -n "$NAMESPACE" get sa "$SA_NAME" -o jsonpath='{.secrets[0].name}')"
    TOKEN="$($KUBECTL -n "$NAMESPACE" get secret "$SECRET" -o jsonpath='{.data.token}' | base64 --decode)"
    log "Token retrieved using legacy method."
fi

# ========================================
# Write token to file
# ========================================
printf '%s\n' "$TOKEN" > "$TOKEN_OUT"
log "Token written to file: $TOKEN_OUT"

# ========================================
# Optionally show the full token
# ========================================
SHOW_TOKEN="${SHOW_TOKEN:-0}"   # set SHOW_TOKEN=1 or pass --show-token to print token
for arg in "$@"; do
    [[ $arg == --show-token ]] && SHOW_TOKEN=1
done

# ========================================
# Display Token Information
# ========================================
log "----------------------------------------"
log "Jenkins ServiceAccount provisioning summary:"
log "  Namespace:        $NAMESPACE"
log "  ServiceAccount:   $SA_NAME"
log "  Token file:       $TOKEN_OUT"
log "  Role manifests:   ${ROLE_FILES[*]}"

if [[ $SHOW_TOKEN == 1 ]]; then
    log "  Token (full):"
    printf '%s\n' "$TOKEN"
else
    log "  Token preview:   ${TOKEN:0:8}... (set SHOW_TOKEN=1 or pass --show-token to print full token)"
fi

# ========================================
# Fetch Kubernetes API server certificate from kubeconfig
# ========================================
log "----------------------------------------"
log "Fetching Kubernetes API server certificate from kubeconfig..."

CA_CERT="$($KUBECTL config view --raw -o jsonpath='{.clusters[0].cluster.certificate-authority-data}')"

# Check if CA cert exists and write it to file
if [[ -n "$CA_CERT" ]]; then
    echo "$CA_CERT" | base64 -d  > "$CERT_OUT"
    log "Kubernetes server certificate written to: $CERT_OUT"
else
    log "Failed to retrieve Kubernetes server certificate."
fi
