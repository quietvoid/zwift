#!/bin/bash
set -e
set -x

ZWIFT_HOME="$HOME/.wine/drive_c/Program Files (x86)/Zwift"

function get_current_version() {
    CUR_FILENAME=$(cat Zwift_ver_cur_filename.txt)
    if grep -q sversion $CUR_FILENAME; then
        ZWIFT_VERSION_CURRENT=$(cat $CUR_FILENAME | grep -oP 'sversion="\K.*?(?=\s)' | cut -f 1 -d ' ')
    else
        # Basic install only, needs initial update
        ZWIFT_VERSION_CURRENT="0.0.0"
    fi
}

function get_latest_version() {
    ZWIFT_VERSION_LATEST=$(wget --quiet -O - http://cdn.zwift.com/gameassets/Zwift_Updates_Root/Zwift_ver_cur.xml | grep -oP 'sversion="\K.*?(?=")' | cut -f 1 -d ' ')
}

function wait_for_zwift_game_update() {
    echo "updating zwift..."
    get_current_version
    get_latest_version
    if [ "$ZWIFT_VERSION_CURRENT" = "$ZWIFT_VERSION_LATEST" ]
    then
        echo "already at latest version..."
        exit 0
    fi

    wine64 start ZwiftLauncher.exe SilentLaunch
    until [ "$ZWIFT_VERSION_CURRENT" = "$ZWIFT_VERSION_LATEST" ]
    do
        echo "updating in progress..."
        sleep 5
        get_current_version
    done

    echo "updating done, waiting 5 seconds..."
    sleep 5
}

mkdir -p "$ZWIFT_HOME"
cd "$ZWIFT_HOME"

if [ "$1" = "update" ]
then
    wait_for_zwift_game_update

    wineserver -k
    exit 0
fi

if [ ! "$(ls -A .)" ] # is directory empty?
then
    #install dotnet > 4.7.2
    winetricks --force --unattended dotnet48 win10

    # Setup config dir
    mkdir -p "$HOME/Zwift"
    sudo chown user:user "$HOME/Zwift"
    ln -s "$HOME/Zwift" "$HOME/.wine/drive_c/users/user/Documents/Zwift"

    #install zwift
    wget https://cdn.zwift.com/app/ZwiftSetup.exe
    wine64 ZwiftSetup.exe /SP- /VERYSILENT /SUPPRESSMSGBOXES /NORESTART /NOCANCEL
    sleep 30

    # Wait for Zwift to fully install and then restart container
    until ! pgrep ZwiftLauncher.exe
    do
        echo "updating in progress..."
        sleep 5
    done

    # Restart updates in background
    pkill ZwiftLauncher || true

    wait_for_zwift_game_update

    rm "$ZWIFT_HOME/ZwiftSetup.exe"
    rm -rf "$HOME/.wine/drive_c/users/user/Downloads/Zwift"
    rm -rf $HOME/.cache/wine*

    wineserver -k
    exit 0
fi

echo "starting zwift..."
cd "$ZWIFT_HOME"
wine64 start ZwiftLauncher.exe SilentLaunch

LAUNCHER_PID_HEX=$(winedbg --command "info proc" | grep -P "ZwiftLauncher.exe" | grep -oP "^\s\K.+?(?=\s)")
LAUNCHER_PID=$((16#$LAUNCHER_PID_HEX))

cd "$HOME"
if [[ -f "/home/user/Zwift/.zwift-credentials" ]]
then
    echo "authenticating with zwift..."
    wine64 start /d "$ZWIFT_HOME" runfromprocess-rs.exe $LAUNCHER_PID "$ZWIFT_HOME/ZwiftApp.exe" --token=$(zwift-auth)
else
    wine64 start /d "$ZWIFT_HOME" runfromprocess-rs.exe $LAUNCHER_PID "$ZWIFT_HOME/ZwiftApp.exe"
fi

sleep 3

until pgrep ZwiftApp.exe &> /dev/null
do
    echo "Waiting for zwift to start ..."
    sleep 1
done

echo "Killing uneccesary applications"
pkill ZwiftLauncher
pkill ZwiftWindowsCra

wineserver -w
