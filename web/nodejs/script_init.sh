#!/bin/bash

# Requirements
addgroup webuser
adduser --disabled-password --no-create-home --shell /bin/bash --gecos "" --home /home/webuser --ingroup webuser webuser

npm i -g yarn
npm i -g pm2

# Clean up
rm /script_init.sh
