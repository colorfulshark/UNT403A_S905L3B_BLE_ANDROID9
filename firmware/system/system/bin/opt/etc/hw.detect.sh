#!/system/bin/sh

DEVICEMODEL=`getprop ro.product.model`
sleep 1
if [ ${DEVICEMODEL:0:2} == "MR"];then
    echo "no need to check"
else
    wifi_chip_type=`cat /sys/bus/sdio/devices/*/uevent 2>&- | grep SDIO_ID | grep -Ei "037A:7608|024C:B822|037A:7603"`
    if [ -z "$wifi_chip_type" ]; then
        echo "[MARK] not found bt wifi chip."
        setprop ro.hardware.feature 1
    else
        echo "[MARK] bt wifi chip type is $wifi_chip_type"
        setprop ro.hardware.feature 0
    fi
fi
