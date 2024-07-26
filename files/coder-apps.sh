#!/usr/bin/bash

# VS Code Server - install latest code-server
curl -fsSL https://code-server.dev/install.sh | sh -s -- --method=standalone --prefix=/usr/local/code-server

# JupyerLab
apt update -y 
DEBIAN_FRONTEND=noninteractive apt install -y python3-pip
rm -rf /var/lib/apt/lists/* 
pip3 install jupyterlab --break-system-packages
