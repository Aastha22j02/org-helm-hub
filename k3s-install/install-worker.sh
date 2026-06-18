#!/bin/bash

set -e

echo "====================================="
echo "K3S WORKER NODE INSTALLATION STARTED"
echo "====================================="

# =========================
# VARIABLES
# =========================

MASTER_IP="192.168.22.107"

NODE_TOKEN="K103aeb2b25cc7d271018c0615cf337159f05fd3c6af072e4a819433695438b9f89::server:0d7c2fca377c86a334f661a06a2e6751"

INSTALL_DIR="$HOME/INSTALLATION_K3S/k3s-install"

# =========================
# CLEAN OLD INSTALLATION
# =========================

echo "[INFO] Cleaning old K3s agent installation..."

sudo /usr/local/bin/k3s-agent-uninstall.sh 2>/dev/null || true

sudo rm -rf /etc/rancher
sudo rm -rf /var/lib/rancher
sudo rm -rf /var/lib/kubelet

# =========================
# MOVE TO INSTALL DIR
# =========================

echo "[INFO] Moving to installation directory..."

cd "$INSTALL_DIR"

# =========================
# COPY K3S BINARY
# =========================

echo "[INFO] Copying K3s binary..."

sudo cp k3s /usr/local/bin/k3s
sudo chmod +x /usr/local/bin/k3s

# =========================
# AIRGAP IMAGES
# =========================

echo "[INFO] Preparing airgap images..."

sudo mkdir -p /var/lib/rancher/k3s/agent/images

sudo cp k3s-airgap-images-amd64.tar.zst \
/var/lib/rancher/k3s/agent/images/

# =========================
# CONNECTIVITY CHECK
# =========================

echo "[INFO] Checking connectivity to master..."

nc -zv ${MASTER_IP} 6443

# =========================
# INSTALL WORKER NODE
# =========================

echo "[INFO] Installing worker node..."

sudo INSTALL_K3S_SKIP_DOWNLOAD=true \
K3S_URL="https://${MASTER_IP}:6443" \
K3S_TOKEN="${NODE_TOKEN}" \
INSTALL_K3S_EXEC="agent --node-name=dhs02" \
sh install-k3s.sh

# =========================
# WAIT FOR STARTUP
# =========================

echo "[INFO] Waiting for node startup..."

sleep 15

# =========================
# VERIFY SERVICE
# =========================

echo "[INFO] Checking k3s-agent service..."

sudo systemctl status k3s-agent --no-pager

echo "====================================="
echo "K3S WORKER NODE INSTALLATION COMPLETED"
echo "====================================="
