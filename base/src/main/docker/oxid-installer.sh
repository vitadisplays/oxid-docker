#!/bin/bash
set -e

START_TIME=$SECONDS

XDEBUG_CONFIG_TMP=$XDEBUG_CONFIG
export XDEBUG_CONFIG=remote_enable=0

PROGRAMM_NAME=$0
cwd=$(dirname "$PROGRAMM_NAME")
cwd=$(readlink -f $cwd)

OXID_sShopDir=$1
INITOXID_DIR=$2

OXID_CHOWNER=$(whoami)
OXID_CHGROUP=$(id -g -n)

if [ -z "$INITOXID_DIR" ]; then
	INITOXID_DIR="$cwd/docker-entrypoint-initoxid"
fi

if [ ! -d "$INITOXID_DIR" ]; then
	echo "$PROGRAMM_NAME: provisioning directory $INITOXID_DIR not found."
	exit 1
fi
export INITOXID_DIR=$INITOXID_DIR

if [ -f "$INITOXID_DIR/settings" ]; then
	. "$INITOXID_DIR/settings"
fi

if [ -z "$OXID_sShopDir" ]; then
	OXID_sShopDir="/srv/www/oxid"
fi

if [ ! -d "$OXID_sShopDir" ]; then
	echo "$PROGRAMM_NAME: shop directory $OXID_sShopDir not found."
	exit 1
fi

if [ ! -w "$OXID_sShopDir" ]; then
	echo "$PROGRAMM_NAME: shop directory $OXID_sShopDir not writable."
	exit 1
fi

export OXID_sShopDir=$OXID_sShopDir

TMP_DIR="/tmp"
RESORCES_DIR="$INITOXID_DIR/resources.d"
export RESORCES_DIR=$RESORCES_DIR

# OXID settings
OXID_HOSTNAME=$(hostname)

# OXID_ADMIN_TOOL settings
if [ -f "$cwd/oxid-helper.inc.php" ]; then
	OXID_INCLUDE_HELPER="$cwd/oxid-helper.inc.php"
	export OXID_INCLUDE_HELPER=$OXID_INCLUDE_HELPER
fi

if [ -f "$cwd/oxid-admin-tools.phar" ]; then
	OXID_ADMIN_TOOL="$cwd/oxid-admin-tools.phar"
	export OXID_ADMIN_TOOL=$OXID_ADMIN_TOOL
fi
if [ -f "$OXID_sShopDir/bin/oxid-admin-tools.phar" ]; then
	OXID_ADMIN_TOOL="$OXID_sShopDir/bin/oxid-admin-tools.phar"
	export OXID_ADMIN_TOOL=$OXID_ADMIN_TOOL
fi

if [ ! -f "$OXID_ADMIN_TOOL" ]; then
	echo "$PROGRAMM_NAME: oxid-admin-tools.phar not found in $INITOXID_DIR or $OXID_sShopDir/bin"
	exit 1
fi

if [ ! -f "$OXID_INCLUDE_HELPER" ]; then
	echo "$PROGRAMM_NAME: $cwd/oxid-helper.inc.php not found"
	exit 1
fi

if [ -z "$OXID_sCompileDir" ]; then
	OXID_sCompileDir="$OXID_sShopDir/tmp"
fi
export OXID_sCompileDir=$OXID_sCompileDir

if [ -z "$OXID_HOST" ]; then
	echo "$PROGRAMM_NAME: using IP Address from $OXID_HOSTNAME"
	OXID_HOST_IP=$(getent hosts $OXID_HOSTNAME | awk '{ print $1 }')
else
	OXID_HOST_IP=$OXID_HOST
fi
export OXID_HOST_IP=$OXID_HOST_IP

if [ -z "$OXID_sShopURL" ]; then
	OXID_sShopURL="http://$OXID_HOST_IP"
fi
export OXID_sShopURL=$OXID_sShopURL

if [ -z "$OXID_sAdminSSLURL" ]; then
	if [ -z "$OXID_sSSLShopURL" ]; then
		OXID_sAdminSSLURL="null"
		OXID_sAdminURL="$OXID_sShopURL/admin"
	else
		OXID_sAdminSSLURL="$OXID_sSSLShopURL/admin"
	fi
fi
export OXID_sAdminSSLURL=$OXID_sAdminSSLURL

if [ -z "$OXID_sSSLShopURL" ]; then
	OXID_sSSLShopURL="null"
fi
export OXID_sSSLShopURL=$OXID_sSSLShopURL

if [ -z "$OXID_iUtfMode" ]; then
	OXID_iUtfMode=0 
fi
export OXID_iUtfMode=$OXID_iUtfMode

if [ -z "$OXID_captchaKey" ]; then
	OXID_captchaKey=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1) 
fi
export OXID_captchaKey=$OXID_captchaKey

if [ -z "$OXID_SOURCE_ARCHIVE_PWD" ]; then
	OXID_SOURCE_ARCHIVE_PWD="0x1d"
fi

if [ -z "$OXID_DEMODATA" ]; then
	OXID_DEMODATA="0"
fi

# Composer settings
COMPOSER_BIN="composer"
COMPOSER_CACHE_DIR=$OXID_sShopDir/tmp/composer
export COMPOSER_CACHE_DIR=$COMPOSER_CACHE_DIR

# MySQL settings
mysql_params="--host=$OXID_dbHost --user=$OXID_dbUser --password=$OXID_dbPwd $OXID_dbName"

function unsetFilePermissions {
	if [ -f "$OXID_sShopDir/config.inc.php" ]; then
		 chmod ug=rw "$OXID_sShopDir/config.inc.php"
	fi
	
	if [ -f "$OXID_sShopDir/.htaccess" ]; then
		 chmod u=r "$OXID_sShopDir/.htaccess"
	fi
}

function setFilePermissions {
	names='/out/pictures/ /out/media/ /tmp/ /export/'
	echo "$PROGRAMM_NAME: set file and folder permissions"
	
	if [ -d "$OXID_sShopDir" ]; then	
		if [ -d "$OXID_sShopDir/bin" ]; then
			 chmod u+x $(find "$OXID_sShopDir/bin" -type f)
		fi
		
		if [ -f "$OXID_sShopDir/config.inc.php" ]; then
			 chmod u=r "$OXID_sShopDir/config.inc.php"
		fi
		
		if [ -f "$OXID_sShopDir/.htaccess" ]; then
			 chmod u=r "$OXID_sShopDir/.htaccess"
		fi
	fi
}

function runComposer {
	echo "$PROGRAMM_NAME: run $COMPOSER_BIN $@ --working-dir=$OXID_sShopDir/modules"
	
	"$COMPOSER_BIN" "$@" --working-dir=$OXID_sShopDir/modules
}

function configureConfig {
	echo "$PROGRAMM_NAME: configure ${OXID_sShopDir}/config.inc.php"
	
	chmod ug+w "$OXID_sShopDir/config.inc.php"
	
	while IFS='=' read -r -d '' name value; do
		if [[ $name =~ ^OXID_ ]] ; then
			var=${name:5}
			search="\$this->$var\s*=\s*.*\s*;"
			replace="\$this->$var = '$value';"
			
			if [[ $value =~ ^(true|false|null)$ ]] || [[ $value =~ ^[0-9]+$ ]]; then
				search="\$this->$var\s*=\s*.*\s*;"
				replace="\$this->$var = $value;"
			fi
	
			if grep -q "${search}" "${OXID_sShopDir}/config.inc.php" ; then
				echo "$PROGRAMM_NAME: replace ${search} => ${replace} in ${OXID_sShopDir}/config.inc.php"
				sed -i -- "s@${search}@${replace}@g" "${OXID_sShopDir}/config.inc.php"
			fi
		fi		
	done < <(env -0)
	
	chmod u=r "$OXID_sShopDir/config.inc.php"
}

function unpackArchive {
	local TMP_FILE=""
	local ARCHIVE_FILE=$1
	local DEST=$2

	if [[ $ARCHIVE_FILE =~ ^https?: ]] ; then
		BASENAME=$(basename "$ARCHIVE_FILE")
		TMP_FILE="$TMP_DIR/$BASENAME"
		echo "$PROGRAMM_NAME: getting $ARCHIVE_FILE"
		wget -q "$ARCHIVE_FILE" -O "$TMP_FILE" || { echo "$PROGRAMM_NAME: getting $ARCHIVE_FILE failed" ; exit 1; } 
		ARCHIVE_FILE=$TMP_FILE		 
	fi

	if [ -z "$DEST" ]; then
		DEST=$OXID_sShopDir
	fi
	
	case "$ARCHIVE_FILE" in
		*.rar) echo "$PROGRAMM_NAME: unpack $ARCHIVE_FILE to $DEST"; 7z x -trar -y -o"$DEST" -p"$OXID_SOURCE_ARCHIVE_PWD" "$ARCHIVE_FILE" || { echo "$PROGRAMM_NAME: unpack $ARCHIVE_FILE failed" ; exit 1; } ;;
		*.zip) echo "$PROGRAMM_NAME: unpack $ARCHIVE_FILE to $DEST"; 7z x -tzip -y -o"$DEST" "$ARCHIVE_FILE" || { echo "$PROGRAMM_NAME: unpack $ARCHIVE_FILE failed" ; exit 1; } ;;
		*.gz) echo "$PROGRAMM_NAME: unpack $ARCHIVE_FILE to $DEST"; 7z x -tgzip -y -o"$DEST" "$ARCHIVE_FILE" || { echo "$PROGRAMM_NAME: unpack $ARCHIVE_FILE failed" ; exit 1; } ;;
		*.bz2) echo "$PROGRAMM_NAME: unpack $ARCHIVE_FILE to $DEST"; 7z x -tbzip2 -y -o"$DEST" "$ARCHIVE_FILE" || { echo "$PROGRAMM_NAME: unpack $ARCHIVE_FILE failed" ; exit 1; } ;;
		*)			echo "$PROGRAMM_NAME: unsupported archive format $ARCHIVE_FILE" ; exit 1 ;;					
	esac

	if [ -n "$TMP_FILE" ] &&  [ -f "$TMP_FILE" ]; then
		 rm -r -f "$TMP_FILE"
	fi
}

function moduleInstallLegacy {
	local TMP_FILE=""
	local ARCHIVE_FILE=$1	
	local COPY_MATRIX=$2
	local EXCLUDES=$3
	
	if [[ $ARCHIVE_FILE =~ (.rar|.zip|.gz|.bz2)$ ]] ; then
		BASENAME=$(basename ${ARCHIVE_FILE} .${ARCHIVE_FILE##*.})
		TMP_FILE="${TMP_DIR}/${BASENAME}"	
		unpackArchive "$ARCHIVE_FILE" "$TMP_FILE"
		ARCHIVE_FILE=$TMP_FILE	
	fi
	
	if [ -z "$EXCLUDES" ]; then
		EXCLUDES=(".*" ".*/" "vendor/" "composer.lock" "composer.phar")
	fi
	
	if [ -z "$COPY_MATRIX" ]; then
		COPY_MATRIX="copy_this/ = ,changed_full/ = "
	fi
	
	IFS=',' read -ra HASH <<< "$COPY_MATRIX"
	for h in "${HASH[@]}"; do
    	key=$(echo "$h" | cut -f1 --delimiter='=')
    	key=$(echo "$key" | xargs)
    	value=$(echo "$h" | cut -f2 --delimiter='=')
    	value=$(echo "$value" | xargs)
    	
    	SOURCE="${ARCHIVE_FILE}/${key}"
		SHOP_DEST="${OXID_sShopDir}/${value}"		

		if [ -f "$SOURCE" ] || [ -d "$SOURCE" ]; then
			echo "$PROGRAMM_NAME: install $SOURCE to $SHOP_DEST"
		
			SHOP_DEST_DIR=$(dirname "$SHOP_DEST")
			if [ ! -d "$SHOP_DEST_DIR" ]; then
				mkdir -p "$SHOP_DEST_DIR"
			fi
			
			EXCLUDE_STRING=''
			for e in "${EXCLUDES[@]}"
			do :
   				EXCLUDE_STRING+=" --exclude=${e}"
			done
			
			rsync -av --force $EXCLUDE_STRING "${SOURCE}" "${SHOP_DEST}"
		else
			echo "$PROGRAMM_NAME: copy $SOURCE to $SHOP_DEST not found. ignored."
		fi
	done
		
	if [ -n "$TMP_FILE" ] &&  [ -f "$TMP_FILE" ]; then
		 rm -r -f "$TMP_FILE"
	fi	
}

function moduleInstall {
	local TMP_FILE=""
	local ARCHIVE_FILE=$1

	if [[ $ARCHIVE_FILE =~ ^https?: ]] ; then
		ARCHIVE_FILE=$(getFile $ARCHIVE_FILE)
		TMP_FILE=$ARCHIVE_FILE 
	fi	
	
	if [[ $ARCHIVE_FILE =~ (.rar|.zip|.gz|.bz2)$ ]] ; then
		BASENAME=$(basename "$ARCHIVE_FILE")
		DEST="$TMP_DIR/moduleInstallLegacy_$BASENAME"
		TMP_FILE=$ARCHIVE_FILE 
		ARCHIVE_FILE=$(unpackArchive $ARCHIVE_FILE $DEST)		
	fi
		
	echo "$PROGRAMM_NAME: install $ARCHIVE_FILE"; php $OXID_ADMIN_TOOL--shop-dir="$OXID_sShopDir" module:install --type=module "$ARCHIVE_FILE" || { echo "$PROGRAMM_NAME: install module $ARCHIVE_FILE failed"; exit 1; }

	if [ -n "$TMP_FILE" ] &&  [ -f "$TMP_FILE" ]; then
		rm -r -f "$TMP_FILE"
	fi
}

function activateModule {
	local ModuleId=$1
	local ShopId=$2	

	echo "$PROGRAMM_NAME: running $cwd/activate-module.php for module $ModuleId on Shop $ShopId"; php -f "$cwd/activate-module.php" "$OXID_sShopDir" "$ModuleId" "$ShopId"
}

function deactivateModule {
	local ModuleId=$1
	local ShopId=$2	

	echo "$PROGRAMM_NAME: running $cwd/deactivate-module.php for module $ModuleId on Shop $ShopId"; php -f "$cwd/deactivate-module.php" "$OXID_sShopDir" "$ModuleId" "$ShopId"
}

function updateViews {
	local ShopId=$1

	echo "$PROGRAMM_NAME: running $cwd/update-views.php for Shop $ShopId"; php -f "$cwd/update-views.php" "$OXID_sShopDir" "$ShopId"
}

function updateShop {
	local TMP_FILE=""
	local ARCHIVE_FILE=$1
	local ANSWERS=$2	
	if [[ $ARCHIVE_FILE =~ ^https?: ]] ; then
		BASENAME=$(basename "$ARCHIVE_FILE")
		TMP_FILE="$TMP_DIR/$BASENAME"
		echo "$PROGRAMM_NAME: getting $ARCHIVE_FILE"; wget -q "$ARCHIVE_FILE" -O "$TMP_FILE" || { echo "$PROGRAMM_NAME: getting $TMP_FILE failed" ; exit 1; }
		
		ARCHIVE_FILE=$TMP_FILE
	fi

	unsetFilePermissions
	
	echo "$PROGRAMM_NAME: install $ARCHIVE_FILE($md5)"; php $OXID_ADMIN_TOOL --shop-dir="$OXID_sShopDir" module:install --type=update --archive-password="$OXID_SOURCE_ARCHIVE_PWD" "$ARCHIVE_FILE" || { echo "$PROGRAMM_NAME: install module $ARCHIVE_FILE failed" ; exit 1; }
	
	configureConfig
	
	# Answerfile
	options=""
	answerfile="${ARCHIVE_FILE}.yml"
	
	if [ -f "$answerfile" ]; then
		options="--anwser-file=$answerfile"
	fi

	if [ -n "$ANSWERS" ]; then
		options="--answers=$ANSWERS"
	fi

	echo "$PROGRAMM_NAME: update $ARCHIVE_FILE"; php $OXID_ADMIN_TOOL --shop-dir="$OXID_sShopDir" $options update:shop || { echo "$PROGRAMM_NAME: update $ARCHIVE_FILE failed" ; exit 1; }

	php $OXID_ADMIN_TOOL --shop-dir="$OXID_sShopDir" clean:compiledir || { echo "$PROGRAMM_NAME: oxid clean compiledir failed" ; exit 1; }
	php $OXID_ADMIN_TOOL --shop-dir="$OXID_sShopDir" update:views || { echo "$PROGRAMM_NAME: oxid update views failed" ; exit 1; }
	
	if [ -n "$TMP_FILE" ] && [ -f "$TMP_FILE" ]; then
		rm -r -f "$TMP_FILE"
	fi
	
	if [ -n "$TMP_FILE" ] && [ -f "$TMP_FILE.yml" ]; then
		rm -r -f "$TMP_FILE.yml"
	fi
	
	setFilePermissions
}

function dumpSQL {
	local SQL=$1	

	echo "$PROGRAMM_NAME: run $SQL"
	mysql $mysql_params -e "$SQL"
}

function dumpSQLFile {
	local TMP_FILE=""
	local SQL_FILE=$1
		
	if [[ $SQL_FILE =~ ^https?: ]] ; then
		BASENAME=$(basename "$SQL_FILE")
		TMP_FILE="$TMP_DIR/$BASENAME"
		echo "$PROGRAMM_NAME: getting $SQL_FILE"; wget -q "$SQL_FILE" -O "$TMP_FILE" || { echo "$PROGRAMM_NAME: getting $TMP_FILE failed" ; exit 1; }
		
		SQL_FILE=$TMP_FILE
	fi
	
	case "$SQL_FILE" in
		*.sh)     echo "$PROGRAMM_NAME: running $SQL_FILE"; . "$SQL_FILE" "$OXID_sShopDir";;
		*.sql)    echo "$PROGRAMM_NAME: running $SQL_FILE"; mysql $mysql_params < "$SQL_FILE"; echo ;;
		*.sql.gz) echo "$PROGRAMM_NAME: running $SQL_FILE"; gunzip -c "$SQL_FILE" | mysql $mysql_params; echo ;;
		*)        echo "$PROGRAMM_NAME: ignoring $f" ;;
	esac
	
	if [ -n "$TMP_FILE" ] && [ -f "$TMP_FILE" ]; then
		rm -r -f "$TMP_FILE"
	fi
}

function cleanUp {
	rm -r -f "$OXID_sShopDir/tmp/smarty"
	rm -r -f "$OXID_sShopDir/tmp/*.txt"
	
	echo "$PROGRAMM_NAME: running $cwd/clear-cache.php"; php -f "$cwd/clear-cache.php" "$OXID_sShopDir"
}

if [ ! -f "${OXID_sShopDir}/pkg.info" ]; then	
	# Oxid Sources	
	if [ -d "$INITOXID_DIR/sources.d" ]; then
		echo "$PROGRAMM_NAME: check for oxid sources in directory $INITOXID_DIR/sources.d"
		
		for f in $INITOXID_DIR/sources.d/*; do
			case "$f" in
				*.sh)     echo "$PROGRAMM_NAME: running $f"; . "$f" "$OXID_sShopDir";;
				*.zip)    unzipArchive "$f";;
				*.rar)    unrarArchive "$f";;
			esac
			echo
		done			
	fi
	
	configureConfig	
fi

DB_TABLE_COUNT_SQL="select count(*) from information_schema.tables where table_type = 'BASE TABLE' and table_schema = '$OXID_dbName';"
DB_TABLE_COUNT=$(echo $DB_TABLE_COUNT_SQL | mysql -s $mysql_params)

echo "$PROGRAMM_NAME: MySQL $OXID_dbName Table count: $DB_TABLE_COUNT"

if [ "$DB_TABLE_COUNT" -eq 0 ]; then
	if [ -f "${OXID_sShopDir}/setup/sql/database_schema.sql" ]; then	
		dumpSQLFile "${OXID_sShopDir}/setup/sql/database_schema.sql"
	fi
	if [ -f "${OXID_sShopDir}/setup/sql/database.sql" ]; then	
		dumpSQLFile "${OXID_sShopDir}/setup/sql/database.sql"
	fi	
	if [ -f "${OXID_sShopDir}/setup/sql/initial_data.sql" ]; then	
		dumpSQLFile "${OXID_sShopDir}/setup/sql/initial_data.sql"
	fi	

	if [ "$OXID_DEMODATA" -eq 1 ]; then
		if [ -f "${OXID_sShopDir}/setup/sql/demodata.sql" ]; then	
			dumpSQLFile "${OXID_sShopDir}/setup/sql/demodata.sql"
		fi
	fi
	
	if [ "$OXID_iUtfMode" -eq "1" ]; then
		if [ -f "${OXID_sShopDir}/setup/sql/latin1_to_utf8.sql" ]; then
			echo "$PROGRAMM_NAME: Starting SQL dump for UTF-Mode."	
			dumpSQLFile "${OXID_sShopDir}/setup/sql/latin1_to_utf8.sql"
		fi
	fi
	
	# init
	if [ -d "$INITOXID_DIR/init.d" ]; then	
		echo "$PROGRAMM_NAME: check for initialisiation resources in directory $INITOXID_DIR/init.d"
	
		for f in $INITOXID_DIR/init.d/*; do
			case "$f" in
				*.sh)     			echo "$PROGRAMM_NAME: running $f"; . "$f" "$OXID_sShopDir";;
				*.sql|*.sql.gz)     dumpSQLFile "$f";;
				*.php)    			echo "$PROGRAMM_NAME: running php -f $f"; php -f "$f" "$OXID_sShopDir";;
				*)        			echo "$PROGRAMM_NAME: ignoring $f";;
			esac
			echo
		done	
		
	fi	
fi

if [ -d "${OXID_sShopDir}/setup" ]; then 
	find "${OXID_sShopDir}/setup" -maxdepth 1 -mindepth 1 -exec rm -rf {} \;
fi
	
if [ -d "$INITOXID_DIR/modules.d" ]; then
	echo "$PROGRAMM_NAME: check for oxid modules install files in $INITOXID_DIR/modules.d"
	
	for f in $INITOXID_DIR/modules.d/*; do
		case "$f" in
			*.php)    			echo "$PROGRAMM_NAME: running php -f $f"; php -f "$f" "$OXID_sShopDir";;
			*.yml|*.json|*.ser)     echo "$PROGRAMM_NAME: import config $f"; php $OXID_ADMIN_TOOL --shop-dir="$OXID_sShopDir" import:shop-config $f || { echo "$PROGRAMM_NAME: shop config import of $f  failed." ; exit 1; };;
			*.sh)     echo "$PROGRAMM_NAME: running $f"; . "$f" "$OXID_sShopDir";;
		esac
		echo
	done
fi

# Oxid configuration files
if [ -d "$INITOXID_DIR/config.d" ]; then
	echo "$PROGRAMM_NAME: check for oxid config files in $INITOXID_DIR/config.d"
	
	for f in $INITOXID_DIR/config.d/*; do
		case "$f" in
			*.yml|*.json|*.ser)     echo "$PROGRAMM_NAME: import config $f"; php $OXID_ADMIN_TOOL --shop-dir="$OXID_sShopDir" import:shop-config $f || { echo "$PROGRAMM_NAME: shop config import of $f  failed." ; exit 1; };;
			*.sh)     echo "$PROGRAMM_NAME: running $f"; . "$f" "$OXID_sShopDir";;
			*.sql|*.sql.gz)     dumpSQLFile "$f";;
		esac
		echo
	done
fi

if [ -d "$INITOXID_DIR/scripts.d" ]; then
	echo "$PROGRAMM_NAME: check for scripts in $INITOXID_DIR/scripts.d"
	
	for f in $INITOXID_DIR/scripts.d/*; do
		case "$f" in
			*.sh)     echo "$PROGRAMM_NAME: running $f"; . "$f" "$OXID_sShopDir";;
			*.php)    echo "$PROGRAMM_NAME: running php -f $f"; php -f "$f" "$OXID_sShopDir";;
			*.sql|*.sql.gz)     dumpSQLFile "$f";;
		esac
		echo
	done
fi

cleanUp



# Oxid File and Folder Permissions
setFilePermissions

# Information
oxid_edition=$(grep "^edition" "$OXID_sShopDir/pkg.info" | cut -d'=' -f2 | tr -d \" | tr -d ' ')
oxid_version=$(grep "^version" "$OXID_sShopDir/pkg.info" | cut -d'=' -f2 | tr -d \" | tr -d ' ')
php_version=$(php --version | grep "^PHP " | cut -d " " -f2)

if [ "$oxid_edition" = "EE" ]; then
	oxid_encoder=$(grep "^encoder-version" "$OXID_sShopDir/pkg.info" | cut -d'=' -f2 | tr -d \" | tr -d ' ')
	oxid_version_string="$oxid_edition $oxid_version for PHP $oxid_encoder"
else
	oxid_version_string="$oxid_edition $oxid_version"	
fi

echo "oxid eshop version: $oxid_version_string"
echo "php version: $php_version"

if [ "$OXID_sSSLShopURL" = "null" ]; then
	echo "oxid eshop accessible under $OXID_sShopURL"
else
	echo "oxid eshop accessible under $OXID_sSSLShopURL"
fi

if [ "$OXID_sAdminSSLURL" = "null" ]; then
	echo "oxid eshop admin area accessible under $OXID_sAdminURL"
else
	echo "oxid eshop admin area accessible under $OXID_sAdminSSLURL"
fi

ELAPSED_TIME=$(($SECONDS - $START_TIME))

echo "Service started in $ELAPSED_TIME seconds..."

export XDEBUG_CONFIG=$XDEBUG_CONFIG_TMP