#!/system/bin/sh
echo "factory_net_monitor: Version 1.0"


#arg1: interface name
function get_entry()
{
    ifname=$1
    echo $(ip route show table main | grep $ifname)
}

function get_network_from_entry()
{
    ifname=$1
    entry=$(ip route show table main | grep $ifname)
	if [ x"$entry" != x ]; then
	network=$(echo $entry |awk  '{ print $1}')
	echo $network
	else
	echo ""
	fi
}

#arg1: interface name
function get_entry_seq()
{
    ifname=$1
    echo $(ip route show table main | sed -n -e "/$ifname/=")
}

#arg1: operation: add/del/append
#arg2: entry
function modify_route_table_main()
{
    CMD="ip route $1 table main $2"
    #printf "arg1=%s,arg2=%s" $1 "$2"
    $($CMD)
    echo "$CMD" $?
}

FactoryEnable_FILE="/params/factory_enable"
FactoryFinish_FILE="/params/factory_finish"
HIGH_IF=eth0
LOW_IF=wlan0

if [ x$1 != x ]; then
echo HIGH_IF=$1
HIGH_IF=$1
fi

if [ x$2 != x ]; then
echo LOW_IF=$2
LOW_IF=$2
fi

if [ -f ${FactoryEnable_FILE} ] && [ ! -f ${FactoryFinish_FILE} ] ; then
 echo "factory mode!"
 while true; do
    HIGHIF_SEQ=$(get_entry_seq ${HIGH_IF})
    HIGHIF_ENTRY=$(get_entry ${HIGH_IF})
    LOWIF_SEQ=$(get_entry_seq ${LOW_IF})
    LOWIF_ENTRY=$(get_entry ${LOW_IF})
	HIGH_NET=$(get_network_from_entry ${HIGH_IF})
	LOW_NET=$(get_network_from_entry ${LOW_IF})
 	
    if [ x"$HIGHIF_SEQ" != x -a x"$LOWIF_SEQ" != x -a x"$HIGH_NET" == x"$LOW_NET" ]; then
	#if [ x"$HIGHIF_SEQ" != x -a x"$LOWIF_SEQ" != x ]; then
	    if [[ $HIGHIF_SEQ > $LOWIF_SEQ ]]; then
        echo ${HIGH_IF}=$HIGHIF_SEQ ${LOW_IF}=$LOWIF_SEQ ppp0=$(get_entry_seq ppp0)
        echo "HIGHIF_ENTRY(${HIGHIF_ENTRY})"
        echo "LOWIF_ENTRY(${LOWIF_ENTRY})"
        echo "HIGH_NET(${HIGH_NET})"
        echo "LOW_NET(${LOW_NET})"
        echo "Try to exchange the entries of high and low interface:"
		
        echo $(modify_route_table_main del "$HIGHIF_ENTRY")
        echo $(modify_route_table_main del "$LOWIF_ENTRY")
        echo $(modify_route_table_main append "$HIGHIF_ENTRY")
        echo $(modify_route_table_main append "$LOWIF_ENTRY")

        fi
    fi
    sleep 1
 done
else
 echo "no factory mode!"
fi

