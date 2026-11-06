#!/bin/sh

# build the container image
podman build -t rocky9_podman_wsl -f Containerfile .

# Create the container without starting it
cid="$(podman create rocky9_podman_wsl /bin/true)"
# Cleanup the container image when exiting
trap 'podman rm -f "$cid" >/dev/null' EXIT

# Export the container image to be used in wsl
podman export -o rocky9_podman_wsl.tar "$cid"