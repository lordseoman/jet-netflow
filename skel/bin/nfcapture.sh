#!/bin/bash

/usr/local/bin/nfcapd -T+3,+6 -w -p 9995 \
  -P /opt/netflowv9/nfcapd.pid \
  -n ExindaNewP,10.255.101.10,/Netflow/incoming/ExindaNewP \
  -n ExindaNewS,10.255.101.20,/Netflow/incoming/ExindaNewS

