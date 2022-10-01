ARG BASE_REGISTRY=registry.hub.docker.com
ARG BASE_IMAGE=zarguell/ubi8
ARG BASE_TAG=latest

# FROM statement must reference the base image using the three ARGs established
FROM itzg/minecraft-server:latest as builder

FROM ${BASE_REGISTRY}/${BASE_IMAGE}:${BASE_TAG}

USER 0

RUN dnf install -y java-17-openjdk-headless freetype fontconfig dejavu-sans-fonts dos2unix && \
    dnf -y upgrade && \
    dnf clean all && \
    rm -rf /var/cache/dnf

ENV LANG C.UTF-8
ENV JAVA_HOME /usr/lib/jvm/jre-17-openjdk
ENV PATH $JAVA_HOME/bin:$PATH
ENV TYPE=VANILLA VERSION=LATEST EULA="" UID=1000 GID=1000 RCON_PASSWORD=minecraft

VOLUME ["/data"]
WORKDIR /data

STOPSIGNAL SIGTERM

COPY --from=builder --chmod=755 /start* /
COPY --from=builder --chmod=755 /data /data
COPY --from=builder --chmod=755 /usr/local/bin/* /usr/local/bin/
COPY --from=builder --chmod=755 /usr/bin/mc-image-helper /usr/local/bin/
COPY --from=builder --chmod=755 /usr/sbin/gosu /usr/local/bin
COPY --from=builder --chmod=755 /health.sh /health.sh
COPY --from=builder --chmod=644 /image/log4j2.xml /image/log4j2.xml
COPY --from=builder --chmod=755 /auto /auto

# RUN chown -R 1000:1000 /start* && \
#     chown -R 1000:1000 /usr/local/bin/ && \
#     chown -R 1000:1000 /health.sh && \
#     chown -R 1000:1000 /image/log4j2.xml && \
#     chown -R 1000:1000 /auto && \


RUN groupadd -g 1000 minecraft \
&& useradd -m -u 1000 -g minecraft minecraft
# USER 1000

RUN dos2unix /start* /auto/*

EXPOSE 25565 25575
ENTRYPOINT [ "/start" ]
HEALTHCHECK --start-period=1m --interval=5s --retries=24 CMD mc-health