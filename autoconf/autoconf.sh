#!/bin/bash
MYIP=`ifconfig eth0 | perl -ne 'print $1 if m/inet addr:(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/'`
MYHOSTNAME=`hostname`
MYDOMAINS=`dig ${MYHOSTNAME}.szkolenie.dnssec.pl txt +short | sort | tr -d '"' | tr "\n" " "`

echo -e "\n\tIP:\t$MYIP"
echo -e "\tDOMENY:\t$MYDOMAINS\n"

read -p "Przeprowadzić autokonfigurację? (t/n)" choice
case "$choice" in 
  t|T ) echo "Autokonfiguracja...";;
  n|N ) exit 0;;
  * ) exit 1;;
esac

echo "deb http://ftp.debian.org/debian jessie-backports main" >> /etc/apt/sources.list
[ $? -ne 0 ] && exit 1

apt-get update
[ $? -ne 0 ] && exit 1

apt-get install bind9 --yes
[ $? -ne 0 ] && exit 1


cp named.conf.options /etc/bind/named.conf.options
[ $? -ne 0 ] && exit 1

echo 'include "/etc/bind/named.conf.zones";' >> /etc/bind/named.conf
[ $? -ne 0 ] && exit 1


touch /etc/bind/named.conf.zones
[ $? -ne 0 ] && exit 1

chgrp bind /etc/bind/named.conf.zones 
[ $? -ne 0 ] && exit 1


mkdir /etc/bind/zones
[ $? -ne 0 ] && exit 1

chown -R bind:bind /etc/bind/zones
[ $? -ne 0 ] && exit 1


for MYDOMAIN in $MYDOMAINS
do
	cat zone-conf-tpl >> /etc/bind/named.conf.zones
	[ $? -ne 0 ] && exit 1

	sed "s/_MYDOMAIN_/$MYDOMAIN/g" -i /etc/bind/named.conf.zones
	[ $? -ne 0 ] && exit 1

	cp zone-tpl /etc/bind/zones/$MYDOMAIN
	[ $? -ne 0 ] && exit 1

	sed "s/_MYDOMAIN_/$MYDOMAIN/g" -i /etc/bind/zones/$MYDOMAIN
	[ $? -ne 0 ] && exit 1

	sed "s/_MYIP_/$MYIP/g" -i /etc/bind/zones/$MYDOMAIN
	[ $? -ne 0 ] && exit 1

done

rndc reconfig

sleep 2

for MYDOMAIN in $MYDOMAINS
do
	echo ""
	echo "dig test.$MYDOMAIN TXT +short @8.8.8.8"
	dig test.$MYDOMAIN TXT +short @8.8.8.8
done
echo ""
