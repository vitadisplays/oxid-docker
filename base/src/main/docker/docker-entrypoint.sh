#!/bin/bash
set -e

PROGRAMM_NAME=$0

echo "$PROGRAMM_NAME: waiting for Database on host $OXID_dbHost"
while ! mysqladmin ping -h"$OXID_dbHost" --silent; do
    sleep 1
done

echo "$PROGRAMM_NAME: Database ready"

OXID_ROOT="/srv/www/oxid"
OXID_CHOWNER="www-data"
OXID_CHGROUP="www-data"

#mkdir -p $OXID_ROOT
#chown $OXID_CHOWNER $OXID_ROOT
#chgrp $OXID_CHOWNER $OXID_ROOT

# installer
#sudo -E -u $OXID_CHOWNER -g $OXID_CHGROUP -- ./oxid-installer.sh $OXID_ROOT
./oxid-installer.sh $OXID_ROOT

# Cron
echo "* * * * *	$OXID_CHOWNER	/usr/bin/php -d display_errors --file $OXID_sShopDir/bin/cron.php > $OXID_ROOT/log/cron_log.txt" > /etc/cron.d/oxid_cron
service cron reload

#xdebug
if [ -n "$XDEBUG_CONFIG" ]; then
	phpenmod -v $PHP_VERSION xdebug
	echo "xdebug enabled."
else
	phpdismod -v $PHP_VERSION xdebug
	echo "xdebug disabled."
fi

exec "$@"