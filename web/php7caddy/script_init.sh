#!/bin/bash
set -euxo pipefail

# clean up
rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
rm /script_init.sh
