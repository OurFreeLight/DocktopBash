#!/usr/bin/env bash

for DEV_PATH in $(find /sys/bus/usb/devices/usb*/ -name dev); do
    (
        SYSPATH="${DEV_PATH%/dev}"
        DEV_NAME="$(udevadm info -q name -p $SYSPATH)"

        eval "$(udevadm info -q property --export -p $SYSPATH)"

        if [[ -z "$ID_SERIAL" ]]; then
            exit
        fi

        echo "/dev/$DEV_NAME - $ID_SERIAL"
    )
done