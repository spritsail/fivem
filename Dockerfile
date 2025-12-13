ARG FIVEM_NUM=23918
ARG FIVEM_VER=23918-3ece3ade3e27ea03b4745de9a1c8f41ad8d0f0e6
ARG DATA_VER=0e7ba538339f7c1c26d0e689aa750a336576cf02

ARG FEX_VER=FEX-2512

ARG DEBIAN_FRONTEND=noninteractive

FROM ubuntu:22.04 AS main

RUN sed -E -i 's#http://[^[:space:]]*ubuntu\.com/ubuntu-ports#http://mirrors.dotsrc.org/ubuntu-ports#g' /etc/apt/sources.list \
&&  sed -E -i 's#http://[^[:space:]]*ubuntu\.com/ubuntu#http://mirrors.dotsrc.org/ubuntu#g'             /etc/apt/sources.list

# --------------------------------------------------------------------------------

FROM main AS fex-builder-amd64

FROM --platform=arm64 main AS fex-builder-arm64

ARG DEBIAN_FRONTEND

ARG FEX_VER

RUN apt update && apt install -y cmake \
    clang-13 llvm-13 nasm ninja-build pkg-config \
    libcap-dev libglfw3-dev libepoxy-dev python3-dev libsdl2-dev \
    python3 linux-headers-generic  \
    git qtbase5-dev qtdeclarative5-dev lld \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /FEX
ADD https://github.com/FEX-Emu/FEX.git#${FEX_VER} ./

ARG CC=clang-13
ARG CXX=clang++-13
RUN mkdir build \
    && cmake -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=Release -DUSE_LINKER=lld -DENABLE_LTO=True -DBUILD_TESTING=False -DENABLE_ASSERTIONS=False -G Ninja . \
    && ninja

WORKDIR /FEX/build

ARG TARGETARCH
FROM fex-builder-${TARGETARCH} AS fex-builder

# --------------------------------------------------------------------------------

FROM main AS fex-rootfs-amd64

FROM --platform=arm64 main AS fex-rootfs-arm64

ARG DEBIAN_FRONTEND

RUN apt-get update \
    && apt-get install -y jq curl squashfs-tools-ng \
    && rm -rf /var/lib/apt/lists/*

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
    && rm -rf /var/lib/apt/lists/* 

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
    && rm -rf /var/lib/apt/lists/*

COPY --from=fex-builder /FEX/Bin/* /usr/bin/
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
    && rm -rf /var/lib/apt/lists/*

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
