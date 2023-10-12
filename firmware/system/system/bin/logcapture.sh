#!/system/bin/sh
log_enable="1"
log_capture=$(getprop persist.logcapture.enable)
log_path=$(getprop persist.logcapture.path)
if [ "$log_capture" = "$log_enable" ]; then
   if [ "x$log_path" != "x" ]; then
      sleep 5
      logcat > $log_path/logcat.log
   else
      logcat > /data/logcat.log
   fi

fi


