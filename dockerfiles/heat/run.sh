#!/bin/bash
set -x

ADMIN_PASSWORD=${ADMIN_PASSWORD:-devops}
MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD:-devops}
HEAT_PASSWORD=${HEAT_PASSWORD:-devops}
HEAT_FILE=/etc/heat/heat.conf
HEAT_DBPASS=${HEAT_DBPASS:-devops}
MYSQL_HOST=${MYSQL_HOST:-mysql}
RABBITMQ_HOST=${RABBITMQ_HOST:-rabbitmq}
RABBITMQ_USER=${RABBITMQ_USER:-openstack}
RABBITMQ_PASSWORD=${RABBITMQ_PASSWORD:-devops}
KEYSTONE_HOST=${KEYSTONE_HOST:-keystone}
MEMCACHED_HOST=${MEMCACHED_HOST:-memcached}
PROJECT_DOMAIN=${PROJECT_DOMAIN:-default}
USER_DOMAIN=${USER_DOMAIN:-default}
PROJECT_NAME=${PROJECT_NAME:-service}
HEAT_HOST=${HEAT_HOST:-heat}
HEAT_USER=${HEAT_USER:-heat}
HEAT_DB=${HEAT_DB:-heat}
HEAT_DBUSER=${HEAT_DBUSER:-heat}
HEAT_DBPASS=${HEAT_DBPASS:-devops}
REGION=${REGION:-RegionOne}
SERVICE_ORCHESTRATION_PORT=${SERVICE_ORCHESTRATION_PORT:-8004}
SERVICE_CLOUDFORMATION_PORT=${SERVICE_CLOUDFORMATION_PORT:-8000}
HEAT_DOMAIN_ADMIN_PASSWORD=${HEAT_DOMAIN_ADMIN_PASSWORD:-devops}

heat_config() {

MYSQL="mysql -h${MYSQL_HOST} -uroot -p${MYSQL_ROOT_PASSWORD}"
${MYSQL} -e "CREATE DATABASE IF NOT EXISTS ${HEAT_DB};"
${MYSQL} -e "GRANT ALL PRIVILEGES ON ${HEAT_DB}.* TO \"${HEAT_DBUSER}\"@'localhost' IDENTIFIED BY \"${HEAT_DBPASS}\";\
                GRANT ALL PRIVILEGES ON ${HEAT_DB}.* TO \"$HEAT_DBUSER\"@'%' IDENTIFIED BY \"${HEAT_DBPASS}\";"

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

if [ "`openstack user list | grep ${HEAT_USER}`" ]
then
	:
else
	openstack user create --domain default --password ${HEAT_PASSWORD} ${HEAT_USER}
	openstack role add --project service --user ${HEAT_USER} admin
	openstack service create --name heat orchestration
	openstack service create --name heat-cfn cloudformation
	openstack endpoint create --region $REGION orchestration public http://${HEAT_HOST}:${SERVICE_ORCHESTRATION_PORT}/v1/%(tenant_id)s
	openstack endpoint create --region $REGION orchestration internal http://${HEAT_HOST}:${SERVICE_ORCHESTRATION_PORT}/v1/%(tenant_id)s
	openstack endpoint create --region $REGION orchestration admin http://${HEAT_HOST}:${SERVICE_ORCHESTRATION_PORT}/v1/%(tenant_id)s
	openstack endpoint create --region $REGION cloudformation public http://${HEAT_HOST}:${SERVICE_CLOUDFORMATION_PORT}/v1
	openstack endpoint create --region $REGION cloudformation internal http://${HEAT_HOST}:${SERVICE_CLOUDFORMATION_PORT}/v1
	openstack endpoint create --region $REGION cloudformation admin http://${HEAT_HOST}:${SERVICE_CLOUDFORMATION_PORT}/v1
	openstack domain create heat
	openstack user create --domain heat --password ${HEAT_DOMAIN_ADMIN_PASSWORD} heat_domain_admin
	openstack role add --domain heat --user-domain heat --user heat_domain_admin admin
	openstack role create heat_stack_owner
	openstack role add --project admin --user admin heat_stack_owner
	openstack role create heat_stack_user

fi

sed -i "/\[database\]/a connection = mysql+pymysql:\/\/${HEAT_DBUSER}:${HEAT_DBPASS}@${MYSQL_HOST}\/${HEAT_DB}" $HEAT_FILE

sed -i "s/#rpc_backend/rpc_backend/" ${HEAT_FILE}

sed -i "/\[oslo_messaging_rabbit\]/a rabbit_host = ${RABBITMQ_HOST}\nrabbit_userid = ${RABBITMQ_USER}\nrabbit_password = ${RABBITMQ_PASSWORD}" ${HEAT_FILE}

sed -i "/\[keystone_authtoken\]/a auth_uri = http://${KEYSTONE_HOST}:5000\nauth_url = http://${KEYSTONE_HOST}:35357\nmemcached_servers = ${MEMCACHED_HOST}:11211\nauth_type = password\nproject_domain_name = ${PROJECT_DOMAIN}\nuser_domain_name = ${USER_DOMAIN}\nproject_name = ${PROJECT_NAME}\nusername = ${HEAT_USER}\npassword =${HEAT_PASSWORD}" $HEAT_FILE

echo -e "\n[trustee]\nauth_plugin = password\nauth_url = http://${KEYSTONE_HOST}:35357\n\nusername = ${HEAT_USER}\npassword =${HEAT_PASSWORD}\nuser_domain_name = ${USER_DOMAIN}" >> ${HEAT_FILE}

echo -e "\n[clients_keystone]\nauth_uri = http://${KEYSTONE_HOST}:35357" >> ${HEAT_FILE}

echo -e "\n[ec2authtoken]\nauth_uri = http://${KEYSTONE_HOST}:5000" >> ${HEAT_FILE}

sed -i "/\[DEFAULT\]/a heat_metadata_server_url = http:\/\/${HEAT_HOST}:8000\nheat_waitcondition_server_url = http:\/\/${HEAT_HOST}:8000\/v1\/waitcondition\nstack_domain_admin = heat_domain_admin\nstack_domain_admin_password = ${HEAT_DOMAIN_ADMIN_PASSWORD}\nstack_user_domain_name = heat" ${HEAT_FILE}

su -s /bin/sh -c "heat-manage db_sync" heat

}
if [ ! -f ~/openrc ]; then
	heat_config
fi

/usr/bin/supervisord
