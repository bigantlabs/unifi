FROM debian:bullseye-slim

ARG BUILD_DATE
ARG VCS_REF
ARG VERSION

LABEL \
    org.opencontainers.image.created="${BUILD_DATE}" \
    org.opencontainers.image.revision="${VCS_REF}" \
    org.opencontainers.image.version="${VERSION}" \
    org.opencontainers.image.title="unifi" \
    org.opencontainers.image.description="UniFi Network Controller" \
    org.opencontainers.image.source="https://github.com/bigantlabs/unifi"

ENV \
    BIND_PRIV=false \
    DEBIAN_FRONTEND=noninteractive \
    DEBUG=false \
    JVM_EXTRA_OPTS= \
    JVM_INIT_HEAP_SIZE= \
    JVM_MAX_HEAP_SIZE=1024M \
    PGID=999 \
    PUID=999 \
    RUN_CHOWN=true \
    RUNAS_UID0=false

WORKDIR /usr/lib/unifi

COPY scripts/docker-entrypoint.sh scripts/docker-healthcheck.sh /usr/local/bin/

RUN set -eux \
    && apt-get update \
    && apt-get -y --no-install-recommends install \
        apt-utils \
        ca-certificates \
        ca-certificates-java \
        curl \
        dirmngr \
        gnupg2 \
        tini \
    && apt-get -y --no-install-recommends install \
        openjdk-11-jre-headless \
    && curl -fsSL https://pgp.mongodb.com/server-5.0.asc \
        | gpg -o /usr/share/keyrings/mongodb-server-5.0.gpg --dearmor \
    && echo "deb [signed-by=/usr/share/keyrings/mongodb-server-5.0.gpg] http://repo.mongodb.org/apt/debian bullseye/mongodb-org/5.0 main" \
        > /etc/apt/sources.list.d/mongodb-org-5.0.list \
    && apt-get update \
    && apt-get -y --no-install-recommends install \
        mongodb-org-server \
    && curl -fsSL "https://dl.ui.com/unifi/${VERSION}/unifi_sysvinit_all.deb" -o "/tmp/unifi-${VERSION}.deb" \
    && apt-get -y --no-install-recommends install "/tmp/unifi-${VERSION}.deb" \
    && apt-get -y purge \
        apt-utils dirmngr gnupg2 \
    && apt-get -y autoremove --purge \
    && rm -rf \
        "/tmp/unifi-${VERSION}.deb" \
        /var/lib/apt/lists/* \
        /var/cache/apt/archives/*.deb \
    && chmod +x /usr/local/bin/docker-entrypoint.sh /usr/local/bin/docker-healthcheck.sh

EXPOSE 3478/udp 6789/tcp 8080/tcp 8443/tcp 8843/tcp 8880/tcp 10001/udp

VOLUME ["/usr/lib/unifi/cert", "/usr/lib/unifi/data", "/usr/lib/unifi/logs"]

HEALTHCHECK --start-period=5m --interval=30s --timeout=10s --retries=3 \
    CMD /usr/local/bin/docker-healthcheck.sh

ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/bin/docker-entrypoint.sh"]

CMD ["unifi"]
