#!/bin/bash
set -e

apt-get update
apt-get install dnsutils -y

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

apt-get update
apt-get install bind9 --yes
apt-get install vim --yes

cp named.conf.options /etc/bind/named.conf.options
echo 'include "/etc/bind/named.conf.zones";' >> /etc/bind/named.conf
touch /etc/bind/named.conf.zones
chgrp bind /etc/bind/named.conf.zones 

mkdir /etc/bind/zones

for MYDOMAIN in $MYDOMAINS
do
	cat zone-conf-tpl >> /etc/bind/named.conf.zones
	sed "s/_MYDOMAIN_/$MYDOMAIN/g" -i /etc/bind/named.conf.zones

	cp zone-tpl /etc/bind/zones/$MYDOMAIN
	sed "s/_MYDOMAIN_/$MYDOMAIN/g" -i /etc/bind/zones/$MYDOMAIN
	sed "s/_MYIP_/$MYIP/g" -i /etc/bind/zones/$MYDOMAIN
done

chown -R bind:bind /etc/bind/zones

service bind9 restart

sleep 2

for MYDOMAIN in $MYDOMAINS
do
	echo ""
	echo "dig test.$MYDOMAIN TXT +short @8.8.8.8"
	dig test.$MYDOMAIN TXT +short @8.8.8.8
done
echo ""
