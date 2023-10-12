if [ $# -lt 1 ]
then
  echo "parammeters lost：procedure_name"
  exit 1
fi
 
PROCESS=`ps | grep -w $1 | awk '{print $2}'`
for i in $PROCESS
do
  echo "Kill the $1 process [ $i ]"
  kill -9 $i
done
