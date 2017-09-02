#!/bin/bash

echo 0 > /sys/module/dvb_core/parameters/dvb_powerdown_on_sleep

# Workaround for Astrometa DVB-T/T2/C USB-Stick to change frontends and make it work with dvbtune
frontend0realtek=`dvbsnoop -frontend /dev/dvb/adapter0/frontend0 -s feinfo | grep Realtek | wc -l`
frontend1panasonic=`dvbsnoop -frontend /dev/dvb/adapter0/frontend1 -s feinfo | grep Panasonic | wc -l`
if [ $frontend0realtek == "1" ] && [ $frontend1panasonic == "1" ]; then
    mv /dev/dvb/adapter0/frontend0 /dev/dvb/adapter0/frontend2
    mv /dev/dvb/adapter0/frontend1 /dev/dvb/adapter0/frontend0
    mv /dev/dvb/adapter0/frontend2 /dev/dvb/adapter0/frontend1
    dvb-fe-tool --adapter=0 --frontend=0 --set-delsys=DVB-C
fi

freq256="546000000 554000000 562000000 570000000 578000000 586000000 594000000 602000000 666000000 674000000 682000000 690000000"
freq64="698000000 706000000 714000000 722000000 762000000 770000000 778000000 786000000 794000000 802000000 810000000 818000000"

influxhost="influxhost"
influxuser="user"
influxpass="pass"
influxdb="db"

for freq1 in $freq256
do
   ps -ef | grep dvbsnoop | awk '{print $2}' | xargs kill -9
   frequency=`dvbtune -f $freq1 -s 6952 -qam 256 2>&1 | grep 'tuning DVB-C' | cut -d "," -f1 | cut -d " " -f4`
   bw=`dvbsnoop -s bandwidth 8190 -n 3000 -hideproginfo | awk -F: 'END { print $NF }' | sed 's/^[ \t]*//' | awk '{print $1*1000}'`
   curl -i -XPOST "http://$influxhost:8086/write?db=$influxdb" --data-binary "docsis,freq=$freq1 value=$bw"
#   curl -i -XPOST "http://$influxhost:8086/write?db=$influxdb&u=$influxuser&p=$influxpass" --data-binary "docsis,freq=$freq1 value=$bw"
done

for freq1 in $freq64
do
   ps -ef | grep dvbsnoop | awk '{print $2}' | xargs kill -9
   frequency=`dvbtune -f $freq1 -s 6952 -qam 64 2>&1 | grep 'tuning DVB-C' | cut -d "," -f1 | cut -d " " -f4`
   bw=`dvbsnoop -s bandwidth 8190 -n 3000 -hideproginfo | awk -F: 'END { print $NF }' | sed 's/^[ \t]*//' | awk '{print $1*1000}'`
   curl -i -XPOST "http://$influxhost:8086/write?db=$influxdb" --data-binary "docsis,freq=$freq1 value=$bw"
#   curl -i -XPOST "http://$influxhost:8086/write?db=$influxdb&u=$influxuser&p=$influxpass" --data-binary "docsis,freq=$freq1 value=$bw"
done
