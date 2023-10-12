#!/system/bin/sh
# Script to start "softdetector probe service" on the device
#

echo "start softdetector probe service"
dataFile="/data/data/com.cmcc.mid.softdetector/lib/libpcapcmcc.so"
systemFile="/system/bin/libpcapcmcc.so"
while [ ! -f $dataFile ] && [ ! -f $systemFile ]
do
sleep 3;
done
sleep 1
if [ -f $dataFile ];then
echo "dataFile excute"
/data/data/com.cmcc.mid.softdetector/lib/libpcapcmcc.so
else
echo "systemFile excute"
/system/bin/libpcapcmcc.so
fi