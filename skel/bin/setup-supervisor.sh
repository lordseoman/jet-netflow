#!/bin/bash

if [ ! -e /etc/supervisord.conf ]; then
    echo " - configuring supervisor"
    mkdir /etc/supervisord
    cd /etc/supervisord 
    ln -s /home/jet/Jet jet
    ln -s jet/var/log/supervisor logs
    mkdir conf.d
    cd conf.d
    ln -s ../jet/modules/reportfe/supervisord.conf reports.conf
    ln -s ../jet/modules/pylonfe/supervisord.conf pylons.conf
    cd ../
    ln -s jet/local/etc/supervisord/supervisord.conf . 
    cd ../
    ln -s supervisord/supervisord.conf .
fi
