#!/bin/bash

# requirements
addgroup webuser
adduser --disabled-password --no-create-home --shell /bin/bash --gecos "" --home /home/webuser --ingroup webuser webuser

# clean up
rm /script_init.sh
