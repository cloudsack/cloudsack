#!/bin/bash
set -x

ADMIN_PASSWORD=${ADMIN_PASSWORD:-devops}
MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD:-devops}
GLANCE_PASSWORD=${GLANCE_PASSWORD:-devops}
GLANCE_FILES="/etc/glance/glance-registry.conf /etc/glance/glance-api.conf"
GLANCE_DBPASS=${GLANCE_DBPASS:-devops}
MYSQL_HOST=${MYSQL_HOST:-mysql}
KEYSTONE_HOST=${KEYSTONE_HOST:-keystone}
MEMCACHED_HOST=${MEMCACHED_HOST:-memcached}
GLANCE_HOST=${GLANCE_HOST:-glance}
PROJECT_DOMAIN=${PROJECT_DOMAIN:-default}
USER_DOMAIN=${USER_DOMAIN:-default}
PROJECT_NAME=${PROJECT_NAME:-service}
GLANCE_USER=${GLANCE_USER:-glance}
GLANCE_DB=${GLANCE_DB:-glance}
GLANCE_DBUSER=${GLANCE_DBUSER:-glance}
GLANCE_DBPASS=${GLANCE_DBPASS:-devops}
REGION=${REGION:-RegionOne}
SERVICE_PORT=${SERVICE_PORT:-9292}

glance_config() {

MYSQL="mysql -h${MYSQL_HOST} -uroot -p${MYSQL_ROOT_PASSWORD}"
${MYSQL} -e "CREATE DATABASE IF NOT EXISTS ${GLANCE_DB};"
${MYSQL} -e "GRANT ALL PRIVILEGES ON ${GLANCE_DB}.* TO \"${GLANCE_DBUSER}\"@'localhost' IDENTIFIED BY \"${GLANCE_DBPASS}\";\
                GRANT ALL PRIVILEGES ON ${GLANCE_DB}.* TO \"$GLANCE_DBUSER\"@'%' IDENTIFIED BY \"${GLANCE_DBPASS}\";"

for GLANCE_FILE in $GLANCE_FILES
do
	sed -i "s,^sqlite_db[ =].*,connection = mysql+pymysql://${GLANCE_DBUSER}:${GLANCE_DBPASS}@${MYSQL_HOST}/${GLANCE_DB}," $GLANCE_FILE

	sed -i "/\[keystone_authtoken\]/a auth_uri = http://${KEYSTONE_HOST}:5000\nauth_url = http://${KEYSTONE_HOST}:35357\nmemcached_servers = ${MEMCACHED_HOST}:11211\nauth_type = password\nproject_domain_name = ${PROJECT_DOMAIN}\nuser_domain_name = ${USER_DOMAIN}\nproject_name = ${PROJECT_NAME}\nusername = ${GLANCE_USER}\npassword =$GLANCE_PASSWORD " $GLANCE_FILE

	sed -i "/\[paste_deploy\]/a flavor = keystone" $GLANCE_FILE

done

sed -i "/\[glance_store\]/a stores = file,http\ndefault_store = file\nfilesystem_store_datadir = \/var\/lib\/glance\/images/" $GLANCE_FILE

su -s /bin/sh -c "glance-manage db_sync" glance

cat >~/openrc <<EOF
export OS_PROJECT_DOMAIN_NAME=default
export OS_USER_DOMAIN_NAME=default
export OS_PROJECT_NAME=admin
export OS_USERNAME=admin
export OS_PASSWORD=${ADMIN_PASSWORD}
export OS_AUTH_URL=http://${KEYSTONE_HOST}:35357/v3
export OS_IDENTITY_API_VERSION=3
export OS_IMAGE_API_VERSION=2
EOF

source ~/openrc

openstack user create --domain default --password ${GLANCE_PASSWORD} ${GLANCE_USER}
openstack role add --project service --user ${GLANCE_USER} admin
openstack service create --name glance image
openstack endpoint create --region $REGION image public http://${GLANCE_HOST}:${SERVICE_PORT}
openstack endpoint create --region $REGION image internal http://${GLANCE_HOST}:${SERVICE_PORT}
openstack endpoint create --region $REGION image admin http://${GLANCE_HOST}:${SERVICE_PORT}

}
if [ ! -f ~/openrc ]; then
	glance_config
fi

/usr/bin/supervisord
