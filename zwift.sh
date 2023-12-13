#!/usr/bin/env bash
set -x
set -e

SCRIPT_DIR=$(dirname "$(realpath "$0")")
source $SCRIPT_DIR/bin/common.sh

# The container version
VERSION=${VERSION:-latest}

set_vga_device_env

# Use podman if available
if [[ ! $CONTAINER_TOOL ]]
then
    if [[ -x "$(command -v podman)" ]]
    then
        CONTAINER_TOOL=podman
    else
        CONTAINER_TOOL=docker
    fi
fi

# Start the zwift container
CONTAINER=$($CONTAINER_TOOL run \
    -d \
    --rm \
    --privileged \
    --name zwift \
    -e DISPLAY=$DISPLAY \
    -v /tmp/.X11-unix:/tmp/.X11-unix \
    -v /run/user/$UID/pulse:/run/user/1000/pulse \
    -v zwift-config:/home/user/Zwift \
    $([ "$CONTAINER_TOOL" = "podman" ] && echo '--userns=keep-id') \
    $VGA_DEVICE_FLAG $VGA_DEVICE_VALUE \
    "${IMAGE_TAG}:$VERSION")

if [[ -z $WAYLAND_DISPLAY ]]
then
    # Allow container to connect to X
    xhost +local:$($CONTAINER_TOOL inspect --format='{{ .Config.Hostname  }}' $CONTAINER)
fi
