#!/bin/bash

set -e

GREEN='\033[1;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No color

print_step() {
  echo -e "${GREEN}==> $1${NC}"
}

print_warn() {
  echo -e "${YELLOW}$1${NC}"
}

TAR_FILE="helm-v3.16.4-linux-amd64.tar.gz"
DIR_NAME="linux-amd64"

if [[ ! -f "$TAR_FILE" ]]; then
  print_warn "Error: File $TAR_FILE not found in current directory."
  exit 1
fi

# 1. Extract archive
print_step "Extracting $TAR_FILE..."
tar -xzf "$TAR_FILE"

# 2. Move helm binary
print_step "Moving helm binary to /usr/local/bin..."
sudo cp "$DIR_NAME/helm" /usr/local/bin/
sudo chmod +x /usr/local/bin/helm

# 3. Clean up
print_step "Cleaning up temporary files..."
rm -rf "$DIR_NAME"

# 4. Verify
print_step "Verifying Helm installation..."
helm version

print_step "✅ Helm installed successfully!"

