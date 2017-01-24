#!/bin/bash


sed -i "s/-l .*/-l `hostname -i`/" /etc/memcached.conf

/usr/bin/memcached -u root -S -l 0.0.0.0
