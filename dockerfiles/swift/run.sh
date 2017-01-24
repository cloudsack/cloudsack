#!/bin/bash
set -x
SWIFT_PROXY_FILE=/etc/swift/proxy-server.conf
SWIFT_FILE=/etc/swift/swift.conf
MYSQL_HOST=${MYSQL_HOST:-mysql}
RABBITMQ_HOST=${RABBITMQ_HOST:-rabbitmq}
RABBITMQ_USER=${RABBITMQ_USER:-openstack}
RABBITMQ_PORT=${RABBITMQ_PORT:-5672}
RABBITMQ_PASSWORD=${RABBITMQ_PASSWORD:-devops}
KEYSTONE_HOST=${KEYSTONE_HOST:-keystone}
MEMCACHED_HOST=${MEMCACHED_HOST:-memcached}
MEMCACHED_PORT=${MEMCACHED_PORT:-11211}
PROJECT_DOMAIN=${PROJECT_DOMAIN:-default}
USER_DOMAIN=${USER_DOMAIN:-default}
PROJECT_NAME=${PROJECT_NAME:-service}
SWIFT_USER=${SWIFT_USER:-swift}
SWIFT_IP=`hostname -i`
REGION_NAME=${REGION_NAME:-RegionOne}
SWIFT_DB=${SWIFT_DB:-swift}
SWIFT_DBUSER=${SWIFT_DBUSER:-swift}
SWIFT_DBPASS=${SWIFT_DBPASS:-devops}
SWIFT_PASSWORD=${SWIFT_PASSWORD:-devops}
SERVICE_PORT=${SERVICE_PORT:-8080}
SWIFT_HASH_PATH_SUFFIX=${SWIFT_HASH_PATH_SUFFIX:-hashsuffix}
SWIFT_HASH_PATH_PREFIX=${SWIFT_HASH_PATH_PREFIX:-hashprefix}

swift_config() {

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
openstack user create --domain default --password ${SWIFT_PASSWORD} ${SWIFT_USER}
openstack role add --project service --user ${SWIFT_USER} admin
openstack service create --name swift object-store
openstack endpoint create --region $REGION_NAME object-store  public http://${HOSTNAME}:${SERVICE_PORT}/v1/AUTH_%\(tenant_id\)s
openstack endpoint create --region $REGION_NAME object-store internal http://${HOSTNAME}:${SERVICE_PORT}/v1/AUTH_%\(tenant_id\)s
openstack endpoint create --region $REGION_NAME object-store admin http://${HOSTNAME}:${SERVICE_PORT}/v1/AUTH_%\(tenant_id\)s

sed -i "/\[filter:authtoken\]/a auth_uri = http://${KEYSTONE_HOST}:5000\nauth_url = http://${KEYSTONE_HOST}:35357\nmemcached_servers = ${MEMCACHED_HOST}:${MEMCACHED_PORT}\nauth_type = password\nproject_domain_name = ${PROJECT_DOMAIN}\nuser_domain_name = ${USER_DOMAIN}\nproject_name = ${PROJECT_NAME}\nusername = ${SWIFT_USER}\npassword = ${SWIFT_PASSWORD}\ndelay_auth_decision = True" ${SWIFT_PROXY_FILE}

sed -i "/\[filter:cache\]/a memcache_servers = ${MEMCACHED_HOST}:${MEMCACHED_PORT}" ${SWIFT_PROXY_FILE}

sed -i "s/^swift_hash_path_suffix.*/swift_hash_path_suffix = ${SWIFT_HASH_PATH_SUFFIX}/" ${SWIFT_FILE}

sed -i "s/^swift_hash_path_prefix.*/swift_hash_path_prefix = ${SWIFT_HASH_PATH_PREFIX}/" ${SWIFT_FILE}
}
if [ ! -f ~/openrc ]; then
	swift_config
fi
/usr/bin/supervisord
