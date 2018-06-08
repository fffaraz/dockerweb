#!/bin/bash
set -euxo pipefail

export DEBIAN_FRONTEND=noninteractive
apt update
apt -y upgrade
apt -y install bash nano wget

# Clean up
rm -rf /var/lib/apt/lists/*
rm /script_init.sh
exit 0
