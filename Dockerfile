ARG BASE_REGISTRY=registry1.dso.mil
ARG BASE_IMAGE=ironbank/redhat/ubi/ubi8
ARG BASE_TAG=8.6

# FROM statement must reference the base image using the three ARGs established
FROM itzg/minecraft-server:latest as builder

FROM ${BASE_REGISTRY}/${BASE_IMAGE}:${BASE_TAG}

RUN dnf install -y java-17-openjdk-headless freetype fontconfig dejavu-sans-fonts && \
    dnf -y upgrade && \
    dnf clean all && \
    rm -rf /var/cache/dnf

ENV LANG C.UTF-8
ENV JAVA_HOME /usr/lib/jvm/jre-17-openjdk
ENV PATH $JAVA_HOME/bin:$PATH

COPY --from=builder --chmod=755 /start* /
COPY --from=builder --chmod=755 /usr/local/bin/* /usr/local/bin/
COPY --from=builder --chmod=755 /health.sh /health.sh
COPY --from=builder --chmod=644 /image/log4j2.xml /image/log4j2.xml
COPY --from=builder --chmod=755 /auto /auto

RUN dos2unix /start* /auto/*

EXPOSE 25565 25575
ENTRYPOINT [ "/start" ]
HEALTHCHECK --start-period=1m --interval=5s --retries=24 CMD mc-health