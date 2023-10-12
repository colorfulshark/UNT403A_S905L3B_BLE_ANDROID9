#!/system/bin/sh

/system/xbin/daemonsu --auto-daemon &
setprop persist.sys.usb.config mtp,adb
setprop persist.service.adb.enable 1
busybox telnetd -l /system/bin/sh &
adbd&

/system/bin/su --auto-daemon &

