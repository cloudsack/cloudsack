#!/bin/bash
set -x

rm -rf /etc/apache2/apache2.conf && ln -s /opt/conf/apache2.conf /etc/apache2/apache2.conf
rm -rf /etc/keystone/keystone.conf && ln -s /opt/keystone/keystone.conf /etc/keystone/keystone.conf
rm -rf /root/openrc && ln -s /opt/openrc/openrc /root/openrc

MYSQL="mysql -h${MYSQL_HOST} -uroot -p${MYSQL_ROOT_PASSWORD}"

${MYSQL} -e "CREATE DATABASE IF NOT EXISTS ${KEYSTONE_DB};"
${MYSQL} -e "GRANT ALL PRIVILEGES ON ${KEYSTONE_DB}.* TO \"${KEYSTONE_DBUSER}\"@'localhost' IDENTIFIED BY \"${KEYSTONE_DBPASS}\";\
                GRANT ALL PRIVILEGES ON ${KEYSTONE_DB}.* TO \"$KEYSTONE_DBUSER\"@'%' IDENTIFIED BY \"${KEYSTONE_DBPASS}\";"

# Populate the Identity service database
su -s /bin/sh -c "keystone-manage db_sync" keystone

# Initialize Fernet keys
keystone-manage fernet_setup --keystone-user keystone --keystone-group keystone

# Remove SQLite db
rm -rf /var/lib/keystone/keystone.db

source /etc/apache2/envvars

/usr/sbin/apache2 -DFOREGROUND
