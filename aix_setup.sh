#!/bin/sh -v

ifconfig bridge1 create
ifconfig bridge1 192.168.100.1/24 up
sysctl -w net.inet.ip.forwarding=1
sysctl -w net.link.ether.inet.proxyall=1
pfctl -F all
pfctl -f "C:\Users\Youssef Sbai Idrissi\Downloads\AIX\aix_nat_config"
