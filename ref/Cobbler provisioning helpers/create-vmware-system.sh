#!/bin/bash

set -xe

mac=$1
name=$2
ipaddr=`gethostip -d $name`

cobbler system add --name="$name" --hostname="$name.example.com" --interface=eth0 --mac="$mac" --ip-address="$ipaddr" --static=1 --subnet=255.255.255.0  --gateway=1.2.3.1 --profile=CentOS-5-x86_64 
