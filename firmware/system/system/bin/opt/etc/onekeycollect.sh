#!/system/bin/sh
#$Author: zhangjian $
#$Date: 2017-07-03  $
#$Rev: 1000 
#$Rev: 1000
# 
#persist.sys.collect.info          defined by UI; 1 only for log, 2 only for pcap, 3 for both; default 3
#persist.sys.collect.logcatlimit   Mb; log split little one, every one's size;  default 20   
#persist.sys.collect.tcpdmplimit  Mb; pacp split little one, every one's size; default 300

echo "One Key Collect"

#devMac=$(busybox ifconfig | grep "eth0 " | busybox awk '{print $5}' | busybox sed "s/://g")
while [ -z $devMac ]
do
    #mac=`getprop ro.mac`
    #devMac=`echo "$mac" | busybox sed "s/://g"`
    sleep 0.5
    devMac=$(busybox ifconfig | grep "eth0 " | busybox awk '{print $5}' | busybox sed "s/://g")   
done

startupDirName="STBLogInfo_"$devMac"_Startup"
startupDirPath="/sdcard/$startupDirName"
sdcardDir="/sdcard"
startupFlag="/params/onekeystartup"
VERSION=`getprop ro.build.version.release`

getUSBPath(){
    usbDir=$(df | grep "/mnt/runtime/default/sda1" | busybox awk '{print $1}') ####hisi
    if [ -z $usbDir ]; then
         if [ $VERSION == "9" ]; then
            usbDir=$(df | grep "/mnt/media_rw" | busybox awk '{print $1}'| grep "/mnt/media_rw") #### amlogic Andriod9.0
         else
            usbDir=$(df | grep "/storage/external_storage/sda" | busybox awk '{print $1}') #### amlogic Android4.4
          fi
      if [ -z $usbDir ]; then
            usbDir=$(df | grep "/mnt/usb/sda" | busybox awk '{print $1}') #######mstar
      fi
    fi

    usbDirValue=$(echo $usbDir)

    echo "$usbDir, $devMac $startupDirName"
}

##specify interface for tcpdump, any is too much, may cause lowmemory
getInterface(){
    TMP=`busybox ifconfig|grep "eth0 " `
    TMP2=`busybox ifconfig|grep "ppp0" `
    TMP3=`busybox ifconfig|grep "wlan0" `
    interface="eth0"

    if [ ! -z "$TMP" ]; then
        StbIP1=`busybox ifconfig eth0 |grep "inet addr" |busybox cut -d : -f 2|busybox cut -d " " -f 1 `
    fi
    if [ ! -z "$TMP2" ]; then
        StbIP2=`busybox ifconfig ppp0 |grep "inet addr" |busybox cut -d : -f 2|busybox cut -d " " -f 1 `
    fi
    if [ ! -z "$TMP3" ]; then
        StbIP3=`busybox ifconfig wlan0 |grep "inet addr" |busybox cut -d : -f 2|busybox cut -d " " -f 1 `
    fi

    echo "stbip1=== $StbIP1, $StbIP2, $StbIP3"
    if [ ! -z "$StbIP1" ]; then
        interface="eth0"
    elif [ ! -z "$StbIP2" ]; then
        interface="ppp0"
    elif [ ! -z "$StbIP3" ]; then
        interface="wlan0"
    fi

    echo "interface=== $interface"
}

stop(){
    echo "Stop collect info......"
    sync 

    if [ -d $startupDirPath ];then
        getUSBPath
        if [[ "$usbDirValue" != "" ]];then
            if [ -d $usbDir/$startupDirName ]; then
                rm -rf $usbDir/$startupDirName
            fi
            cp -r $startupDirPath  $usbDir
            sync
            /system/bin/am broadcast -a ONEKEYCOLLECT_BROADCAST --es actionName "copyOver" -f 0x01000000
        fi
        rm -rf $startupDirPath
        if [ -f  $startupFlag ];then
            rm -rf $startupFlag
        fi
    fi
    PID=$(ps | grep "onekeycollect" | busybox awk '{print $2}')
    echo "onekeycollect=$PID"
    if [ ! $PID ];then
        echo "onekeycollect is not exist"
    else
        kill $PID
    fi
    exit 0
}


start(){
    isStart=`getprop sys.onekeylog.start`
    echo "Start collect info.....=$isStart"
    if [ $isStart == 1 ]; then
        echo "Start collect info......"

        usbMounted=0
        if [[ "$usbDirValue" != "" ]]; then
            echo "USB device is mounted to $usbDir"
            usbMounted=1    
        else
            echo "No USB device is mounted"
            usbMounted=0
        fi
        
        if [ $usbMounted -eq 1 ];then
            dirName="STBLogInfo_"$devMac"_"`date '+%Y%m%d%H%M%S'`
            dirPath="$usbDir/$dirName"
            
            mkdir $dirPath
            STBDevInfo="STBDeviceInfo"
            mkdir "$dirPath/$STBDevInfo"
            
            STBDevInfoTar=$dirPath/STBDeviceInfo.tar.gz
            
            getInterface
            type=`getprop persist.sys.collect.info`
            logcatlimit=`getprop persist.sys.collect.logcatlimit`
            tcpdumplimit=`getprop persist.sys.collect.tcpdmplimit`
            if [ -z $logcatlimit ];then
                logcatlimit=20
            fi
            if [ -z $tcpdumplimit ];then
                tcpdumplimit=300
            fi
            if [ -z $type ]; then
                type=3
            fi
            logcatlimit=`busybox expr $logcatlimit \* 1024`
            if [ $type == "1" ];then
                logcat -v threadtime -r$logcatlimit -n100 -f $dirPath/STBLog.txt &
            elif [ $type == "2" ];then
                tcpdump -i $interface -s0 -C $tcpdumplimit -w  $dirPath/STBCap.cap &
            elif [ $type == "3" ];then
                logcat -v threadtime -r$logcatlimit -n100 -f $dirPath/STBLog.txt &
                tcpdump -i $interface -s0 -C $tcpdumplimit -w  $dirPath/STBCap.cap &
            fi
            
            dmesg > $dirPath/STBDmesg.txt
            getprop > $dirPath/GetProp.txt
            
            dropbox="/data/system/dropbox"
            tombstones="/data/tombstones"
            anr="/data/anr"
            fhdatabase="/data/data/com.fiber*"
            systemdatabase="/data/data/com.android.providers.settings"
            
            version="/system/opt/etc/version"
            buildprop="/system/*.prop*"
            iptvsettingprop="/params/iptvsetting.properties"
            defaultiptvsetting="/system/opt/etc/default.iptvsetting"
            fhversion="/system/fhversion"
            
            fhiptv="/data/data/com.android.smart.terminal.iptv"
            
            cp -r $dropbox      $dirPath/$STBDevInfo
            cp -r $tombstones   $dirPath/$STBDevInfo
            cp -r $anr          $dirPath/$STBDevInfo
            cp -r $fhdatabase   $dirPath/$STBDevInfo
            cp -r $systemdatabase   $dirPath/$STBDevInfo
            cp -r $version      $dirPath/$STBDevInfo
            cp -r $buildprop    $dirPath/$STBDevInfo
            cp -r $iptvsettingprop  $dirPath/$STBDevInfo
            cp -r $defaultiptvsetting  $dirPath/$STBDevInfo
            cp -r $fhversion  $dirPath/$STBDevInfo
            cp -r $fhiptv  $dirPath/$STBDevInfo

            chmod -R 777 $dirPath/$STBDevInfo
            cd $dirPath
            

            busybox tar cvzf  $STBDevInfoTar  $STBDevInfo
            rm -rf $STBDevInfo
                   
            dirSize=1
            while [ $dirSize -le 33554432 ] 
            do
                if [[ "$usbDirValue" == "" ]];then 
                    break
                fi
                
                echo "============`date '+%Y%m%d%H%M%S'`===============" >> $dirPath/STBRoute.txt
                busybox route -n >> $dirPath/STBRoute.txt
                
                echo "============`date '+%Y%m%d%H%M%S'`===============" >> $dirPath/STBArp.txt
                busybox arp -a >> $dirPath/STBArp.txt
                
                echo "============`date '+%Y%m%d%H%M%S'`===============" >> $dirPath/STBPs.txt
                ps >> $dirPath/STBPs.txt
                
                echo "============`date '+%Y%m%d%H%M%S'`===============" >> $dirPath/STBTop.txt
                top -n 1 >> $dirPath/STBTop.txt
                
                echo "============`date '+%Y%m%d%H%M%S'`===============" >> $dirPath/STBIfconfig.txt
                busybox ifconfig >> $dirPath/STBIfconfig.txt
                sync
                sleep 30
                
                dirSize=$(busybox du -s $dirPath | busybox awk '{print $1}')
                echo $dirSize
            done
        
            sync    
            /system/bin/am broadcast -a ONEKEYCOLLECT_BROADCAST --es actionName "realTimeOver" -f 0x01000000
        fi
    fi   
}

startup(){
    ONEKEYCTON=`getprop persist.sys.onekeyct`
    case $ONEKEYCTON in
    "1")
        echo "one key collect startup"
        
        flag=1
        while [ $flag==1 ]
        do
            if [ ! -d $sdcardDir ];then
                sleep 1
            else
                break
            fi
        done

        if [ -d $startupDirPath ];then
            rm -rf $startupDirPath/*
            if [ -f  $startupFlag ];then
                echo "There has startup message"
                rm -rf $startupFlag
            fi 
        else
        
            mkdir $startupDirPath
        fi
        
        getInterface
        type=`getprop persist.sys.collect.info`
        logcatlimit=`getprop persist.sys.collect.logcatlimit`
        tcpdumplimit=`getprop persist.sys.collect.tcpdmplimit`
        if [ -z $logcatlimit ];then
            logcatlimit=20
        fi
        if [ -z $tcpdumplimit ];then
            tcpdumplimit=300
        fi
        if [ -z $type ]; then
            type=3
        fi
        logcatlimit=`busybox expr $logcatlimit \* 1024`
        if [ $type == "1" ];then
            #logcat -v time > $startupDirPath/STBLog.txt &
            logcat -v threadtime -r$logcatlimit -n100 -f $startupDirPath/STBLog.txt &
        elif [ $type == "2" ];then
            tcpdump -i $interface -s0 -C $tcpdumplimit -w  $startupDirPath/STBCap.cap &
        elif [ $type == "3" ];then
            logcat -v threadtime -r$logcatlimit -n100 -f $startupDirPath/STBLog.txt &
            tcpdump -i $interface -s0 -C $tcpdumplimit -w  $startupDirPath/STBCap.cap &
        fi
        
        dmesg > $startupDirPath/startup.txt
        
        echo "startup message collect" >> $startupFlag
        
        dirSize=1
        i=1       
        while [ $dirSize -le 204800 ]
        do
            while [[ i -lt 10 ]]
            do
                dirSize=$(busybox du -s $startupDirPath | busybox awk '{print $1}')
                i=$((i+1))
                echo $i, logsize:$dirSize
                if [[ $dirSize -lt 204800 ]];then
                    echo "============`date '+%Y%m%d%H%M%S'`===============" >> $startupDirPath/STBRoute.txt
                    busybox route -n >> $startupDirPath/STBRoute.txt
            
                    echo "============`date '+%Y%m%d%H%M%S'`===============" >> $startupDirPath/STBArp.txt
                    busybox arp -a >> $startupDirPath/STBArp.txt
            
                    echo "============`date '+%Y%m%d%H%M%S'`===============" >> $startupDirPath/STBPs.txt
                    ps >> $startupDirPath/STBPs.txt
            
                    echo "============`date '+%Y%m%d%H%M%S'`===============" >> $startupDirPath/STBTop.txt
                    top -n 1 >> $startupDirPath/STBTop.txt
            
                    echo "============`date '+%Y%m%d%H%M%S'`===============" >> $startupDirPath/STBIfconfig.txt
                    busybox ifconfig >> $startupDirPath/STBIfconfig.txt
                    sync
                    sleep 5
                else
                    break 2
                fi
            done
            sync
            sleep 5
            
            dirSize=$(busybox du -s $startupDirPath | busybox awk '{print $1}') 
            echo logsize:$dirSize
        done
        
        /system/bin/am broadcast -a ONEKEYCOLLECT_BROADCAST --es actionName "startupOver" -f 0x01000000
    ;;
    *)
    
    ;;
    
    esac
}
getUSBPath
getInterface
start
startup

case "$1" in      
  'start')  
    start  
   ;;  
  'stop')  
    stop  
    ;;  
  'startup')
    startup
    ;;
  *)  
    echo $"Usage: $0 {start|stop|startup}"  
    ;;
esac
