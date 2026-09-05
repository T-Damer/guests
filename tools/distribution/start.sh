#!/bin/sh
# Launch the packaged Linux game from any working directory. No downloads/root.
set -eu
case "$(uname -s)" in
    Linux) ;;
    *) printf '%s\n' 'This package is for Linux. On macOS use GUESTS.app.' >&2; exit 1 ;;
esac
case "$(uname -m)" in
    x86_64|amd64) ;;
    *) printf '%s\n' 'This package requires an x86_64 Linux machine.' >&2; exit 1 ;;
esac
APP_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
if [ ! -f "$APP_DIR/guests.x86_64" ] || [ ! -f "$APP_DIR/guests.pck" ]; then
    printf '%s\n' 'Extract the entire archive. Keep the executable and guests.pck together.' >&2
    exit 1
fi
if [ ! -x "$APP_DIR/guests.x86_64" ]; then
    printf '%s\n' 'Missing execute permission. Run: chmod u+x guests.x86_64' >&2
    exit 1
fi
cd "$APP_DIR"
exec "$APP_DIR/guests.x86_64" "$@"
