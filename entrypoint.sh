#!/bin/bash

sleep infinity & PID=$!
trap "kill $PID" INT TERM

case "$1" in
    'start')
        if [ ! -e /opt/netflowv9/nfcapd.pid ]; then
            echo "Removing stale pid file.."
            rm /opt/netflowv9/nfcapd.pid
        fi
        echo "Starting netflow.."
        /opt/netflowv9/bin/nfcapture.sh
        echo "..exiting"
    ;;
    *)
        echo "Called with unhandled arg: $1"
        exec /bin/bash
    ;;
esac

