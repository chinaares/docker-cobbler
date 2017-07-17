#!/bin/bash

if [ $# -ne 5 ]; then
	prog=`basename $0`
	echo "Usage $prog <short-hostname> <eth0> <eth1> <eth2> <eth3>" >&2
	exit -1
fi

set -xe

name=$1
mac0=$2
mac1=$3
mac2=$4
mac3=$5

ipaddr0=`gethostip -d $name`
ipaddr1=`echo $ipaddr0 | sed 's/1\.2\.3\.\([0-9]*\)/1.2.250.\1/'`

cobbler system remove --name="$name"
cobbler system add --name="$name" --hostname="$name.example.com" --profile=CentOS-5-x86_64-database

cobbler system edit --name="$name" --interface=eth0 --mac="$mac0" --bonding=slave --bonding-master=bond0
cobbler system edit --name="$name" --interface=eth1 --mac="$mac1" --bonding=slave --bonding-master=bond0
cobbler system edit --name="$name" --interface=bond0 --bonding=master --bonding-opts="mode=802.3ad miimon=100"
cobbler system edit --name="$name" --interface=bond0 --ip-address="$ipaddr0" --static=1 --subnet=255.255.255.0  --gateway=1.2.3.1

cobbler system edit --name="$name" --interface=eth2 --mac="$mac2" --bonding=slave --bonding-master=bond1
cobbler system edit --name="$name" --interface=eth3 --mac="$mac3" --bonding=slave --bonding-master=bond1
cobbler system edit --name="$name" --interface=bond1 --bonding=master --bonding-opts="mode=802.3ad miimon=100"
cobbler system edit --name="$name" --interface=bond1 --ip-address="$ipaddr1" --static=1 --subnet=255.255.255.0
