#!/bin/bash
set -euxo pipefail

exec nginx -g "daemon off;"
