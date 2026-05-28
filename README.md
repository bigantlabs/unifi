[![Build](https://github.com/bigantlabs/unifi/actions/workflows/build.yml/badge.svg)](https://github.com/bigantlabs/unifi/actions/workflows/build.yml)
[![Release](https://img.shields.io/github/v/release/bigantlabs/unifi?sort=semver)](https://github.com/bigantlabs/unifi/releases)
[![Image](https://ghcr-badge.egpl.dev/bigantlabs/unifi/latest_tag?trim=major&label=ghcr)](https://github.com/bigantlabs/unifi/pkgs/container/unifi)
[![Size](https://ghcr-badge.egpl.dev/bigantlabs/unifi/size)](https://github.com/bigantlabs/unifi/pkgs/container/unifi)

# UniFi Controller

UniFi Network Controller image for managing UniFi access points.

The UniFi version this image builds is tracked in [`VERSION`](./VERSION).

## Pull

Latest build from `master`:

```bash
docker pull ghcr.io/bigantlabs/unifi:latest
```

Pin to a specific UniFi version:

```bash
docker pull ghcr.io/bigantlabs/unifi:$(cat VERSION)
```

## Releasing a new UniFi version

1. Bump [`VERSION`](./VERSION) (e.g. `7.4.156` → `7.4.158`).
2. Open a PR. CI builds the image but does not push.
3. Merge to `master`. CI publishes `:<version>`, `:latest`, and `:sha-<short>` to GHCR.
4. Optionally cut a release: `git tag v$(cat VERSION) && git push --tags`.
