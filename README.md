[![Build](https://github.com/bigantlabs/unifi/actions/workflows/build.yml/badge.svg)](https://github.com/bigantlabs/unifi/actions/workflows/build.yml)

# UniFi Network Application

Containerized UniFi Network Application (formerly UniFi Controller) for managing UniFi access points.

## Stack

| Component | Version |
|---|---|
| Base | Debian Bookworm (12) |
| JRE | Eclipse Temurin 25 (Adoptium) |
| MongoDB | 7.0 (LTS) |
| UniFi Network Application | Tracked in [`VERSION`](./VERSION) |

CPU must support **AVX** (Intel Sandy Bridge / AMD Bulldozer or newer) — MongoDB 7.0 requires it.

## Pull

Latest build from `master`:

```bash
docker pull ghcr.io/bigantlabs/unifi:latest
```

Pin to a specific UniFi version:

```bash
docker pull ghcr.io/bigantlabs/unifi:$(cat VERSION)
```

## Migrating from a UniFi 7.x image

The 10.x image bundles MongoDB 7.0, which is not an in-place upgrade from the Mongo 5.0 that 7.x images shipped. Migrate via UniFi's own backup/restore:

1. In the running UniFi 7.x web UI: **Settings → System → Backup → Download**. Save the `.unf` file somewhere outside the container's appdata folder.
2. Stop (don't remove) the current container:
   ```bash
   docker stop Unifi
   ```
3. Move the existing appdata aside as a safety net:
   ```bash
   mv /mnt/cache/appdata/unifi /mnt/cache/appdata/unifi.v7-backup
   mkdir /mnt/cache/appdata/unifi
   chown 99:100 /mnt/cache/appdata/unifi
   ```
4. Update your container to the new image (e.g. `ghcr.io/bigantlabs/unifi:10.4.57`) and start it. UniFi 10 boots against an empty data directory.
5. On first boot, UniFi's setup wizard offers **Restore from backup** — upload the `.unf` from step 1.
6. Verify APs reconnect and settings are intact. If healthy:
   ```bash
   rm -rf /mnt/cache/appdata/unifi.v7-backup
   ```
   If not, stop the new container, `mv` the backup directory back, and pin to your previous 7.x SHA tag for rollback.

> **Note:** UniFi officially supports `.unf` restore across two major versions. 7.x → 10.x is three majors; in practice it usually works, but if the restore fails, deploy an 8.x image (e.g. `:8.5.x`) as a one-time bridge, restore there, take a fresh backup, then upgrade to 10.x.

## Releasing a new UniFi version

1. Bump [`VERSION`](./VERSION) (e.g. `10.4.57` → `10.4.58`).
2. Open a PR. CI builds the image but does not push.
3. Merge to `master`. CI publishes `:<version>`, `:latest`, and `:sha-<short>` to GHCR.
4. Optionally cut a release: `git tag v$(cat VERSION) && git push --tags`.
