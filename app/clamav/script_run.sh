#!/bin/bash
set -euxo pipefail

freshclam
clamscan -V

# --move=/home/USER/VIRUS
clamscan -r -i /home
