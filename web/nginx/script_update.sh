#!/bin/bash
set -euo pipefail

NORELOAD=0
[ $# -gt 0 ] && [ "$1" == "--no-reload" ] && NORELOAD=1
[ $# -gt 0 ] && [ "$1" == "--debug" ] && set -x

exit 0
