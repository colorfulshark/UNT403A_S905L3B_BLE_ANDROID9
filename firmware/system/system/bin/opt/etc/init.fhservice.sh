#!/system/bin/sh

stbid=`getprop ro.serialno`
buildid=${stbid:0:20}
if [ "$buildid" == "" ]; then
    buildid=KOT49H
fi
setprop ro.build.id ${buildid}

/system/bin/opt/etc/hw.detect.sh &

/system/bin/opt/etc/andlink_para_init.sh &

sleep 20
MAC=`getprop ro.mac`
MACVALUE1=${MAC//:/\\:}
MACVALUE2=${MACVALUE1//:/\\:}
MACVALUE3=$MACVALUE2"@iptv"
SETTINGSDB=/data/misc/ethernet/eth0_config_prop.txt
SUMMARYDB=/data/data/com.fiberhome.fhstbconfig/databases/summary.db

if [ -f ${SETTINGSDB} ];then
    ipoeUserNameExist=`busybox grep "ipoeUserName=" $SETTINGSDB`
    ipoev6UserNameExist=`busybox grep "ipoev6UserName=" $SETTINGSDB`
    ipoeUserName=`busybox grep "ipoeUserName=" $SETTINGSDB | busybox cut -d = -f2`
    ipoev6UserName=`busybox grep "ipoev6UserName=" $SETTINGSDB | busybox cut -d = -f2`
    if [ -z $ipoeUserNameExist ];then
        echo "ipoeUserName=$MACVALUE1@iptv" >> $SETTINGSDB
    elif [ "$ipoeUserName" != "$MACVALUE3" ];then
        sed -i "s/ipoeUserName=.*/ipoeUserName=$MACVALUE3/g" $SETTINGSDB
    fi
    if [ -z $ipoev6UserNameExist ];then
        echo "ipoev6UserName=$MACVALUE1@iptv" >> $SETTINGSDB
    elif [ "$ipoev6UserName" != "$MACVALUE3" ];then
        sed -i "s/ipoev6UserName=.*/ipoev6UserName=$MACVALUE3/g" $SETTINGSDB
    fi
    sync
fi

if [ -f ${SUMMARYDB} ];then
    content update --uri content://fhconfig/summary/network.dhcp.username --bind value:s:$MAC"@iptv"
    sync
fi
