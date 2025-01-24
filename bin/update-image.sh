#!/usr/bin/env bash
set -x
set -e

source $(dirname "$(realpath "$0")")/common.sh

run_zwift_image update

commit_zwift_image update

# Remove container
docker rm zwift
