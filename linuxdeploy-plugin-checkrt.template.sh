#! /bin/bash

OFFSET=-1

if [ $OFFSET -le 0 ]; then
    echo "Please run ./generate-plugin-script.sh to build the linuxdeploy plugin script"
    exit 1
fi

script=$(readlink -f "$0")

show_usage() {
    echo "Usage: $script --appdir <path to AppDir>"
    echo
    echo "Creates or replaces AppRun in AppRun that decides whether to load a bundled libstdc++ or not"
}

APPDIR=

while [ "$1" != "" ]; do
    case "$1" in
        --plugin-api-version)
            echo "0"
            exit 0
            ;;
        --appdir)
            APPDIR="$2"
            shift
            shift
            ;;
        --help)
            show_usage
            exit 0
            ;;
        *)
            echo "Invalid argument: $1"
            echo
            show_usage
            exit 1
            ;;
    esac
done

if [ ! -d "$APPDIR" ]; then
    echo "No such directory: $APPDIR"
    exit 1
fi

pushd "$APPDIR" &>/dev/null

# extract files from appended tarball
echo "Extracting binaries"
dd if="$script" skip="$OFFSET" iflag=skip_bytes,count_bytes 2>/dev/null | tar -xz

# copy system libraries
for path in $(ldconfig -p | grep "libstdc++" | awk 'NR==1 {print $NF}') $(ldconfig -p | grep "libgcc_s" | awk 'NR==1 {print $NF}'); do
    if [ -e "$path" ]; then
        echo "Copying into AppDir: $path"
        mkdir -p usr/optional/$(basename "$path")
        cp "$path" usr/optional/$(basename "$path")
    fi
done

if [ -f AppRun ]; then
    rm AppRun
fi

# use patched AppRun
mv AppRun.sh AppRun

# leave AppDir
popd &>/dev/null

# important: exit before the appended tarball
exit
