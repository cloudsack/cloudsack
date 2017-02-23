#!/bin/bash
set -x

rm -rf /etc/heat/heat.conf && ln -s /opt/heat/heat.conf /etc/heat/heat.conf
rm -rf /root/openrc && ln -s /opt/openrc/openrc /root/openrc

MYSQL="mysql -h${MYSQL_HOST} -uroot -p${MYSQL_ROOT_PASSWORD}"
${MYSQL} -e "CREATE DATABASE IF NOT EXISTS ${HEAT_DB};"
${MYSQL} -e "GRANT ALL PRIVILEGES ON ${HEAT_DB}.* TO \"${HEAT_DBUSER}\"@'localhost' IDENTIFIED BY \"${HEAT_DBPASS}\";\
                GRANT ALL PRIVILEGES ON ${HEAT_DB}.* TO \"$HEAT_DBUSER\"@'%' IDENTIFIED BY \"${HEAT_DBPASS}\";"

su -s /bin/sh -c "heat-manage db_sync" heat

/usr/bin/supervisord
