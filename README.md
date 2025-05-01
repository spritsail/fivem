# docker-fivem-fexemu

This docker image allows you to run a server for FiveM, a modded GTA multiplayer program.
Upon first run, the configuration is generated in the host mount for the `/config` directory.
The container should be stopped so fivem can be configured to the user requirements in the `server.cfg`.

> [!NOTE]
> **This container represents one of the attempts to make FiveM Server run on ARM64 devices using FEX-Emu!**
> 
> References:
> - [FEX-Emu](https://github.com/FEX-Emu/FEX)
> - [deploying-a-fivem-server-in-ubuntu-on-aarch64-arm64-machine (forum.cfx.re)](https://forum.cfx.re/t/deploying-a-fivem-server-in-ubuntu-on-aarch64-arm64-machine/5185384)

> [!TIP]
> For AMD64 devices or VMs it is recommended to use a different Docker container image e.g. [spritsail/fivem](https://github.com/spritsail/fivem) although this container image also works on AMD64 devices and VMs.

> [!IMPORTANT]
> The Docker container must be built on the device to be executed (especially on ARM64) using, for example, Docker Build for FEX-Emu to work under Docker.
> Therefore, there is no container image on a Docker registry.

> [!WARNING]
> - Running it on an AMD64 device or VM is done without using FEX-Emu and therefore remains native.
> - RedM Frameworks that require the steam web api key may not work on ARM64 devices or VMs in combination with FEX-Emu.

> [!CAUTION]
> Only building and using on AMD64 and ARM64 is supported. 
> Architectures such as ARMv7 or other architectures are not supported with this image.

## License Key

A freely obtained license key is required to use this server, which should be declared as `$LICENSE_KEY`. A tutorial on how to obtain a license key can be found [here](https://forum.fivem.net/t/explained-how-to-make-add-a-server-key/56120).

## Usage

Use the `docker-compose` script provided if you wish to run a couchdb server with FiveM, else use the line below:

```sh
git clone https://github.com/LizenzFass78851/docker-fivem-fexemu docker-fivem-fexemu \
  cd docker-fivem-fexemu

docker build . -t docker-fivem-fexemu

docker run -d \
  --name FiveM \
  --restart=on-failure \
  -e LICENSE_KEY=<your-license-here> \
  -p 30120:30120 \
  -p 30120:30120/udp \
  -v /volumes/fivem:/config \
  -ti \
  docker-fivem-fexemu
```

_It is important that you use `interactive` and `pseudo-tty` options otherwise the container will crash on startup_
See [issue #3](https://github.com/spritsail/fivem/issues/3)

## Image tags

This image has two tags - a `latest` tag (the default), based on the most recent FiveM build, and a `stable` tag, based on the "optional" FiveM release. We do not provide an image based on the recommended FiveM release as it is typically too stale.

### Web UI (txAdmin)

The web UI can be enabled by not passing any `+exec` config to the FXServer binary. This can be achieved by setting the `NO_DEFAULT_CONFIG` environment variable (see below).

`txAdmin` stores it's configuration and database data in `/txData`, so a volume can be set up to persist this data:

```sh
git clone https://github.com/LizenzFass78851/docker-fivem-fexemu docker-fivem-fexemu \
  cd docker-fivem-fexemu

docker build . -t docker-fivem-fexemu

docker run -d \
  --name FiveM \
  --restart=on-failure \
  -e LICENSE_KEY=<your-license-here> \
  -p 30120:30120 \
  -p 30120:30120/udp \
  -p 40120:40120 \ # Allow txAdmin's webserver port to be accessible
  -v /volumes/fivem:/config \
  -v /volumes/txData:/txData \ # Can use a named volume as well -v txData:/txData \
  -ti \
  docker-fivem-fexemu
```

### Environment Variables

- `LICENSE_KEY` - This is a required variable for the license key needed to start the server.
- `RCON_PASSWORD` - A password to use for the RCON functionality of the fxserver. If not specified, a random 16 character password is assigned. This is only used upon creation of the default configs
- `NO_DEFAULT_CONFIG` - Optional. Set to any non-zero value to disable the default exec config. This is required for txAdmin.
- `NO_LICENSE_KEY` - Optional. Set to any non-zero length value to disable specifying the license key in the environment. Useful if your license key is in a config file.
- `NO_ONESYNC` - Optional. Set to any non-zero value to disable OneSync being added to the default configs.
