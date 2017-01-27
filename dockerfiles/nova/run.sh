#!/bin/bash
NOVA_FILE=/etc/nova/nova.conf
NOVA_DBPASS=${NOVA_DBPASS:-devops}
MYSQL_HOST=${MYSQL_HOST:-mysql}
RABBITMQ_HOST=${RABBITMQ_HOST:-rabbitmq}
RABBITMQ_USER=${RABBITMQ_USER:-openstack}
RABBITMQ_PORT=${RABBITMQ_PORT:-5672}
RABBITMQ_PASSWORD=${RABBITMQ_PASSWORD:-devops}
KEYSTONE_HOST=${KEYSTONE_HOST:-keystone}
MEMCACHED_HOST=${MEMCACHED_HOST:-memcached}
GLANCE_HOST=${GLANCE_HOST:-glance}
MEMCACHED_PORT=${MEMCACHED_PORT:-11211}
PROJECT_DOMAIN=${PROJECT_DOMAIN:-default}
USER_DOMAIN=${USER_DOMAIN:-default}
PROJECT_NAME=${PROJECT_NAME:-service}
NOVA_USER=${NOVA_USER:-nova}
NOVA_HOST=${NOVA_HOST:-nova}
NOVA_IP=`hostname -i`
NEUTRON_HOST=${NEUTRON_HOST:-neutron}
REGION=${REGION:-RegionOne}
NEUTRON_USER=${NEUTRON_USER:-neutron}
NEUTRON_PASSWORD=${NEUTRON_PASSWORD:-devops}
METADATA_SECRET=${METADATA_SECRET:-openstack}
NOVA_DB=${NOVA_DB:-nova}
NOVA_API_DB=${NOVA_API_DB:-nova_api}
NOVA_DBUSER=${NOVA_DBUSER:-nova}
NOVA_PASSWORD=${NOVA_PASSWORD:-devops}
SERVICE_PORT=${SERVICE_PORT:-8774}

nova_config() {

MYSQL="mysql -h${MYSQL_HOST} -uroot -p${MYSQL_ROOT_PASSWORD}"
${MYSQL} -e "CREATE DATABASE IF NOT EXISTS ${NOVA_DB};"
${MYSQL} -e "CREATE DATABASE ${NOVA_API_DB};"
${MYSQL} -e "GRANT ALL PRIVILEGES ON ${NOVA_DB}.* TO \"${NOVA_DBUSER}\"@'localhost' IDENTIFIED BY \"${NOVA_DBPASS}\";\
                GRANT ALL PRIVILEGES ON ${NOVA_DB}.* TO \"$NOVA_DBUSER\"@'%' IDENTIFIED BY \"${NOVA_DBPASS}\";"
${MYSQL} -e "GRANT ALL PRIVILEGES ON ${NOVA_API_DB}.* TO \"${NOVA_DBUSER}\"@'localhost' IDENTIFIED BY \"${NOVA_DBPASS}\";\
                GRANT ALL PRIVILEGES ON ${NOVA_API_DB}.* TO \"$NOVA_DBUSER\"@'%' IDENTIFIED BY \"${NOVA_DBPASS}\";"

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

if [ "`openstack user list | grep ${NOVA_USER}`" ]
then
	:
else
	openstack user create --domain default --password ${NOVA_PASSWORD} ${NOVA_USER}
	openstack role add --project service --user ${NOVA_USER} admin
	openstack service create --name nova compute
	openstack endpoint create --region $REGION compute  public http://${NOVA_HOST}:${SERVICE_PORT}/v2.1/%(tenant_id)s
	openstack endpoint create --region $REGION compute internal http://${NOVA_HOST}:${SERVICE_PORT}/v2.1/%(tenant_id)s
	openstack endpoint create --region $REGION compute admin http://${NOVA_HOST}:${SERVICE_PORT}/v2.1/%(tenant_id)s

fi

sed -i 's/enabled_apis[ =].*/enabled_apis = osapi_compute,metadata/' ${NOVA_FILE}

echo -e "\n[api_database]" >> ${NOVA_FILE}
echo -e "connection = mysql+pymysql://nova:${NOVA_DBPASS}@${MYSQL_HOST}/nova_api" >> ${NOVA_FILE}

echo -e "\n[database]" >> ${NOVA_FILE}
echo -e "connection = mysql+pymysql://nova:${NOVA_DBPASS}@${MYSQL_HOST}/nova" >> ${NOVA_FILE}

sed -i "/\[DEFAULT\]/a rpc_backend = rabbit\nauth_strategy = keystone\nmy_ip = ${NOVA_IP}\nuse_neutron = True\nfirewall_driver = nova.virt.firewall.NoopFirewallDriver" ${NOVA_FILE}

echo -e "\n[oslo_messaging_rabbit]" >> ${NOVA_FILE}
echo -e "rabbit_host = ${RABBITMQ_HOST}\nrabbit_userid = ${RABBITMQ_USER}\nrabbit_password = ${RABBITMQ_PASSWORD}" >> ${NOVA_FILE}

echo -e "\n[keystone_authtoken]\nauth_uri = http://${KEYSTONE_HOST}:5000\nauth_url = http://${KEYSTONE_HOST}:35357\nmemcached_servers = ${MEMCACHED_HOST}:${MEMCACHED_PORT}\nauth_type = password\nproject_domain_name = ${PROJECT_DOMAIN}\nuser_domain_name = ${USER_DOMAIN}\nproject_name = ${PROJECT_NAME}\nusername = ${NOVA_USER}\npassword = ${NOVA_PASSWORD}" >> ${NOVA_FILE}

echo -e "\n[vnc]\nvncserver_listen = \$my_ip\nvncserver_proxyclient_address = \$my_ip" >> ${NOVA_FILE}

echo -e "\n[glance]\napi_servers = http://${GLANCE_HOST}:9292" >> ${NOVA_FILE}

echo -e "\n[oslo_concurrency]\nlock_path = /var/lib/nova/tmp" >> ${NOVA_FILE}

echo -e "\n[neutron]\nurl = http://${NEUTRON_HOST}:9696\nauth_url = http://${KEYSTONE_HOST}:35357\nauth_type = password\nproject_domain_name = ${PROJECT_DOMAIN}\nuser_domain_name = ${USER_DOMAIN}\nregion_name = ${REGION}\nproject_name = ${PROJECT_NAME}\nusername = ${NEUTRON_USER}\npassword = ${NEUTRON_PASSWORD}\n\nservice_metadata_proxy = True\nmetadata_proxy_shared_secret = ${METADATA_SECRET}" >> ${NOVA_FILE}

echo -e "\n[cinder]\nos_region_name = ${REGION}" >> ${NOVA_FILE}

su -s /bin/sh -c "nova-manage api_db sync" nova
su -s /bin/sh -c "nova-manage db sync" nova
rm /var/lib/nova/nova.sqlite
}
if [ ! -f ~/openrc ]; then
	nova_config
fi
/usr/bin/supervisord
