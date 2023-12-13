#!/usr/bin/zsh
set -e

function set_zwift_output {
	ZWIFT_OUTPUT=$(swaymsg -t get_outputs | jq -r '.[] | select(.name | startswith("HEADLESS")) | .name')
}

set_zwift_output
if [[ -z $ZWIFT_OUTPUT ]]; then
	swaymsg create_output
	set_zwift_output
fi

function zwift_cleanup {
	echo "Stopping zwift container"
	docker stop zwift || true
	swaymsg output $ZWIFT_OUTPUT unplug
}

trap zwift_cleanup INT QUIT TERM EXIT

zsh zwift.sh
sleep 5

swaymsg "[title=\"Zwift\"]" move output $ZWIFT_OUTPUT
sleep 1
swaymsg "[title=\"Zwift\"]" focus
swaymsg "[title=\"Zwift\"]" fullscreen

docker wait zwift
