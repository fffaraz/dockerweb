#!/bin/bash
set -euxo pipefail

mkdir -p /home/webuser/log/apache
export PATH=$PATH:$HOME/.composer/vendor/bin

exec apache2-foreground
