FROM alpine:3.7 as builder

ARG FIVEM_VER=507-1006eacd1951849fd9c9e25a3b813132389d794b
ARG DATA_VER=fefd22590476055a34c0a2245e3a522b62fc89e1

WORKDIR /tmp

RUN mkdir -p /output \
 && apk add -U curl git \
 && curl https://runtime.fivem.net/artifacts/fivem/build_proot_linux/master/${FIVEM_VER}/fx.tar.xz | tar xJ \
 && cp -r /tmp/alpine/* /output \
 && git clone https://github.com/citizenfx/cfx-server-data.git /tmp/data \
 && cd /tmp/data \
 && git reset --hard ${DATA_VER} \
 && rm -rf /tmp/data/.git* \
 && cp -r /tmp/data /output/opt/cfx-server-data

ADD start.sh /output/

ADD server.cfg /output/opt/cfx-server-data

#================

FROM scratch

COPY --from=builder /output/ /

RUN apk add -U tini \
 && chmod +x /start.sh

WORKDIR /config

ENTRYPOINT ["/sbin/tini","--"]
CMD ["/start.sh"]

EXPOSE 30120
