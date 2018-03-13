#!/bin/sh

SERVER_ARGS=$SERVER_ARGS:"+exec /config/server.cfg"

if [ ! -d /config ]; then
  echo "Config directory not found, please mount!"
  exit 1
fi

# Check if the directory is empty
if [ ! "$(ls -A /config)" ]; then
  echo "Creating default configs, please add a licence key and restart!"
  cp -r /opt/cfx-server-data/* /config
  exit 1
fi

cd /opt/cfx-server

if [ ! -d cache ]; then
  mkdir cache
fi

exec /opt/cfx-server/FXServer $SERVER_ARGS $*
