#!/bin/bash

source ~/openrc
cd /etc/swift
ACCOUNT_PORT=${ACCOUNT_PORT:-6002}
CONTAINER_PORT=${CONTAINER_PORT:-6001}
OBJECT_PORT=${OBJECT_PORT:-6000}
REGION_NUMBER=${REGION_NUMBER:-1}
ZONE_NUMBER=${ZONE_NUMBER:-1}
WEIGHT=${WEIGHT:-100}
REPLICA_COUNT=${REPLICA_COUNT:-2}

#Make etc/hosts entry
for i in `echo $1 | sed 's/,/ /g'`
do
	entry=`echo $i | sed 's/:/ /g'`
	echo $entry >> /etc/hosts
done
build_ring(){
	ring_type=$1
	port=$2
swift-ring-builder ${ring_type}.builder create 10 ${REPLICA_COUNT} 1

for storage_node in ${STORAGE_NODES}
do
	for mounts in `echo ${SWIFT_DEVICES} | sed 's/,/ /'`
        do
                device=`echo $mounts | awk -F '/' '{print $NF}'`
		swift-ring-builder ${ring_type}.builder add --region ${REGION_NUMBER} --zone ${ZONE_NUMBER} --ip ${storage_node} --port ${port} --device ${device} --weight ${WEIGHT}
	done
done

swift-ring-builder ${ring_type}.builder rebalance
}

build_ring account ${ACCOUNT_PORT}
build_ring container ${CONTAINER_PORT}
build_ring object ${OBJECT_PORT}

supervisorctl restart proxy_server
