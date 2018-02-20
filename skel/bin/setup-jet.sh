#!/bin/bash

CLIENT=$1
SERVERNAME=$2
FQDN=$3
IP=$4

echo "Doing first time setup: ${CLIENT} on ${SERVERNAME} @ ${IP}"
echo 

echo -n "Enter your Fullname: "
read FULLNAME
echo -n "Enter your Bazaar username: "
read USERNAME
echo -n "Enter your email address: "
read EMAIL

bzr whoami "${FULLNAME} <${EMAIL}>"

cd 
mkdir -p .bazaar/plugins
cd .bazaar/plugins/
bzr branch bzr+ssh://${USERNAME}@svn.obsidian.com.au/home/bzr/.plugins/obsidian/
cd obsidian
bzr obs-login $USERNAME
cd

echo -n "Enter the client [${CLIENT}]: "
read REPO
echo -n "Enter the branch [central]: "
read BRANCH

bzr obs-branch --repo=${BRANCH:-central} ${REPO:-$CLIENT} ${REPO:-$CLIENT}-${BRANCH:-central}
ln -sv ${REPO:-$CLIENT}-${BRANCH:-central} Jet
cd Jet/etc
ln -s ../local/etc/licence.key .
ln -s ../local/etc/realm-${CLIENT}.cfg realm.cfg
ln -s ../local/etc/local-${CLIENT}.cfg local.cfg
cd 

if [ -e /opt/Reports ]; then
    cd Jet/local/var/
    ln -s /opt/Reports reports_repo
    cd 
fi

cd Jet/modules/pylonfe
python setup.py egg_info
cd pylonfe/public
ln -s jQuery-1.10.2 jQuery
ln -s DataTables-1.9.4 DataTables
cd 

cd Jet/modules/reportfe
python setup.py egg_info
cd 

cd 
mkdir Jet/var/log/supervisord
touch Jet/var/log/supervisord/pylons.log
touch Jet/var/log/supervisord/pylons.err
touch Jet/var/log/supervisord/radius.log
touch Jet/var/log/supervisord/radius.err
touch Jet/var/log/supervisord/supervisord.log
chown jet:jet -R Jet/var/log

