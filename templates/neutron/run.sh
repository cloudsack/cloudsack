#!/bin/bash

rm -rf /etc/neutron/neutron.conf && ln -s /opt/neutron-conf/neutron.conf /etc/neutron/neutron.conf
rm -rf /etc/neutron/plugins/ml2/ml2_conf.ini && ln -s /opt/neutron-ml2/ml2_conf.ini /etc/neutron/plugins/ml2/ml2_conf.ini
rm -rf /etc/neutron/plugins/ml2/linuxbridge_agent.ini && ln -s /opt/neutron-linuxbridge/linuxbridge_agent.ini /etc/neutron/plugins/ml2/linuxbridge_agent.ini
rm -rf /etc/neutron/l3_agent.ini && ln -s /opt/neutron-l3/l3_agent.ini /etc/neutron/l3_agent.ini
rm -rf /etc/neutron/dhcp_agent.ini && ln -s /opt/neutron-dhcp/dhcp_agent.ini /etc/neutron/dhcp_agent.ini
rm -rf /etc/neutron/metadata_agent.ini && ln -s /opt/neutron-metadata/metadata_agent.ini /etc/neutron/metadata_agent.ini
rm -rf /root/openrc && ln -s /opt/openrc/openrc /root/openrc

OVERLAY_INTERFACE_IP_ADDRESS=`hostname -i`

echo -e "nameserver ${KUBE_NAMESERVER} \n nameserver ${HOST_NAMESERVER}" > /etc/resolv.conf

MYSQL="mysql -h${MYSQL_HOST} -uroot -p${MYSQL_ROOT_PASSWORD}"
${MYSQL} -e "CREATE DATABASE IF NOT EXISTS ${NEUTRON_DB};"
${MYSQL} -e "GRANT ALL PRIVILEGES ON ${NEUTRON_DB}.* TO \"${NEUTRON_DBUSER}\"@'localhost' IDENTIFIED BY \"${NEUTRON_DBPASS}\";\
                GRANT ALL PRIVILEGES ON ${NEUTRON_DB}.* TO \"$NEUTRON_DBUSER\"@'%' IDENTIFIED BY \"${NEUTRON_DBPASS}\";"


echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf
echo 'net.ipv4.conf.default.rp_filter=0' >> /etc/sysctl.conf
echo 'net.ipv4.conf.all.rp_filter=0' >> /etc/sysctl.conf
sysctl -p

sed -i "/\[vxlan\]/a local_ip = $OVERLAY_INTERFACE_IP_ADDRESS" /etc/neutron/plugins/ml2/linuxbridge_agent.ini

ln -s /etc/neutron/plugins/ml2/ml2_conf.ini /etc/neutron/plugin.ini 

rm -rf /var/lib/neutron/neutron.sqlite

su -s /bin/sh -c "neutron-db-manage --config-file /etc/neutron/neutron.conf --config-file /etc/neutron/plugins/ml2/ml2_conf.ini upgrade head" neutron

/usr/bin/supervisord
