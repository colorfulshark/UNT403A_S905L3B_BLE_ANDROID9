#!/system/bin/sh

MARK=/data/local/symbol_thirdpart_apks_installed
PKGS=/system/preinstall/

curversion=`getprop ro.preinstall.app.version`
preversion=`busybox grep "version=" $MARK | busybox cut -d = -f2`
echo "curversion = $curversion"
echo "preversion = $preversion"
if [ ! -e $MARK ] || [ "$curversion" != "" -a "$curversion" != "$preversion" ] ;then
echo "booting the first time, so pre-install some APKs."

busybox find $PKGS -name "*\.apk" -exec sh /system/bin/pm install -r {} \;

# NO NEED to delete these APKs since we keep a mark under data partition.
# And the mark will be wiped out after doing factory reset, so you can install
# these APKs again if files are still there.
# busybox rm -rf $PKGS

echo version="$curversion" > $MARK
echo "OK, installation complete."
else
    echo "not need install preinstall apk."
fi