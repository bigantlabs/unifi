#!/bin/bash
set -euo pipefail

UNIFI_HOME=/usr/lib/unifi
UNIFI_USER=unifi
UNIFI_GROUP=unifi

log() { printf '[entrypoint] %s\n' "$*"; }
die() { printf '[entrypoint] FATAL: %s\n' "$*" >&2; exit 1; }

if [[ "${DEBUG:-false}" == "true" ]]; then
    set -x
fi

if [[ "$(id -u)" != "0" ]]; then
    die "must start as root to set PUID/PGID and chown volumes (currently uid $(id -u)). Remove any --user flag from your container config and let the entrypoint demote."
fi

log "starting as uid=$(id -u) gid=$(id -g), target PUID=${PUID} PGID=${PGID}"

if [[ "$(getent group "${UNIFI_GROUP}" | cut -d: -f3)" != "${PGID}" ]]; then
    log "setting ${UNIFI_GROUP} gid to ${PGID}"
    groupmod -o -g "${PGID}" "${UNIFI_GROUP}"
fi
if [[ "$(id -u "${UNIFI_USER}")" != "${PUID}" ]]; then
    log "setting ${UNIFI_USER} uid to ${PUID}"
    usermod -o -u "${PUID}" "${UNIFI_USER}"
fi

for dir in cert data logs run work; do
    target="$(readlink -f "${UNIFI_HOME}/${dir}" 2>/dev/null || echo "${UNIFI_HOME}/${dir}")"
    mkdir -p "${target}"
done

if [[ "${RUN_CHOWN:-true}" == "true" ]]; then
    log "chowning ${UNIFI_HOME} runtime dirs to ${PUID}:${PGID} (resolving symlinks)"
    for dir in cert data logs run work; do
        target="$(readlink -f "${UNIFI_HOME}/${dir}")"
        if ! chown -R "${PUID}:${PGID}" "${target}"; then
            die "chown of ${target} (from ${UNIFI_HOME}/${dir}) failed. Check that the bind-mount is writable and the container started as root."
        fi
    done
else
    log "RUN_CHOWN=false; skipping chown. Current ownership:"
    for dir in cert data logs run work; do
        ls -lad "$(readlink -f "${UNIFI_HOME}/${dir}")"
    done
fi

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

cd "${UNIFI_HOME}"

CMD=( java "${JVM_OPTS[@]}" -jar "${UNIFI_HOME}/lib/ace.jar" start )

if [[ "${RUNAS_UID0:-false}" == "true" ]]; then
    log "starting unifi as root"
    exec "${CMD[@]}"
else
    log "starting unifi as ${UNIFI_USER} (uid=${PUID} gid=${PGID})"
    exec setpriv --reuid="${UNIFI_USER}" --regid="${UNIFI_GROUP}" --init-groups "${CMD[@]}"
fi
