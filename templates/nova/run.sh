#!/bin/bash

rm -rf /etc/nova/nova.conf && ln -s /opt/nova-conf/nova.conf /etc/nova/nova.conf
rm -rf /root/openrc && ln -s /opt/openrc/openrc /root/openrc

NOVA_DB=${NOVA_DB:-nova}
NOVA_API_DB=${NOVA_API_DB:-nova_api}

MYSQL="mysql -h${MYSQL_HOST} -uroot -p${MYSQL_ROOT_PASSWORD}"
${MYSQL} -e "CREATE DATABASE IF NOT EXISTS ${NOVA_DB};"
${MYSQL} -e "CREATE DATABASE IF NOT EXISTS ${NOVA_API_DB};"
${MYSQL} -e "GRANT ALL PRIVILEGES ON ${NOVA_DB}.* TO \"${NOVA_DBUSER}\"@'localhost' IDENTIFIED BY \"${NOVA_DBPASS}\";\
                GRANT ALL PRIVILEGES ON ${NOVA_DB}.* TO \"$NOVA_DBUSER\"@'%' IDENTIFIED BY \"${NOVA_DBPASS}\";"
${MYSQL} -e "GRANT ALL PRIVILEGES ON ${NOVA_API_DB}.* TO \"${NOVA_DBUSER}\"@'localhost' IDENTIFIED BY \"${NOVA_DBPASS}\";\
                GRANT ALL PRIVILEGES ON ${NOVA_API_DB}.* TO \"$NOVA_DBUSER\"@'%' IDENTIFIED BY \"${NOVA_DBPASS}\";"

su -s /bin/sh -c "nova-manage api_db sync" nova
su -s /bin/sh -c "nova-manage db sync" nova
rm -rf /var/lib/nova/nova.sqlite

/usr/bin/supervisord
