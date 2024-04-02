#!/usr/bin/env bash

set_vga_device_env() {
    # Check for proprietary nvidia driver and set correct device to use
    if [[ -f "/proc/driver/nvidia/version" ]]
    then
        VGA_DEVICE_FLAG="--gpus"
        VGA_DEVICE_VALUE="all"
    else
        VGA_DEVICE_FLAG="--device"
        VGA_DEVICE_VALUE="/dev/dri:/dev/dri"
    fi
}

run_zwift_image() {
    docker run -it \
        --name zwift \
        --privileged \
        -e DISPLAY=$DISPLAY \
        -v /tmp/.X11-unix:/tmp/.X11-unix \
        $VGA_DEVICE_FLAG $VGA_DEVICE_VALUE \
        "${IMAGE_TAG}:latest" "$1"
}

commit_zwift_image() {
    BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ')
    ZWIFT_VERSION=$(curl -s http://cdn.zwift.com/gameassets/Zwift_Updates_Root/Zwift_ver_cur.xml | grep -oP 'sversion="\K.*?(?=")' | cut -f 1 -d ' ')

    if [ "$1" = "update" ]
    then
        COMMIT_MSG="updated image to Zwift version $ZWIFT_VERSION"
    else
        COMMIT_MSG="built image for Zwift version $ZWIFT_VERSION"
    fi

    docker commit --change="LABEL org.opencontainers.image.created=$BUILD_DATE" \
        --change="LABEL org.opencontainers.image.version=$ZWIFT_VERSION" \
        --change='CMD [""]' \
        -m "$COMMIT_MSG" \
        zwift \
        "${IMAGE_TAG}:${ZWIFT_VERSION}"
    docker tag "${IMAGE_TAG}:${ZWIFT_VERSION}" "${IMAGE_TAG}:latest"
}

IMAGE_TAG=zwift-local
set_vga_device_env
