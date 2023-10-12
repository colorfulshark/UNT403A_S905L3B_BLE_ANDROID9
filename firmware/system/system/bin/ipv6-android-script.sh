# !/system/bin/sh
[ -z "$2" ] && echo "Error: should be run by odhcpc6c" && exit 1

ppid=`ps $$ |grep -v USER|awk '{printf $3}'`
pppid=`ps $ppid |grep -v USER|awk '{printf $3}'`

mylog() {
	log -p i -t "odhcp6c" "$ppid $pppid SCRIPT: " "$@"
}

#mylog `ps $$ |grep -v USER`
#mylog `ps $ppid |grep -v USER`

DHCPV6_MODE_STATEFUL="STATEFUL"
DHCPV6_MODE_STATELESS="STATELESS"
DHCPV6_MODE_UNKNOWN="UNKNOWN"

function echo_eval() {
	if [ x"$1" = x"-n" ]; then
		shift
	else
		mylog "$*"
	fi
	local cnt=$#
	local cmdline=""
	while ((cnt--));
	do
		cmdline="$cmdline \"$1\""
		shift
	done
	eval $cmdline
}


setup_interface () {
	local device="$1"
	local event="$2"
	local ra_address
	local dhcpv6_address

	mylog "[setup_interface $device]"

	local ip_old_addr=$(getprop dhcp6c.$device.oldipaddr)
	local ip_new_addr=$(getprop dhcp6c.$device.ipaddress)
	mylog "old_addr=[$ip_old_addr]. new_addr=[$ip_new_addr]"

	mylog "DHCPV6_MODE=[$DHCPV6_MODE]"
	DHCPV6_MODE=${DHCPV6_MODE:=-1}

	if [ $DHCPV6_MODE -eq 0 ]; then
		ipv6_mode_from_odhcp6c=$DHCPV6_MODE_STATEFUL
	elif [ $DHCPV6_MODE -eq 1 ]; then
		ipv6_mode_from_odhcp6c=$DHCPV6_MODE_STATELESS
	else
		ipv6_mode_from_odhcp6c=$DHCPV6_MODE_UNKNOWN
		if [ x$event != x"ra-updated" ]; then
			mylog "unexceptional, return immediately"
			return 1;
		else
			mylog ""
		fi
	fi
	mylog "ipv6_mode_from_odhcp6c=$ipv6_mode_from_odhcp6c"

	# Merge RA-DNS
	# ############################### dns ##################################
	for radns in $RA_DNS; do
		mylog "[setup_interface $device: radns=$radns]"
		local duplicate=0
		for dns in $RDNSS; do
			[ "$radns" = "$dns" ] && duplicate=1
		done
		[ "$duplicate" = 0 ] && RDNSS="$RDNSS $radns"
	done

	local dnspart=""
	dns_index=0
	for dns in $RDNSS; do
		dns_index=$(expr $dns_index + 1)

		echo_eval setprop dhcp6c.$device.dns$dns_index "$dns"
		if [ -z "$dnspart" ]; then
			dnspart="\"$dns\""
		else
			dnspart="$dnspart, \"$dns\""
		fi
	done

	echo_eval setprop dhcp6c.$device.dns.cnt "$dns_index"

	# ############################### prefix (maybe useless) ##################################
	local prefixpart=""
	mylog "setup_interface PREFIXES=[$PREFIXES]"
	for entry in $PREFIXES; do
		mylog "[setup_interface $device: entry=${entry}]"
		local addr="${entry%%,*}"
				entry="${entry#*,}"
				local preferred="${entry%%,*}"
				entry="${entry#*,}"
				local valid="${entry%%,*}"
				entry="${entry#*,}"
		[ "$entry" = "$valid" ] && entry=

		local class=""
		local excluded=""

		while [ -n "$entry" ]; do
			local key="${entry%%=*}"
					entry="${entry#*=}"
			local val="${entry%%,*}"
					entry="${entry#*,}"
			[ "$entry" = "$val" ] && entry=

			if [ "$key" = "class" ]; then
				class=", \"class\": $val"
			elif [ "$key" = "excluded" ]; then
				excluded=", \"excluded\": \"$val\""
			fi
		done

		local prefix="{\"address\": \"$addr\", \"preferred\": $preferred, \"valid\": $valid $class $excluded}"

		if [ -z "$prefixpart" ]; then
			prefixpart="$prefix"
		else
			prefixpart="$prefixpart, $prefix"
		fi

		# TODO: delete this somehow when the prefix disappears
		#ip -6 route add unreachable "$addr"
	done

	# ############################### route ##################################
	mylog "RA_ROUTES=[$RA_ROUTES]"
	# Merge ROUTES
	SERVER="::/0,$SERVER,86400,512"
	mylog "SERVER = $SERVER"
	local duplicates=0
	for route in $RA_ROUTES; do
		[ "$SERVER" = "$route" ] && duplicates=1
	done
	[ "$duplicates" = 0 -a x"$RA_ROUTES" == x"" ] && RA_ROUTES="$SERVER"
	mylog "Merged ROUTE=[$RA_ROUTES]"

	for entry in $RA_ROUTES; do
		local addr="${entry%%,*}"
		entry="${entry#*,}"
		local gw="${entry%%,*}"
		entry="${entry#*,}"
		local valid="${entry%%,*}"
		entry="${entry#*,}"
		local metric="${entry%%,*}"

		if [ -n "$gw" ]; then
			#mylog "[setup_interface "$device": add default route]"

			echo_eval setprop "dhcp6c.$device.gateway" "$gw"
			#echo_eval ip -6 route add "$addr" via "$gw" metric "$metric" dev "$device"
		else
			mylog ""
			#mylog "[setup_interface "$device": add target route]"
			#echo_eval ip -6 route add "$addr" metric "$metric" dev "$device"
		fi

		for prefix in $PREFIXES; do
			local paddr="${prefix%%,*}"
			# [ -n "$gw" ] && echo_eval ip -6 route add "$addr" via "$gw" metric "$metric" dev "$device" from "$paddr"
		done
	done

	
	# Merge addresses
	# ################################## addr ##################################
	mylog "try merge addresses: RA_ADDRESSES=[$RA_ADDRESSES]"
	mylog "try merge addresses: ADDRESSES=[$ADDRESSES]"
	mylog ""

	for entry in $ADDRESSES; do
		local addr="${entry%%/*}"
		dhcpv6_address=$addr
		dhcpv6_address_with_netmask="${entry%%,*}"
		mylog "dhcpv6_address=[$dhcpv6_address]"
		mylog "dhcpv6_address_with_netmask=[$dhcpv6_address_with_netmask]"
	done

	for entry in $RA_ADDRESSES; do
		local duplicate=0
		local addr="${entry%%/*}"
		ra_address=$addr
		ra_address_with_netmask="${entry%%,*}"
		mylog "ra_address=[$ra_address]"
		mylog "ra_address_with_netmask=[$ra_address_with_netmask]"

		ra_netmask="${ra_address_with_netmask#*/}"
		mylog "ra_netmask="$ra_netmask""

		for dentry in $ADDRESSES; do
			local daddr="${dentry%%/*}"
			[ "$addr" = "$daddr" ] && duplicate=1
		done
		[ "$duplicate" = "0" ] && ADDRESSES="$ADDRESSES $entry"
	done

	mylog ""
	mylog "Merged addresses: ALL_ADDRESSES=[$ADDRESSES]"

	for entry in $ADDRESSES; do
		local addr="${entry%%,*}"
		last_addr=$addr
		entry="${entry#*,}"

		dhcpv6_netmask="${addr#*/}"

		local preferred="${entry%%,*}"
		entry="${entry#*,}"
		local valid="${entry%%,*}"

		mylog "dhcpv6_netmask="$dhcpv6_netmask""
		
		#echo_eval ip -6 address add "$addr" dev "$device" preferred_lft "$preferred" valid_lft "$valid" 
	done

	mylog "Managed=[$MANAGED]"
	MANAGED=${MANAGED:=1}

	ipv6_mode=$(getprop persist.sys.ipv6.mode)
	mylog "ipv6_mode = \"$ipv6_mode\""
	ipv6_mode=${ipv6_mode:=0}

	proj_type=$(getprop sys.proj.type)
	proj_type=${proj_type:=other}
	mylog "proj_type = $proj_type"

	# 联通的局点根据属性来决定使用 RA_ADDRESSES or ADDRESSES
	if [ $proj_type == "unicom" ];then
		if [ $ipv6_mode -eq 0 -a x$dhcpv6_address != x ]; then
			tmp_addr=$dhcpv6_address/$dhcpv6_netmask
		elif [ $ipv6_mode -eq 1 -a x$ra_address != x ]; then
			tmp_addr=$ra_address/$ra_netmask
		else
			tmp_addr=$ra_address/$ra_netmask
		fi
	else # 根据 RA 报文里的 MANAGED flag 决定
		if [ $MANAGED -eq 1 -a x$dhcpv6_address != x ]; then
			tmp_addr=$dhcpv6_address/$dhcpv6_netmask
		elif [ $MANAGED -eq 0 -a x$ra_address != x ]; then
			tmp_addr=$ra_address/$ra_netmask
		fi
	fi
	## 经过以上仍未做出决定,则使用 RA_ADDRESSES\ADDRESSES 中最后一个
	mylog "final in ALL_ADDRESSES = "$last_addr
	tmp_addr=${tmp_addr:=${last_addr}}

	local old_ip_addr=$(getprop dhcp6c.$device.ipaddress)

	echo_eval setprop dhcp6c.$device.ipaddress "$tmp_addr"
	echo_eval setprop dhcp6c.$device.oldipaddr "$old_ip_addr"
}

teardown_interface() {
	mylog "[teardown_interface $1: enter]"

	local device="$1"
	#mylog "$device: flush route/address with GLOBAL scope"
	#echo_eval "ip -6 route flush dev $device"
	#echo_eval "ip -6 address flush dev $device scope global"

	mylog "clear property"
	echo_eval setprop dhcp6c.$device.result ""
	echo_eval setprop dhcp6c.$device.ipaddress ""
	echo_eval setprop dhcp6c.$device.gateway ""
	local cnt=`getprop dhcp6c.$device.dns.cnt 2>/dev/null`
	cnt=${cnt:=0}
	while ((cnt--));
	do
		echo_eval setprop dhcp6c.$device.dns$cnt ""
	done
	mylog "[teardown_interface $device: END]"
}

(
	mylog $0 $1 $2
	flock 9
	case "$2" in
		bound)
			teardown_interface "$1"
			setup_interface "$1"
			[ $? -eq 0 ] && echo_eval setprop dhcp6c."$1".result OK
		;;
		informed|updated|rebound)
			setup_interface "$1"
		;;
		ra-updated)
			setup_interface "$1" "ra-updated"
		;;
		stopped|unbound)
			teardown_interface "$1"
		;;
		started)
			teardown_interface "$1"
		;;
	esac

	# user rules
	[ -f /etc/odhcp6c.user ] && . /etc/odhcp6c.user
) 9>/data/misc/ethernet/odhcp6c.lock.$1
rm -f /data/misc/ethernet/odhcp6c.lock.$1
