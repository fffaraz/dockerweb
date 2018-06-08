#!/bin/bash
set -euxo pipefail

apt update
apt -y install bash nano wget

# Clean up
rm -rf /var/lib/apt/lists/*
rm /script_init.sh
exit 0
