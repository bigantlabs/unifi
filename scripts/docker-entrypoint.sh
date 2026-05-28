#!/bin/bash
set -euo pipefail

UNIFI_HOME=/usr/lib/unifi
UNIFI_USER=unifi
UNIFI_GROUP=unifi

log() { printf '[entrypoint] %s\n' "$*"; }

if [[ "${DEBUG:-false}" == "true" ]]; then
    set -x
fi

# Align unifi user/group to PUID/PGID so bind-mounted volumes are writable.
if [[ "$(id -u "${UNIFI_USER}")" != "${PUID}" ]]; then
    log "setting ${UNIFI_USER} uid to ${PUID}"
    usermod -o -u "${PUID}" "${UNIFI_USER}"
fi
if [[ "$(getent group "${UNIFI_GROUP}" | cut -d: -f3)" != "${PGID}" ]]; then
    log "setting ${UNIFI_GROUP} gid to ${PGID}"
    groupmod -o -g "${PGID}" "${UNIFI_GROUP}"
fi

if [[ "${RUN_CHOWN:-true}" == "true" ]]; then
    log "chowning ${UNIFI_HOME} to ${UNIFI_USER}:${UNIFI_GROUP}"
    chown -R "${UNIFI_USER}:${UNIFI_GROUP}" \
        "${UNIFI_HOME}/cert" \
        "${UNIFI_HOME}/data" \
        "${UNIFI_HOME}/logs" \
        "${UNIFI_HOME}/work" 2>/dev/null || true
fi

# Grant the JVM ability to bind privileged ports (e.g. 443) without running as root.
if [[ "${BIND_PRIV:-false}" == "true" ]]; then
    log "granting cap_net_bind_service to java"
    JAVA_BIN=$(readlink -f "$(command -v java)")
    setcap 'cap_net_bind_service=+ep' "${JAVA_BIN}"
fi

if [[ "$1" != "unifi" ]]; then
    exec "$@"
fi

JVM_OPTS=( -Dunifi.datadir="${UNIFI_HOME}/data"
           -Dunifi.logdir="${UNIFI_HOME}/logs"
           -Dunifi.rundir="${UNIFI_HOME}/run"
           -Xmx"${JVM_MAX_HEAP_SIZE}" )

if [[ -n "${JVM_INIT_HEAP_SIZE:-}" ]]; then
    JVM_OPTS+=( -Xms"${JVM_INIT_HEAP_SIZE}" )
fi

if [[ -n "${JVM_EXTRA_OPTS:-}" ]]; then
    # shellcheck disable=SC2206
    JVM_OPTS+=( ${JVM_EXTRA_OPTS} )
fi

mkdir -p "${UNIFI_HOME}/run"
chown "${UNIFI_USER}:${UNIFI_GROUP}" "${UNIFI_HOME}/run"

cd "${UNIFI_HOME}"

CMD=( java "${JVM_OPTS[@]}" -jar "${UNIFI_HOME}/lib/ace.jar" start )

if [[ "${RUNAS_UID0:-false}" == "true" ]]; then
    log "starting unifi as root"
    exec "${CMD[@]}"
else
    log "starting unifi as ${UNIFI_USER}"
    exec setpriv --reuid="${UNIFI_USER}" --regid="${UNIFI_GROUP}" --init-groups "${CMD[@]}"
fi
