#!/system/bin/sh
function write_hardware {
    echo 1 > /sys/class/unifykeys/attach
    echo $1 > /sys/class/unifykeys/name
    echo $2 > /sys/class/unifykeys/write
    echo "\n$1 write success."
    echo $2 >>/params/read_hardware_info
}

function write_mac {
    result=`echo $1 | busybox grep -E "^[A-Fa-f0-9]{2}(:[A-Fa-f0-9]{2}){5}$"`  ###check mac valid
    echo "final mac = " $result
    if [ -z "$result" ]; then
         echo "error!!! mac is not valid,exit."
         exit
    else
         write_hardware "mac" $1
    fi 
}

rm -rf /params/read_hardware_info
if [ $1 == "mac" ];then
     echo "set mac"
     write_mac $2
elif [ $1 == "stbid" ];then
     echo "set stbid"
     write_hardware "usid" $2 
elif [ $1 == "deviceid" ];then
     echo "set deviceid"
     write_hardware $1 $2
elif [ $1 == "cmei" ];then
     echo "set cmei"
     write_hardware $1 $2
elif [ $1 == "authkey" ];then
     echo "set authkey"
     write_hardware $1 $2
elif [ $# -eq 3 ]; then
    write_mac $1
    write_hardware "usid" $2
    write_hardware "deviceid" $3
elif [ $# -eq 5 ];then
    write_mac $1
    write_hardware "usid" $2
    write_hardware "deviceid" $3
    write_hardware "cmei" $4
    write_hardware "authkey" $5
else
    echo "unknown option "
    exit 1
fi
chmod 666 /params/read_hardware_info

function load_driver {
    if [ -f $1 ]; then
        insmod $1
    fi
}

finalmac=
function product_wifi_bt_mac {
    
    echo "product_wifi_bt_mac $1"
    
    mac1=`echo $1 | busybox cut -c 1-2`
    mac2=`echo $1 | busybox cut -c 4-5`
    mac3=`echo $1 | busybox cut -c 7-8`
    mac4=`echo $1 | busybox cut -c 10-11`
    mac5=`echo $1 | busybox cut -c 13-14`
    mac6=`echo $1 | busybox cut -c 16-17`

    tempmac=$mac1$mac2$mac3$mac4$mac5$mac6
    tempmac1=`busybox expr substr "$tempmac" 1 6`
    tempmac2=`busybox expr substr "$tempmac" 7 12`
    if [ $tempmac2 = "FFFFFF" ];then
        tempmac2="000000"
        temp1=$((16#${tempmac1}+1))
        tempmac1=`busybox printf "%06x" $temp1`
    else
        temp2=$((16#${tempmac2}+1))
        tempmac2=`busybox printf "%06x" $temp2`
    fi
    finalmac=$tempmac1$tempmac2
    echo $finalmac
}


#update wifi mac for factory
if [ $1 == "mac" -o $# -eq 5 -o $# -eq 3 ];then
BOARDID=`getprop ro.boot.boardid`
if [ "$BOARDID" == "6" ] ;then
    echo "for rtl8761btv bt mac use property ro.boot.btmacaddr"
    exit 0;
fi

### 2nd check if sdio wifi & bt
svc wifi disable
sleep 1

wifi_chip_type=`cat /sys/bus/sdio/devices/*/uevent 2>&- | grep SDIO_ID | grep -Ei "037A:7608|024C:B822|037A:7603"| busybox awk -F '=' '{print $2}'`
if [ ${wifi_chip_type} = "037A:7608" ];then
    echo "mt7668" > /dev/ttyAMA0
    load_driver /vendor/lib/modules/wlan_mt7668_sdio.ko
elif [ ${wifi_chip_type} = "037A:7603" ];then
    echo "mt7661" > /dev/ttyAMA0
    load_driver /vendor/lib/modules/wlan_mt7663_sdio.ko
else
    echo "unknow wifi type try enable wifi" > /dev/ttyAMA0
    svc wifi enable
fi

ifconfig wlan0 up

if [ $1 == "mac" ];then
   product_wifi_bt_mac $2
else
   product_wifi_bt_mac $1
fi

#iwpriv wlan0 efuse_set mac,$finalmac

wifimac=`echo $finalmac | busybox tr a-z A-Z`
wmac=$(echo "${wifimac:0:2}:${wifimac:2:2}:${wifimac:4:2}:${wifimac:6:2}:${wifimac:8:2}:${wifimac:10:2}")

unset finalmac
product_wifi_bt_mac $wmac

btmac=`echo $finalmac | busybox tr a-z A-Z`
bmac=$(echo "${btmac:0:2}:${btmac:2:2}:${btmac:4:2}:${btmac:6:2}:${btmac:8:2}:${btmac:10:2}")
echo $bmac

if [ -f /vendor/bin/wifitest ];then
    /vendor/bin/wifitest -O
    /vendor/bin/wifitest -z "W $wmac"
    /vendor/bin/wifitest -z "B $bmac"
elif [ -f /system/bin/wifitest ];then
    /system/bin/wifitest -O
    /system/bin/wifitest -z "W $wmac"
    /system/bin/wifitest -z "B $bmac"
else    
    echo "wifitest not exist"
fi

sync
sync

fi


