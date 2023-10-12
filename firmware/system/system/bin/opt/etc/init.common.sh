#!/system/bin/sh

# add for default igmp version is 2 begin
echo "2" > /proc/sys/net/ipv4/conf/default/force_igmp_version
echo "2" > /proc/sys/net/ipv4/conf/eth0/force_igmp_version
# add for default igmp version is 2 end

#feature: set memsize for settings 
MemTotal=`cat /proc/meminfo | grep MemTotal | busybox awk '{print $2}'`
if [ $MemTotal -lt 1200000 ];then
    setprop ro.total.memsize "1G"
    setprop ro.memory.size "1GB"
elif [ $MemTotal -lt 2200000 ];then
    setprop ro.total.memsize "2G"
    setprop ro.memory.size "2GB"
elif [ $MemTotal -lt 3400000 ];then
    setprop ro.total.memsize "3G"
    setprop ro.memory.size "3GB"
else
    setprop ro.total.memsize "2G"
    setprop ro.memory.size "2GB"
fi

# 2016.05.05
FlashSIZE=`busybox fdisk -l /dev/block/mmcblk0| grep mmcblk0: | busybox awk '{print $5}'`
FlashTotal=`busybox expr $FlashSIZE / 1000000`
echo "FlashTotal is $FlashTotal"
if [ $FlashTotal -lt 4096 ];then
    setprop ro.total.flash "4G"
    setprop ro.flash.size "4GB"
elif [ $FlashTotal -lt 8192 ];then
    setprop ro.total.flash "8G"
    setprop ro.flash.size "8GB"
elif [ $FlashTotal -lt 16384 ];then
    setprop ro.total.flash "16G"
    setprop ro.flash.size "16GB"
else
    setprop ro.total.flash "8G"
    setprop ro.flash.size "8GB"
fi

CONSOLEABLE=`getprop persist.sys.console.enable`
PORTCONFLICT=`getprop ro.fix.portconfilict`
FactoryEnable_FILE="/params/factory_enable"
FactoryFinish_FILE="/params/factory_finish"
if [ -f ${FactoryEnable_FILE} ] && [ ! -f ${FactoryFinish_FILE} ] ;then
    setprop ctl.start console 
    setprop ctl.start adbd
    /system/bin/opt/bin/busybox telnetd -l /system/bin/sh &
    if [ "$PORTCONFLICT" == "1" ] ; then
        /system/bin/nc -l 8888 &
    fi
fi

DEF_FILE="/system/opt/etc/backup.dat"
TAGET_FILE="/params/backup.dat"
DEF_CRC=`busybox awk  '!/^$/{x++}END{print  x}' $DEF_FILE`
TAGET_CRC=`busybox awk  '!/^$/{x++}END{print  x}' $TAGET_FILE`

if [ ! -f $TAGET_FILE ] || [ "$TAGET_CRC" == "0" ]; then
    cp $DEF_FILE $TAGET_FILE
fi
chmod 666 $TAGET_FILE

/system/bin/opt/etc/init.fhservice.sh &
