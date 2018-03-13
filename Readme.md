# Docker-FiveM

This docker image allows you to run a server for FiveM, a modded GTA multiplayer program.

## Licence Key

A free licence key is required to use this server, placed in server.cfg. A tutorial on how to generate a licence key can be found [here](https://forum.fivem.net/t/explained-how-to-make-add-a-server-key/56120)

## Example run line

Use the docker-compose script provided if you wish to run a couchdb server with FiveM, else use the line below:

`docker run -d --name FiveM -p 30120:30120 -v /volumes/fivem:/config adamant/fivem`

