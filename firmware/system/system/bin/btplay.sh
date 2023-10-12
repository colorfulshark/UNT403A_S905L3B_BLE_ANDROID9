#!/system/bin/sh

cmccbootvideo=`getprop ro.product.bootvideo.type`

if [ "$cmccbootvideo" != "zip" ]; then
	if [ -f "/data/media/bootvideo" ];then
		echo "bootplay new bootvideo, path is /data/media/bootvideo"
			bootplayer /data/media/bootvideo
	else
		if [ -f "/data/local/bootvideo" ];then
			echo "bootplay new bootvideo, path is /data/local/bootvideo"
			bootplayer /data/local/bootvideo
		else
			echo "bootplay inside bootvideo"
			if [ -f "/system/media/bootvideo" ];then
				bootplayer  /system/media/bootvideo
			else
				echo 0 > /sys/class/graphics/fb1/free_scale
			fi
		fi
	fi
else
	resdir=/data/local/.bootVideoAnimation
	descfile="$resdir"/desc.txt
	if [ -d "$resdir" ];then
		if [ -f "$descfile" ];then
	#   	cat $descfile > /data/descfile
			dos2unix $descfile
	#   	cat "$descfile" | sed '/^$/d' > "$descfile"
	#   	cat $descfile > /data/descfiles
			row=`sed -n '$=' "$descfile"`
			echo row $row
			bootfiles=""
			i=1
			while((($row > 0) && (i <= $row)))
			do
				onerow=`sed -n "$i"p "$descfile"`
				echo "$onerow"
				partpathname="${onerow#*v}"
				partrespathname=`echo $partpathname | sed -e 's/^[ \t]*//'`
				echo partrespathname "$partrespathname"
				partpath="$resdir"/"$partrespathname"
				echo partpath "$partpath"
				for file in $partpath/*
				do
					echo $file
					if [ -f "$file" ];then
						echo filename "$file"
						bootfiles=${bootfiles}"${file} "
					fi
				done
				let "i += 1"
			done
			echo bootfiles "$bootfiles"
			destbootfiles=`echo $bootfiles | sed -e 's/^[ \t]*//'`
			echo destbootfiles "${destbootfiles}"
			if [ -n "$destbootfiles" ];then
				bootplayer `echo $destbootfiles`
			else
				echo "bootplayer bootvideo res is null"
				echo 0 > /sys/class/graphics/fb1/free_scale
			fi
		fi
	fi
fi