#!/bin/bash
set -e

# Colors
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_step() {
  echo -e "\n${GREEN}==> $1${NC}"
}

print_warn() {
  echo -e "${YELLOW}$1${NC}"
}

echo -e "${GREEN}K3s Air-Gap Installer${NC}"

# Copy binaries and images
print_step "Setting up air-gap files..."
sudo mkdir -p /var/lib/rancher/k3s/agent/images/
sudo cp k3s-airgap-images-amd64.tar.zst /var/lib/rancher/k3s/agent/images/
sudo cp k3s /usr/local/bin/
sudo chmod +x /usr/local/bin/k3s
sudo chmod +x install-k3s.sh

# Ask if this is the first node
echo -ne "${YELLOW}Is this the first (cluster-init) server node? [y/n]: ${NC}"
read IS_FIRST

CONFIRMED=false

while [ "$CONFIRMED" = false ]; do
  if [[ "$IS_FIRST" =~ ^[Yy]$ ]]; then
    echo -ne "Enter node name (e.g., server01): "
    read NODE_NAME
    echo -ne "Enter node IP address (e.g., 172.29.26.231): "
    read NODE_IP

    echo -e "\n${YELLOW}==> Please verify your settings:${NC}"
    echo "   Role       : FIRST NODE (cluster-init)"
    echo "   Node Name  : $NODE_NAME"
    echo "   Node IP    : $NODE_IP"
  else
    echo -ne "Enter node name (e.g., server02): "
    read NODE_NAME
    echo -ne "Enter node IP address (e.g., 172.29.26.230): "
    read NODE_IP
    echo -ne "Enter server IP address (e.g., 172.29.26.231): "
    read SERVER_IP
    echo -ne "Enter cluster token (from first node): "
    read TOKEN
    echo -ne "Disable etcd on this node? [y/n]: "
    read DISABLE_ETCD

    echo -e "\n${YELLOW}==> Please verify your settings:${NC}"
    echo "   Role       : JOIN NODE"
    echo "   Node Name  : $NODE_NAME"
    echo "   Node IP    : $NODE_IP"
    echo "   Server IP  : $SERVER_IP"
    echo "   Token      : $TOKEN"
    echo "   Disable Etcd : $DISABLE_ETCD"
  fi

  echo -ne "${YELLOW}Are these correct? Press ENTER to continue or type 'no' to re-enter: ${NC}"
  read CONFIRM
  if [[ "$CONFIRM" =~ ^[Nn][Oo]?$ ]]; then
    CONFIRMED=false
    echo
    echo -ne "${YELLOW}Is this the first (cluster-init) server node? [y/n]: ${NC}"
    read IS_FIRST
  else
    CONFIRMED=true
  fi
done

# Now perform the install
if [[ "$IS_FIRST" =~ ^[Yy]$ ]]; then
  print_step "Installing first K3s server node: $NODE_NAME"

  sudo INSTALL_K3S_SKIP_DOWNLOAD=true \
  K3S_KUBECONFIG_MODE="644" \
  ./install-k3s.sh server \
  --docker \
  --node-name "$NODE_NAME" \
  --node-label "topology.kubernetes.io/zone=$NODE_NAME" \
  --cluster-init \
  --node-ip "$NODE_IP"

  print_step "✅ First node installation completed."
  print_warn "👉 Use the token from /var/lib/rancher/k3s/server/node-token for other nodes."

else
  print_step "Installing additional K3s server node: $NODE_NAME"

  DISABLE_ETCD_FLAG=""
  if [[ "$DISABLE_ETCD" =~ ^[Yy]$ ]]; then
    DISABLE_ETCD_FLAG="--disable-etcd"
    print_warn "⚠️  This node will NOT run etcd."
  fi

  sudo INSTALL_K3S_SKIP_DOWNLOAD=true \
  K3S_KUBECONFIG_MODE="644" \
  ./install-k3s.sh server \
  --docker \
  --node-name "$NODE_NAME" \
  --node-label "topology.kubernetes.io/zone=$NODE_NAME" \
  --server "https://$SERVER_IP:6443" \
  --token "$TOKEN" \
  --node-ip "$NODE_IP" \
  $DISABLE_ETCD_FLAG

  print_step "✅ Join node installation completed."
fi

