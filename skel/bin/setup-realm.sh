#!/bin/bash
#
# This is called if there is not an existing database. So no realm exists we
# need to setup the master realm.
#
# setup_realm.sh $CLIENT $SERVERNAME $IP $FQDN
#
# XXX: NOT WORKING YET..!

CLIENT=$1
SERVERNAME=$2
FQDN=$3
IP=$4

cd ~/Jet

# Read the local.cfg and get db_host and db_passwd
DB_PASSWORD=

echo -n "What is the MySQL Root password: "
read DB_ROOTPW

# Now connect and see if the master realm is setup/exists
if ! /usr/bin/mysql -u root --password="$DB_ROOTPW" -e "use master"; then
	echo "Setting up master realm.."
	echo
	read -d '' QUERY <<- END
		GRANT ALL PRIVILEGES ON master.* TO 'jetdb'@'$FQDN' IDENTIFIED BY '$DB_PASSWORD';
		GRANT reload, super ON *.* TO 'jetdb'@'$FQDN';
		FLUSH PRIVILEGES;
	END
	/usr/bin/mysql -u root --password="$DB_PASSWORD" --database="mysql" -e "$QUERY"
	python setup_master.py --main-server
fi
