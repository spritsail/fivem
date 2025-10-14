ARG FIVEM_NUM=20944
ARG FIVEM_VER=20944-eaa15781d4695bd97b050d848e34aac3607c6696
ARG DATA_VER=0e7ba538339f7c1c26d0e689aa750a336576cf02

FROM spritsail/alpine:3.22 as builder

ARG FIVEM_VER
ARG DATA_VER

WORKDIR /output

RUN wget -O- https://runtime.fivem.net/artifacts/fivem/build_proot_linux/master/${FIVEM_VER}/fx.tar.xz \
        | tar xJ --strip-components=1 \
            --exclude alpine/dev --exclude alpine/proc \
            --exclude alpine/run --exclude alpine/sys \
 && mkdir -p /output/opt/cfx-server-data /output/usr/local/share \
 && wget -O- http://github.com/citizenfx/cfx-server-data/archive/${DATA_VER}.tar.gz \
        | tar xz --strip-components=1 -C opt/cfx-server-data \
    \
 && apk -p $PWD add tini

ADD server.cfg opt/cfx-server-data
ADD entrypoint usr/bin/entrypoint

RUN chmod +x /output/usr/bin/entrypoint

#================

FROM scratch

ARG FIVEM_VER
ARG FIVEM_NUM
ARG DATA_VER

LABEL org.opencontainers.image.authors="Spritsail <fivem@spritsail.io>" \
      org.opencontainers.image.vendor="Spritsail" \
      org.opencontainers.image.title="FiveM" \
      org.opencontainers.image.url="https://fivem.net" \
      org.opencontainers.image.description="FiveM is a modification for Grand Theft Auto V enabling you to play multiplayer on customized dedicated servers." \
      org.opencontainers.image.version=${FIVEM_NUM} \
      io.spritsail.version.fivem=${FIVEM_VER} \
      io.spritsail.version.fivem_data=${DATA_VER}

COPY --from=builder /output/ /

# Temporary to allow soft deprecation.
ENV NO_TXADMIN="DONTANSWERTHEPHONETOLESTERCREST"

WORKDIR /config
EXPOSE 30120

# Default to an empty CMD, so we can use it to add seperate args to the binary
CMD [""]

ENTRYPOINT ["/sbin/tini", "--", "/usr/bin/entrypoint"]
