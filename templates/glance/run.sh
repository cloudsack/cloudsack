#!/bin/bash
set -x

rm -rf /etc/glance/glance-api.conf && ln -s /opt/glance-api/glance-api.conf /etc/glance/glance-api.conf
rm -rf /etc/glance/glance-registry.conf && ln -s /opt/glance-registry/glance-registry.conf /etc/glance/glance-registry.conf
rm -rf /root/openrc && ln -s /opt/openrc/openrc /root/openrc

MYSQL="mysql -h${MYSQL_HOST} -uroot -p${MYSQL_ROOT_PASSWORD}"

${MYSQL} -e "CREATE DATABASE IF NOT EXISTS ${GLANCE_DB};"
${MYSQL} -e "GRANT ALL PRIVILEGES ON ${GLANCE_DB}.* TO \"${GLANCE_DBUSER}\"@'localhost' IDENTIFIED BY \"${GLANCE_DBPASS}\";\
                GRANT ALL PRIVILEGES ON ${GLANCE_DB}.* TO \"$GLANCE_DBUSER\"@'%' IDENTIFIED BY \"${GLANCE_DBPASS}\";"

# Populate the glance service database
su -s /bin/sh -c "glance-manage db_sync" glance

/usr/bin/supervisord
