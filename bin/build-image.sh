#!/usr/bin/env bash
set -x
set -e

SCRIPT_DIR=$(dirname "$(realpath "$0")")
source $SCRIPT_DIR/common.sh

docker build -t $IMAGE_TAG "$SCRIPT_DIR/image"
run_zwift_image

commit_zwift_image

# Remove container
docker rm zwift
