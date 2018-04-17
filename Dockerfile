ARG FIVEM_NUM=583
ARG FIVEM_VER=583-20ed388d15481e5c0425c8e203778ad65726eb8b
ARG DATA_VER=7bb81573f1b2bd8a9505860529b87be4dc001dc8

FROM alpine:3.7 as builder

ARG FIVEM_VER
ARG DATA_VER

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

ARG FIVEM_VER
ARG FIVEM_NUM

LABEL maintainer="Spritsail <fivem@spritsail.io>" \
      org.label-schema.vendor="Spritsail" \
      org.label-schema.name="FiveM" \
      org.label-schema.url="https://fivem.net" \
      org.label-schema.description="FiveM is a modification for Grand Theft Auto V enabling you to play multiplayer on customized dedicated servers." \
      io.spritsail.version.fivem=${FIVEM_VER} \
      org.label-schema.version=${FIVEM_NUM}

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
