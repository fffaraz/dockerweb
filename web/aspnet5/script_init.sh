#!/bin/sh

# requirements
addgroup webuser
adduser --disabled-password --no-create-home --shell /bin/bash --gecos "" --home /home/webuser --ingroup webuser webuser

# https://hub.docker.com/r/microsoft/dotnet/
# https://hub.docker.com/r/microsoft/aspnetcore/
# https://hub.docker.com/r/microsoft/aspnetcore-build/

# clean up
rm /script_init.sh
