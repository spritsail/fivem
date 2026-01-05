ARG FIVEM_NUM=23984
ARG FIVEM_VER=23984-1e340cbec9335a2cfcf2cbc239c179e6fd389082
ARG DATA_VER=0e7ba538339f7c1c26d0e689aa750a336576cf02

ARG FEX_VER=FEX-2512

ARG DEBIAN_FRONTEND=noninteractive

FROM ubuntu:22.04 AS main

RUN sed -E -i 's#http://[^[:space:]]*ubuntu\.com/ubuntu-ports#http://mirrors.dotsrc.org/ubuntu-ports#g' /etc/apt/sources.list \
&&  sed -E -i 's#http://[^[:space:]]*ubuntu\.com/ubuntu#http://mirrors.dotsrc.org/ubuntu#g'             /etc/apt/sources.list

# --------------------------------------------------------------------------------

FROM main AS fex-rootfs-amd64

FROM --platform=arm64 main AS fex-rootfs-arm64

ARG DEBIAN_FRONTEND

RUN apt-get update \
    && apt-get install -y jq curl squashfs-tools-ng \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /root/.fex-emu/RootFS/Ubuntu_22_04
ADD https://rootfs.fex-emu.gg/RootFS_links.json /tmp/RootFS_links.json
RUN curl -L "$(jq -r '.v1 | ."Ubuntu 22.04 (SquashFS)" | .URL' /tmp/RootFS_links.json)" -o /tmp/ubuntu.sqsh \
    && sqfs2tar /tmp/ubuntu.sqsh | tar -x -p --numeric-owner -C ./

WORKDIR /root/.fex-emu

RUN echo '{"Config":{"RootFS":"Ubuntu_22_04"}}' > ./Config.json

ARG TARGETARCH
FROM fex-rootfs-${TARGETARCH} AS fex-rootfs

# --------------------------------------------------------------------------------

FROM main AS fx-downloader

ARG DEBIAN_FRONTEND

ARG FIVEM_VER
ARG DATA_VER

RUN apt update \
    && apt install -y wget xz-utils \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /opt/cfx-server
ADD https://runtime.fivem.net/artifacts/fivem/build_proot_linux/master/${FIVEM_VER}/fx.tar.xz /tmp/fx.tar.xz
RUN tar xJ --strip-components=0 -C /opt/cfx-server -f /tmp/fx.tar.xz
WORKDIR /opt/cfx-server-data
ADD http://github.com/citizenfx/cfx-server-data/archive/${DATA_VER}.tar.gz /tmp/cfx-server-data.tar.gz
RUN tar xz --strip-components=1 -C /opt/cfx-server-data -f /tmp/cfx-server-data.tar.gz

ADD server.cfg /opt/cfx-server-data

# --------------------------------------------------------------------------------
FROM main AS base-amd64

FROM --platform=arm64 main AS base-arm64

ARG DEBIAN_FRONTEND

RUN apt update \
    && apt install -y --no-install-recommends \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    curl \
    gpg-agent \
    && apt-get clean \
    && add-apt-repository -y ppa:fex-emu/fex

RUN apt update \
    && apt install -y \
    curl \
    squashfuse \
    fuse3 \
    squashfs-tools \
    zenity \
    qml-module-qtquick-controls \
    qml-module-qtquick-controls2 \
    qml-module-qtquick-dialogs \
    libc6 \
    libgcc-s1 \
    libgl1 \
    libqt5core5a \
    libqt5gui5-gles \
    libqt5qml5 \
    libqt5quick5-gles \
    libqt5widgets5 \
    libstdc++6 \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

COPY --chmod=755 fex-installer.sh /usr/local/bin/fex-installer.sh
COPY --from=fex-rootfs /root/.fex-emu /root/.fex-emu

ARG TARGETARCH
FROM base-${TARGETARCH}

ARG DEBIAN_FRONTEND

ARG FIVEM_VER
ARG FIVEM_NUM
ARG DATA_VER

LABEL org.opencontainers.image.authors="" \
      org.opencontainers.image.vendor="LizenzFass78851" \
      org.opencontainers.image.title="FiveM" \
      org.opencontainers.image.url="https://fivem.net" \
      org.opencontainers.image.description="FiveM is a modification for Grand Theft Auto V enabling you to play multiplayer on customized dedicated servers." \
      org.opencontainers.image.version=${FIVEM_NUM} \
      io.spritsail.version.fivem=${FIVEM_VER} \
      io.spritsail.version.fivem_data=${DATA_VER}

RUN apt update \
    && apt install -y tini \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

COPY --from=fx-downloader /opt/cfx-server /opt/cfx-server
COPY --from=fx-downloader /opt/cfx-server-data /opt/cfx-server-data

RUN mkdir /txData \
    && ln -s /txData /opt/cfx-server/txData

ENV CFX_SERVER=/opt/cfx-server

ADD --chmod=755 entrypoint /usr/bin/entrypoint

WORKDIR /config
EXPOSE 30120

# Default to an empty CMD, so we can use it to add seperate args to the binary
CMD [""]

ENTRYPOINT ["tini", "--", "/usr/bin/entrypoint"]
STOPSIGNAL SIGKILL
