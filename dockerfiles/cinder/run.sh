#!/bin/bash
CINDER_FILE=/etc/cinder/cinder.conf
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
CINDER_USER=${CINDER_USER:-cinder}
CINDER_IP=`hostname -i`
REGION=${REGION:-RegionOne}
CINDER_DB=${CINDER_DB:-cinder}
CINDER_DBUSER=${CINDER_DBUSER:-cinder}
CINDER_DBPASS=${CINDER_DBPASS:-devops}
CINDER_PASSWORD=${CINDER_PASSWORD:-devops}
SERVICE_PORT=${SERVICE_PORT:-8776}
GLANCE_HOST=${GLANCE_HOST:-glance}
GLANCE_PORT=${GLANCE_PORT:-9292}
BACKEND_DRIVER=${BACKEND_DRIVER:-nfs}
NFS_HOST=${NFS_HOST:-nfs}
NFS_EXPORT_DIR=${NFS_EXPORT_DIR:-/nfs}

cinder_config() {

MYSQL="mysql -h${MYSQL_HOST} -uroot -p${MYSQL_ROOT_PASSWORD}"
${MYSQL} -e "CREATE DATABASE IF NOT EXISTS ${CINDER_DB};"
${MYSQL} -e "GRANT ALL PRIVILEGES ON ${CINDER_DB}.* TO \"${CINDER_DBUSER}\"@'localhost' IDENTIFIED BY \"${CINDER_DBPASS}\";\
                GRANT ALL PRIVILEGES ON ${CINDER_DB}.* TO \"$CINDER_DBUSER\"@'%' IDENTIFIED BY \"${CINDER_DBPASS}\";"

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
if [ "`openstack user list | grep ${CINDER_USER}`" ]
then
	:
else
	openstack user create --domain default --password ${CINDER_PASSWORD} ${CINDER_USER}
	openstack role add --project service --user ${CINDER_USER} admin
	openstack service create --name cinder volume
	openstack service create --name cinderv2 volumev2
	openstack endpoint create --region $REGION volume  public http://${HOSTNAME}:${SERVICE_PORT}/v1/%(tenant_id)s
	openstack endpoint create --region $REGION volume internal http://${HOSTNAME}:${SERVICE_PORT}/v1/%(tenant_id)s
	openstack endpoint create --region $REGION volume admin http://${HOSTNAME}:${SERVICE_PORT}/v1/%(tenant_id)s
	openstack endpoint create --region $REGION volumev2  public http://${HOSTNAME}:${SERVICE_PORT}/v2/%(tenant_id)s
	openstack endpoint create --region $REGION volumev2 internal http://${HOSTNAME}:${SERVICE_PORT}/v2/%(tenant_id)s
	openstack endpoint create --region $REGION volumev2 admin http://${HOSTNAME}:${SERVICE_PORT}/v2/%(tenant_id)s
fi

echo -e "\n[database]\nconnection = mysql+pymysql://${CINDER_DBUSER}:${CINDER_DBPASS}@${MYSQL_HOST}/cinder" >> ${CINDER_FILE}

sed -i "/^\[DEFAULT\]/a rpc_backend = rabbit\nmy_ip = ${CINDER_IP}\nglance_api_servers = http://${GLANCE_HOST}:${GLANCE_PORT}" ${CINDER_FILE}

echo -e "\n[oslo_messaging_rabbit]\nrabbit_host = ${RABBITMQ_HOST}\nrabbit_userid = ${RABBITMQ_USER}\nrabbit_password = ${RABBITMQ_PASSWORD}" >> ${CINDER_FILE}

echo -e "[keystone_authtoken]\nauth_uri = http://${KEYSTONE_HOST}:5000\nauth_url = http://${KEYSTONE_HOST}:35357\nmemcached_servers = ${MEMCACHED_HOST}:${MEMCACHED_PORT}\nauth_type = password\nproject_domain_name = ${PROJECT_DOMAIN}\nuser_domain_name = ${USER_DOMAIN}\nproject_name = ${PROJECT_NAME}\nusername = ${CINDER_USER}\npassword = ${CINDER_PASSWORD}" >> ${CINDER_FILE}


if [ ${BACKEND_DRIVER} == "nfs"  ]; then
sed -i "/^\[DEFAULT\]/a enabled_backends = ${BACKEND_DRIVER}"  ${CINDER_FILE}
echo -e "${NFS_HOST}:${NFS_EXPORT_DIR}" >> /etc/cinder/nfs_shares
chown root:cinder /etc/cinder/nfs_shares
chmod 0640 /etc/cinder/nfs_shares
mkdir -p /var/lib/cinder/nfs
echo -e "[nfs] \nvolume_driver = cinder.volume.drivers.nfs.NfsDriver\nnfs_shares_config = /etc/cinder/nfs_shares\nnfs_mount_point_base = /var/lib/cinder/nfs" >> ${CINDER_FILE}
fi

echo -e "\n[oslo_concurrency]\nlock_path = /var/lib/cinder/tmp" >> ${CINDER_FILE}

su -s /bin/sh -c "cinder-manage db sync" cinder

rm /var/lib/cinder/cinder.sqlite
}
if [ ! -f ~/openrc ]; then
	cinder_config
fi
/usr/bin/supervisord
