#!/system/bin/sh


######################## static property ##############

echo "set andlink prop start ...."

mac1=$(getprop ro.mac)
setprop ro.andlink.deviceMac ${mac1//:}
setprop ro.andlink.mac ${mac1//:}
echo ro.andlink.deviceMac = $(getprop ro.andlink.deviceMac)

setprop ro.andlink.firmwareVersion $(getprop ro.build.version.incremental)
echo ro.andlink.firmwareVersion = $(getprop ro.andlink.firmwareVersion)

setprop ro.andlink.deviceVendor 'Fiberhome'
echo ro.andlink.deviceVendor = $(getprop ro.andlink.deviceVendor)

wifi_chip_type=`cat /sys/bus/sdio/devices/*/uevent 2>&- | grep SDIO_ID | grep -Ei "037A:7608|024C:B822|037A:7603"`
if [ -z "$wifi_chip_type" ];then
    setprop ro.andlink.wifiMode 0
else
    setprop ro.andlink.wifiMode 1
fi
echo ro.andlink.wifiMode = $(getprop ro.andlink.wifiMode)

setprop ro.andlink.stbId $(getprop ro.serialno)
echo ro.andlink.stbId = $(getprop ro.andlink.stbId)

AREAS_IPTV=(CMCCXINJIANG CMCCHEBEI)
OPERATOR=`getprop ro.operator.area`
for area in ${AREAS_IPTV[@]}
do
    if [ $area == $OPERATOR ];then
        isIPTV=1
        break
    fi
done
if [ $isIPTV == 1 ];then
    setprop ro.andlink.stbMode 'IPTV'
else
    setprop ro.andlink.stbMode 'OTT'
fi
echo ro.andlink.stbMode = $(getprop ro.andlink.stbMode)

setprop ro.andlink.manufacturer $(getprop ro.product.vendor.manufacturer)
echo ro.andlink.manufacturer = $(getprop ro.andlink.manufacturer)

setprop ro.andlink.deviceBrand $(getprop ro.product.vendor.brand)
echo ro.andlink.deviceBrand = $(getprop ro.andlink.deviceBrand)

setprop ro.andlink.deviceModel $(getprop ro.product.vendor.model)
echo ro.andlink.deviceModel = $(getprop ro.andlink.deviceModel)

setprop ro.andlink.powerSupplyMode '220V'
echo ro.andlink.powerSupplyMode = $(getprop ro.andlink.powerSupplyMode)

sn=$(getprop ro.deviceid)                                                
if [ "$sn" = "" ]; then                                                    
   setprop ro.andlink.sn '1111111111111111'                              
else                                                                     
   setprop ro.andlink.sn $sn                                           
fi
#setprop ro.andlink.sn $(getprop ro.serialno)
echo ro.andlink.sn = $(getprop ro.andlink.sn)

setprop ro.andlink.authMode '1'
echo ro.andlink.authMode = $(getprop ro.andlink.authMode)

setprop ro.andlink.authId $(getprop ro.serialno)
echo ro.andlink.authId = $(getprop ro.andlink.authId)

authkey=$(getprop ro.boot.authkey)
if [ "$authkey" = "" ]; then
    setprop ro.andlink.authKey ''
else
    setprop ro.andlink.authKey $authkey
fi
echo ro.andlink.authKey = $(getprop ro.andlink.authKey)

cmei=$(getprop ro.boot.cmei)
if [ "$cmei" = "" ]; then
    setprop ro.andlink.cmei ''
else
    setprop ro.andlink.cmei $cmei
fi
echo ro.andlink.cmei = $(getprop ro.andlink.cmei)

setprop ro.andlink.manuDate $(date -d @$(getprop ro.vendor.build.date.utc) "+%Y-%m")
echo ro.andlink.manuDate = $(getprop ro.andlink.manuDate)

setprop ro.andlink.OS 'android9.0'
echo ro.andlink.OS = $(getprop ro.andlink.OS)

setprop ro.andlink.chips.type 'Main'
echo ro.andlink.chips.type = $(getprop ro.andlink.chips.type)

setprop ro.andlink.chips.factory 'Amlogic'
echo ro.andlink.chips.factory = $(getprop ro.andlink.chips.factory)

setprop ro.andlink.chips.model 'S905L3'
echo ro.andlink.chips.model = $(getprop ro.andlink.chips.model)

################ dm param set #######################
setprop ro.andlink.cpuModel 'S905L3'
echo ro.andlink.cpuModel = $(getprop ro.andlink.cpuModel)

setprop ro.andlink.romStorageSize $(getprop ro.flash.size)
echo ro.andlink.romStorageSize = $(getprop ro.andlink.romStorageSize)

setprop ro.andlink.ramStorageSize $(getprop ro.memory.size)
echo ro.andlink.ramStorageSize = $(getprop ro.andlink.ramStorageSize)

btaddr=$(cat /sys/class/bt_addr/value)
setprop ro.andlink.bluetoothMacAddress ${btaddr//:}
echo ro.andlink.bluetoothMacAddress = $(getprop ro.andlink.bluetoothMacAddress)

setprop ro.andlink.moduleType ''
echo ro.andlink.moduleType = $(getprop ro.andlink.moduleType)

setprop ro.andlink.moduleVendor ''
echo ro.andlink.moduleVendor = $(getprop ro.andlink.moduleVendor)

setprop ro.andlink.moduleBrand ''
echo ro.andlink.moduleBrand = $(getprop ro.andlink.moduleBrand)

setprop ro.andlink.moduleModel ''
echo ro.andlink.moduleModel = $(getprop ro.andlink.moduleModel)

setprop ro.andlink.ctaNetworkModel ''
echo ro.andlink.ctaNetworkModel = $(getprop ro.andlink.ctaNetworkModel)

setprop ro.andlink.moduleFirmwareVersion ''
echo ro.andlink.moduleFirmwareVersion = $(getprop ro.andlink.moduleFirmwareVersion)

setprop ro.andlink.moduleSystemVersion ''
echo ro.andlink.moduleSystemVersion = $(getprop ro.andlink.moduleSystemVersion)

setprop ro.andlink.moduleImei ''
echo ro.andlink.moduleImei = $(getprop ro.andlink.moduleImei)

setprop ro.andlink.moduleImsi ''
echo ro.andlink.moduleImsi = $(getprop ro.andlink.moduleImsi)

setprop ro.andlink.moduleIccid ''
echo ro.andlink.moduleIccid = $(getprop ro.andlink.moduleIccid)

setprop ro.andlink.moduleCellid ''
echo ro.andlink.moduleCellid = $(getprop ro.andlink.moduleCellid)

setprop ro.andlink.moduleLac ''
echo ro.andlink.moduleLac = $(getprop ro.andlink.moduleLac)

blemac=$(cat /sys/class/bt_addr/value)
setprop ro.andlink.moduleBleMacAddress ${blemac//:}
echo ro.andlink.moduleBleMacAddress = $(getprop ro.andlink.moduleBleMacAddress)

mac2=$(getprop ro.mac)
setprop ro.andlink.moduleMacAddress ${mac2//:}
echo ro.andlink.moduleMacAddress = $(getprop ro.andlink.moduleMacAddress)

vlanmac=$(cat /sys/class/net/wlan0/address)
setprop ro.andlink.moduleWlanMac ${vlanmac//:}
echo ro.andlink.moduleWlanMac = $(getprop ro.andlink.moduleWlanMac)

setprop ro.andlink.moduleSn ''
echo ro.andlink.moduleSn = $(getprop ro.andlink.moduleSn)

setprop ro.andlink.additionalSlotImei ''
echo ro.andlink.additionalSlotImei = $(getprop ro.andlink.additionalSlotImei)

setprop ro.andlink.additionalSlotImsi ''
echo ro.andlink.additionalSlotImsi = $(getprop ro.andlink.additionalSlotImei)

setprop ro.andlink.additionalSlotIccid ''
echo ro.andlink.additionalSlotIccid = $(getprop ro.andlink.additionalSlotIccid)

setprop ro.andlink.additionalSlotCellid ''
echo ro.andlink.additionalSlotCellid = $(getprop ro.andlink.additionalSlotCellid)

setprop ro.andlink.additionalSlotLac ''
echo ro.andlink.additionalSlotLac = $(getprop ro.andlink.additionalSlotLac)

