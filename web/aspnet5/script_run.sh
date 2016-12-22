#!/bin/bash

mkdir -p /home/webuser/www
[[ -f /home/webuser/project.sh ]] && source /home/webuser/project.sh
[[ ! -f /home/webuser/www/project.json ]] && echo '
{
    "version": "1.0.0-*",
    "webroot": "wwwroot",
    "exclude": [
        "wwwroot"
    ],
    "packExclude": [
        "**.kproj",
        "**.user",
        "**.vspscc"
    ],
    "dependencies": {
        "Microsoft.AspNet.Server.Kestrel": "1.0.0-rc1-final",
        "Microsoft.AspNet.IISPlatformHandler": "1.0.0-rc1-final",
        "Microsoft.AspNet.Diagnostics": "1.0.0-rc1-final",
        "Microsoft.AspNet.Hosting": "1.0.0-rc1-final",
        "Microsoft.AspNet.StaticFiles": "1.0.0-rc1-final",
        "Microsoft.Extensions.Logging.Console": "1.0.0-rc1-final"
    },
    "commands": {
        "web": "Microsoft.AspNet.Server.Kestrel --server.urls http://*:80"
    },
    "frameworks": {
        "dnx451": { },
        "dnxcore50": { }
    }
}
' > /home/webuser/www/project.json

chown -R webuser:webuser /home/webuser

cd /home/webuser/www
dotnet restore
dotnet build
exec dotnet run -p project.json web --server.urls http://0.0.0.0:80

#dotnet publish -c Release -o ./bin/Release/PublishOutput
#dotnet ./bin/Release/PublishOutput/myapp.dll
