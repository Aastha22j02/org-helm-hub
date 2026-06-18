et -e

print_step() {
	    echo -e "\n\033[1;32m==> $1\033[0m"
    }

    # 1. Extract Docker binary
    print_step "Extracting docker-27.4.1.tgz..."
    tar -xvzf docker-27.4.1.tgz

    # 2. Copy binaries to /usr/bin
    print_step "Copying Docker binaries to /usr/bin..."
    sudo cp docker/* /usr/bin/

    # 3. Create containerd.service
    print_step "Creating containerd.service..."
    sudo tee /etc/systemd/system/containerd.service > /dev/null << 'EOF'
[Unit]
Description=containerd container runtime
Documentation=https://containerd.io
After=network.target

[Service]
ExecStart=/usr/bin/containerd
Delegate=yes
KillMode=process
Restart=always
LimitNOFILE=1048576
LimitNPROC=1048576
LimitCORE=infinity

[Install]
WantedBy=multi-user.target
EOF

# 4. Create docker.service
print_step "Creating docker.service..."
sudo tee /etc/systemd/system/docker.service > /dev/null << 'EOF'
[Unit]
Description=Docker Application Container Engine
Documentation=https://docs.docker.com
After=network.target containerd.service
Requires=containerd.service

[Service]
ExecStart=/usr/bin/dockerd
ExecReload=/bin/kill -s HUP $MAINPID
LimitNOFILE=1048576
LimitNPROC=1048576
LimitCORE=infinity
TimeoutStartSec=0
Restart=on-failure
StartLimitBurst=3
StartLimitInterval=60s

[Install]
WantedBy=multi-user.target
EOF

# 5. Reload systemd and enable services
print_step "Reloading systemd daemon..."
sudo systemctl daemon-reload

print_step "Enabling containerd and docker services..."
sudo systemctl enable containerd
sudo systemctl enable docker

# 6. Start services
print_step "Starting containerd..."
sudo systemctl start containerd

print_step "Starting docker..."
sudo systemctl start docker

# 7. Check status
print_step "Checking containerd status..."
sudo systemctl status containerd --no-pager

print_step "Checking docker status..."
sudo systemctl status docker --no-pager

print_step "Docker installation complete!"
docker --version

