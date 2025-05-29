# settings start
email="root@localhost"
pin="*/1 * * * *"
# settings end
cron=$1
test -z "$cron" && exit 1
if [ "$cron" != "cron" ]; then
	if [ ! -d /etc/arecord_moniter ]; then 
		CURDIR=$(cd $(dirname ${BASH_SOURCE[0]}); pwd )
		FILENAME=$(echo $0 | sed 's#.*/##')
		# Check if cron is running
		if [ -z "$(ps -Al | grep cron | grep -v grep)" ]; then 
		# Confirm cron service
			if [ -n "$(command -v apt-get)" ]; then 
				echo -e "|\n|   Notice: Starting 'cron' via 'service'"
				service cron start
			elif [ -n "$(command -v yum)" ]; then 
				echo -e "|\n|   Notice: Starting 'crond' via 'service'"
				chkconfig crond on
				service crond start
			elif [ -n "$(command -v pacman)" ]; then 
				echo -e "|\n|   Notice: Starting 'cronie' via 'systemctl'"
				systemctl start cronie
				systemctl enable cronie
			fi
		fi
		mkdir /etc/arecord_moniter
		cp "$CURDIR/$FILENAME" /etc/arecord_moniter/cron.sh
		(crontab -u root -l | grep -v "/etc/arecord_moniter/cron.sh") | crontab -u root -
crontab -u root -l 2>/dev/null | { cat; echo "$pin bash /etc/arecord_moniter/cron.sh cron >/dev/null 2>&1"; } | crontab -u root -
	fi
	grep "$cron=" /etc/arecord_moniter/logs.log >/dev/null
	if [ $? -ne 0 ]; then
		echo "$cron=" >> /etc/arecord_moniter/logs.log
	fi
else
	test -e /etc/arecord_moniter/logs.log && {
		cat /etc/arecord_moniter/logs.log | while read LINE
		do
			domain=$(echo $LINE | sed 's#=.*##')
			hrecord=$(echo $LINE | sed 's#.*=##')
			record=$(dig $domain +short | head -n 1)
			if [ "$hrecord" != "$record" ]; then
				sed "s#$domain=.*#$domain=$record#" /etc/arecord_moniter/logs.log
				echo "hello, a record of $cron has been changed.($record)" | mail -s "DNS Record Change Notice" "$email"
			fi
		done
	}
fi
