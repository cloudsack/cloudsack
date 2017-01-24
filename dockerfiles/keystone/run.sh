#!/bin/bash
set -x

ADMIN_TOKEN=${ADMIN_TOKEN:-ADMIN_TOKEN}
MYSQL_HOST=${MYSQL_HOST:-mysql}
KEYSTONE_FILE="/etc/keystone/keystone.conf"
ADMIN_USER=${ADMIN_USER:-admin}
ADMIN_PASSWORD=${ADMIN_PASSWORD:-devops}
REGION=${REGION:-RegionOne}
MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD:-devops}
KEYSTONE_DB=${KEYSTONE_DB:-keystone}
KEYSTONE_DBUSER=${KEYSTONE_DBUSER:-keystone}
KEYSTONE_DBPASS=${KEYSTONE_DBPASS:-devops}
KEYSTONE_HOST=${KEYSTONE_HOST:-keystone}

create_service_credentials() {
	CMD=$1
	c=0
	$CMD
	while [ $? -ne 0 ] && [ $c -lt 4 ]
	do
		sleep 5
		c=$((c+1))
		$CMD
	done
	if [ $? -ne 0 ]
	then
		echo -e "Problem in running:\n$CMD"
		exit 1
	fi
}

keystone_config() {

MYSQL="mysql -h${MYSQL_HOST} -uroot -p${MYSQL_ROOT_PASSWORD}"

${MYSQL} -e "CREATE DATABASE IF NOT EXISTS ${KEYSTONE_DB};"
${MYSQL} -e "GRANT ALL PRIVILEGES ON ${KEYSTONE_DB}.* TO \"${KEYSTONE_DBUSER}\"@'localhost' IDENTIFIED BY \"${KEYSTONE_DBPASS}\";\
                GRANT ALL PRIVILEGES ON ${KEYSTONE_DB}.* TO \"$KEYSTONE_DBUSER\"@'%' IDENTIFIED BY \"${KEYSTONE_DBPASS}\";"

# Update admin token
sed -i "s/^#admin_token .*/admin_token = ${ADMIN_TOKEN}/" ${KEYSTONE_FILE}

# Update database connection string
sed -i "s,^connection .*,connection = mysql+pymysql://${KEYSTONE_DBUSER}:${KEYSTONE_DBPASS}@${MYSQL_HOST}/keystone," $KEYSTONE_FILE

# Populate the Identity service database
su -s /bin/sh -c "keystone-manage db_sync" keystone

# Initialize Fernet keys
keystone-manage fernet_setup --keystone-user keystone --keystone-group keystone

# Configure the ServerName option to reference the keystone container
grep "^ServerName" /etc/apache2/apache2.conf
if [ $? -ne 0 ]
then
	echo "ServerName $KEYSTONE_HOST" >> /etc/apache2/apache2.conf
else
	sed -i "s,^ServerName .*,ServerName $KEYSTONE_HOST" /etc/apache2/apache2.conf
fi
# Remove SQLite db
rm -f /var/lib/keystone/keystone.db

#start apache
service apache2 start

OS_TOKEN=$ADMIN_TOKEN
OS_URL=${OS_AUTH_URL:-"http://${HOSTNAME}:35357/v3"}
OS_IDENTITY_API_VERSION=3

export OS_TOKEN OS_URL OS_IDENTITY_API_VERSION

if [ "`openstack user list | grep admin`" ]
then
	:
else
	create_service_credentials "openstack service create  --name keystone identity"
	create_service_credentials "openstack endpoint create --region $REGION identity public http://${KEYSTONE_HOST}:5000/v3"
	create_service_credentials "openstack endpoint create --region $REGION identity internal http://${KEYSTONE_HOST}:5000/v3"
	create_service_credentials "openstack endpoint create --region $REGION identity admin http://${KEYSTONE_HOST}:5000/v3"
	create_service_credentials "openstack domain create --description Default_Domain default"
	create_service_credentials "openstack project create --domain default  --description Admin_Project admin"
	create_service_credentials "openstack user create --domain default --password $ADMIN_PASSWORD admin"
	create_service_credentials "openstack role create admin"
	create_service_credentials "openstack role add --project admin --user admin admin"
	create_service_credentials "openstack project create --domain default --description Service_Project service"

fi

service apache2 stop

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
}

if [ ! -f /root/openrc ]; then
	keystone_config
fi

/usr/bin/supervisord
