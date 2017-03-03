#!/bin/bash
set -x
HORIZON_FILE=/etc/openstack-dashboard/local_settings.py
MEMCACHED_HOST=${MEMCACHED_HOST:-memcached}
KEYSTONE_HOST=${KEYSTONE_HOST:-keystone}
MEMCACHED_PORT=${MEMCACHED_PORT:-11211}

horizon_config() {

sed -i "s/^OPENSTACK_HOST[ =].*/OPENSTACK_HOST = \"${KEYSTONE_HOST}\"/" ${HORIZON_FILE}

sed -i "s/^ALLOWED_HOSTS[ =].*/ALLOWED_HOSTS = ['*', ]/g" ${HORIZON_FILE}

sed -i "/^CACHES/i SESSION_ENGINE = 'django.contrib.sessions.backends.cache'\n" ${HORIZON_FILE}

sed -i "s/'LOCATION':.*/'LOCATION': '${MEMCACHED_HOST}:${MEMCACHED_PORT}',/" ${HORIZON_FILE}

sed -i "s,^OPENSTACK_KEYSTONE_URL.*,OPENSTACK_KEYSTONE_URL = \"http://%s:5000/v3\" % OPENSTACK_HOST," ${HORIZON_FILE}

sed -i "/OPENSTACK_KEYSTONE_MULTIDOMAIN_SUPPORT/a OPENSTACK_KEYSTONE_MULTIDOMAIN_SUPPORT = True" ${HORIZON_FILE}

sed -i "/OPENSTACK_API_VERSIONS/i OPENSTACK_API_VERSIONS = {\n    \"identity\": 3,\n    \"image\": 2,\n    \"volume\": 2,\n}" ${HORIZON_FILE}

sed -i "s/#OPENSTACK_KEYSTONE_DEFAULT_DOMAIN/OPENSTACK_KEYSTONE_DEFAULT_DOMAIN/" ${HORIZON_FILE}

sed -i "s/^OPENSTACK_KEYSTONE_DEFAULT_ROLE.*/OPENSTACK_KEYSTONE_DEFAULT_ROLE = \"user\"/" ${HORIZON_FILE}

sed -i "s/'enable_router'.*/'enable_router': False,/" ${HORIZON_FILE}

sed -i "s/'enable_quotas'.*/'enable_quotas': False,/" ${HORIZON_FILE}

sed -i "s/'enable_lb'.*/'enable_lb': False,/" ${HORIZON_FILE}

sed -i "s/'enable_firewall'.*/'enable_firewall': False,/" ${HORIZON_FILE}

sed -i "s/'enable_vpn'.*/'enable_vpn': False,/" ${HORIZON_FILE}

sed -i "s/'enable_fip_topology_check'.*/'enable_fip_topology_check': False,/" ${HORIZON_FILE}

sed -i "s/^TIME_ZONE.*/TIME_ZONE = \"UTC\"/" ${HORIZON_FILE}


#start apache
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
	horizon_config
fi

/usr/bin/supervisord
