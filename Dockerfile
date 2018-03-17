FROM alpine:3.7 as builder

ARG FIVEM_NUM=507
ARG FIVEM_VER=507-1006eacd1951849fd9c9e25a3b813132389d794b
ARG DATA_VER=fefd22590476055a34c0a2245e3a522b62fc89e1

LABEL maintainer="Spritsail <fivem@spritsail.io>" \
      org.label-schema.vendor="Spritsail" \
      org.label-schema.name="FiveM" \
      org.label-schema.url="https://fivem.net" \
      org.label-schema.description="FiveM is a modification for Grand Theft Auto V enabling you to play multiplayer on customized dedicated servers." \
      org.label-schema.version=${FIVEM_NUM}

WORKDIR /output

RUN wget -O- http://runtime.fivem.net/artifacts/fivem/build_proot_linux/master/${FIVEM_VER}/fx.tar.xz \
        | tar xJ --strip-components=1 \
            --exclude alpine/dev --exclude alpine/proc \
            --exclude alpine/run --exclude alpine/sys \
 && mkdir -p /output/opt/cfx-server-data \
 && wget -O- http://github.com/citizenfx/cfx-server-data/archive/${DATA_VER}.tar.gz \
        | tar xz --strip-components=1 -C opt/cfx-server-data \
    \
 && apk -p $PWD add tini

ADD server.cfg opt/cfx-server-data

#================

FROM scratch

COPY --from=builder /output/ /

WORKDIR /config
EXPOSE 30120

ENV SERVER_ARGS=""

ENTRYPOINT \
    # Check if the directory is empty
    if ! find . -mindepth 1 | read; then \
      echo "Creating default configs, please configure appropriately and restart!"; \
      cp -r /opt/cfx-server-data/* /config; \
      RCON_PASS="${RCON_PASSWORD-$(tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c 16)}"; \ 
      sed -i "s/{RCON_PASS}/${RCON_PASS}/g" /config/server.cfg; \
      sed -i "s/{LICENSE_KEY}/${LICENSE_KEY:-<INSERT LICENSE KEY HERE>}/g" /config/server.cfg; \
      echo "Your RCON password is set to: ${RCON_PASS}"; \
      exit 0; \
    fi; \
    \
    set -ax; \
    exec /sbin/tini -- /opt/cfx-server/FXServer \
        +set citizen_dir /opt/cfx-server/citizen/ \
        +exec /config/server.cfg $0 $@
