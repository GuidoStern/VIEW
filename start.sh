#!/bin/sh

echo "current script=$0"
if [ "$0" != "/home/view/current/start.sh" ] && [ -e /home/view/current/start.sh ]
then
        echo "starting installed version...";
        sh /home/view/current/start.sh
        exit;
else
        echo "running recovery version...";
fi

ACTION=""
MD5=`md5sum /root/startup.sh`
if [ "$MD5" = "72cc8b90d9ecaff265e29a3b5c836b40  /root/startup.sh" ]
then
		cp /home/view/current/media/view-splash-updating.png /root/view-splash-updating.png
		cp /home/view/current/sd_card_update.js /root/sd_card_update.js
		cp /home/view/current/start.sh /root/startup.sh
        echo "md5 matches, copied files"
fi

if (/opt/sunxi-tools/pio -m PB10 | grep -q "PB10<0><1><0><0>") && test -e /sys/class/block/mmcblk1p1; then
    echo "button pressed"
    mount /dev/mmcblk1p1 /media
    if ls /media/VIEW-*.zip 1> /dev/null 2>&1; then
	    echo "firmware available"
	    ACTION="install"
	else
		umount /media
	fi
fi

if [ "$ACTION" = "install" ]; then
	killall fbi
	fbi -T 1 -d /dev/fb0 -noverbose /root/view-splash-updating.png &
	killall node
	cd /root;
	node sd_card_update.js
	echo "installation complete!"
	umount /media
fi

killall fbi
fbi -T 1 -d /dev/fb0 -noverbose /root/view-splash.png &
killall node
cd /home/view/current;
DATE=`date +"%Y%m%d-%H%M%S"`
UILOGFILE="/var/log/view-ui-$DATE.txt"
CORELOGFILE="/var/log/view-core-$DATE.txt"
cat ./logs/current.txt > ./logs/previous.txt
echo $CORELOGFILE > ./logs/current.txt
prepend_date() { while read line; do echo $(date +%Y%m%d-%H%M%S) $line; done }
forever main.js 2>&1 | prepend_date >> $UILOGFILE &
forever intervalometer/intervalometer-server.js 2>&1 | prepend_date >> $CORELOGFILE &

