#!/system/bin/sh

BOARDID=`getprop ro.boot.boardid`
if [ "$BOARDID" == "6" ]; then
    #for rtl8761btv
    ETHERNETMAC=`getprop ro.mac`
    if [ -n "$ETHERNETMAC" ]; then
        SimpleMac=`echo "$ETHERNETMAC" | busybox sed 's/://g'`
        #bt mac = eth mac + 1
        LowBtMac=$((16#${SimpleMac:6:6}+1))
        HightBtMac=$((16#${SimpleMac:0:6}))
        if [ $LowBtMac -gt $((16#FFFFFF)) ];then
            LowBtMac=$(($LowBtMac-$((16#FFFFFF))-1))
            HightBtMac=$(($HightBtMac+1))
        fi
        BtMac=`busybox printf "%06x%06x" $HightBtMac $LowBtMac | busybox tr a-z A-Z`
        FinalBtMac=$(echo "${BtMac:0:2}:${BtMac:2:2}:${BtMac:4:2}:${BtMac:6:2}:${BtMac:8:2}:${BtMac:10:2}")
        BTMACSTATUS=`getprop persist.vendor.rtkbt.bdaddr_path`
        if [ "$BTMACSTATUS" != "default" ];then
            setprop persist.vendor.rtkbt.bdaddr_path default
        fi
        setprop ro.boot.btmacaddr $FinalBtMac
    fi
fi


