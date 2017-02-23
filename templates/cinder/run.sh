#!/bin/bash

rm -rf /etc/cinder/cinder.conf && ln -s /opt/cinder-conf/cinder.conf /etc/cinder/cinder.conf
rm -rf /etc/cinder/glusterfs_shares && ln -s /opt/cinder-glusterfs/glusterfs_shares /etc/cinder/glusterfs_shares
rm -rf /root/openrc && ln -s /opt/openrc/openrc /root/openrc

MYSQL="mysql -h${MYSQL_HOST} -uroot -p${MYSQL_ROOT_PASSWORD}"
${MYSQL} -e "CREATE DATABASE IF NOT EXISTS ${CINDER_DB};"
${MYSQL} -e "GRANT ALL PRIVILEGES ON ${CINDER_DB}.* TO \"${CINDER_DBUSER}\"@'localhost' IDENTIFIED BY \"${CINDER_DBPASS}\";\
                GRANT ALL PRIVILEGES ON ${CINDER_DB}.* TO \"$CINDER_DBUSER\"@'%' IDENTIFIED BY \"${CINDER_DBPASS}\";"


su -s /bin/sh -c "cinder-manage db sync" cinder

rm -rf /var/lib/cinder/cinder.sqlite
chown root:cinder /etc/cinder/glusterfs_shares
chmod 0640 /etc/cinder/glusterfs_shares

/usr/bin/supervisord
