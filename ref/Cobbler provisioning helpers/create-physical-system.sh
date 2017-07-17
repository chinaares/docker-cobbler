#!/bin/bash

set -xe

name=$1
mac0=$2
mac1=$3
ipaddr=`gethostip -d $name`

cobbler system add --name="$name" --hostname="$name.example.com" --profile=CentOS-5-x86_64
cobbler system edit --name="$name" --interface=eth0 --mac="$mac0" --bonding=slave --bonding-master=bond0
cobbler system edit --name="$name" --interface=eth1 --mac="$mac1" --bonding=slave --bonding-master=bond0
cobbler system edit --name="$name" --interface=bond0 --bonding=master --bonding-opts="mode=802.3ad miimon=100"
cobbler system edit --name="$name" --interface=bond0 --ip-address="$ipaddr" --static=1 --subnet=255.255.255.0  --gateway=1.2.3.1
