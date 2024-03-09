#!/bin/bash
set -e
set -x

ZWIFT_HOME="$HOME/.wine/drive_c/Program Files (x86)/Zwift"
WINE_USER_HOME="$HOME/.wine/drive_c/users/user"

# DISPLAY=
# wine regedit /S wayland.reg

function get_current_version() {
    if [ -f Zwift_ver_cur_filename.txt ]; then
        # If Zwift_ver_cur_filename.txt exists, use it
        CUR_FILENAME=$(cat Zwift_ver_cur_filename.txt)
    else
        # Default to Zwift_ver_cur.xml if Zwift_ver_cur_filename.txt doesn't exist
        CUR_FILENAME="Zwift_ver_cur.xml"
    fi

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
    cd "${ZWIFT_HOME}"
    get_current_version
    get_latest_version
    if [ "$ZWIFT_VERSION_CURRENT" = "$ZWIFT_VERSION_LATEST" ]
    then
        echo "already at latest version..."
        exit 0
    fi

    wine64 ZwiftLauncher.exe SilentLaunch &
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
    # Setup config dir
    mkdir -p "$HOME/Zwift"
    sudo chown user:user "$HOME/Zwift"

    # Setup wine prefix
    wineboot -i
    ln -s "$HOME/Zwift" "$HOME/.wine/drive_c/users/user/Documents/Zwift"

    # install dotnet and zwift
    winetricks -q dotnet48 /home/user/zwift.verb

    # update game through zwift launcher
    wait_for_zwift_game_update

    rm "$ZWIFT_HOME/ZwiftSetup.exe"
    rm -rf "$HOME/.wine/drive_c/users/user/Downloads/Zwift"
    rm -rf $HOME/.cache/wine*

    wineserver -k
    # cleanup
    rm -rf "$ZWIFT_HOME"/{ZwiftSetup.exe,VC_redist.x64.exe}
    rm -rf "$WINE_USER_HOME/Downloads/Zwift"
    rm -rf "$WINE_USER_HOME/AppData/Local/Microsoft"
    rm -rf "$HOME"/.cache/wine*

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

until pgrep -f ZwiftApp.exe &> /dev/null
do
    echo "Waiting for zwift to start ..."
    sleep 1
done

echo "Killing uneccesary applications"
pkill ZwiftLauncher
pkill ZwiftWindowsCra

wineserver -w
