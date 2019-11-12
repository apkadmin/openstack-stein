#step1
echo "1";
openstack user create --domain default --project service --password servicepassword nova;
sleep 2;
echo "2";
openstack role add --project service --user nova admin;
sleep 2;
echo "3";

openstack user create --domain default --project service --password servicepassword placement
sleep 2;
echo "4";

openstack role add --project service --user placement admin
sleep 2;

openstack service create --name nova --description "OpenStack Compute service" compute
sleep 2;

openstack service create --name placement --description "OpenStack Compute Placement service" placement
sleep 2;

export controller=10.0.0.2;
sleep 2;

openstack endpoint create --region RegionOne compute public http://$controller:8774/v2.1/%\(tenant_id\)s
sleep 2;

openstack endpoint create --region RegionOne compute internal http://$controller:8774/v2.1/%\(tenant_id\)s
sleep 2;

openstack endpoint create --region RegionOne compute admin http://$controller:8774/v2.1/%\(tenant_id\)s
sleep 2;

openstack endpoint create --region RegionOne placement public http://$controller:8778
sleep 2;

openstack endpoint create --region RegionOne placement internal http://$controller:8778
sleep 2;

openstack endpoint create --region RegionOne placement admin http://$controller:8778
sleep 2;

cat << EOF | mysql -uroot
create database nova;
grant all privileges on nova.* to nova@'localhost' identified by 'password';
grant all privileges on nova.* to nova@'%' identified by 'password';
#
create database nova_api;
grant all privileges on nova_api.* to nova@'localhost' identified by 'password';
grant all privileges on nova_api.* to nova@'%' identified by 'password';
#
create database nova_placement;
grant all privileges on nova_placement.* to nova@'localhost' identified by 'password';
grant all privileges on nova_placement.* to nova@'%' identified by 'password';
#
create database nova_cell0;
grant all privileges on nova_cell0.* to nova@'localhost' identified by 'password';
grant all privileges on nova_cell0.* to nova@'%' identified by 'password';
#
flush privileges;
exit
EOF
echo "accept"

apt -y install nova-api nova-placement-api nova-conductor nova-consoleauth nova-scheduler nova-novncproxy python3-novaclient
mv /etc/nova/nova.conf /etc/nova/nova.conf.org
sleep 3
cat <<EOF>> /etc/nova/nova.conf
# create new
[DEFAULT]
# define own IP
my_ip = 10.0.0.2
state_path = /var/lib/nova
enabled_apis = osapi_compute,metadata
log_dir = /var/log/nova
# RabbitMQ connection info
transport_url = rabbit://openstack:password@10.0.0.2

[api]
auth_strategy = keystone

# Glance connection info
[glance]
api_servers = http://10.0.0.2:9292

[oslo_concurrency]
lock_path = $state_path/tmp

# MariaDB connection info
[api_database]
connection = mysql+pymysql://nova:password@10.0.0.2/nova_api

[database]
connection = mysql+pymysql://nova:password@10.0.0.2/nova

# Keystone auth info
[keystone_authtoken]
www_authenticate_uri = http://10.0.0.2:5000
auth_url = http://10.0.0.2:5000
memcached_servers = 10.0.0.2:11211
auth_type = password
project_domain_name = default
user_domain_name = default
project_name = service
username = nova
password = servicepassword

[placement]
auth_url = http://10.0.0.2:5000
os_region_name = RegionOne
auth_type = password
project_domain_name = default
user_domain_name = default
project_name = service
username = placement
password = servicepassword

[placement_database]
connection = mysql+pymysql://nova:password@10.0.0.2/nova_placement

[wsgi]
api_paste_config = /etc/nova/api-paste.ini
EOF

chmod 640 /etc/nova/nova.conf

chgrp nova /etc/nova/nova.conf

su -s /bin/bash nova -c "nova-manage api_db sync"

su -s /bin/bash nova -c "nova-manage cell_v2 map_cell0"

su -s /bin/bash nova -c "nova-manage db sync"

su -s /bin/bash nova -c "nova-manage cell_v2 create_cell --name cell1"

systemctl restart apache2

for service in api conductor scheduler consoleauth novncproxy; do
systemctl restart nova-$service
done

openstack compute service list


apt -y install nova-compute nova-compute-kvm

echo "[vnc]" >> /etc/nova/nova.conf
echo "enabled = True" >> /etc/nova/nova.conf
echo "server_listen = 0.0.0.0" >> /etc/nova/nova.conf
echo "server_proxyclient_address = 10.0.0.2" >> /etc/nova/nova.conf
echo "novncproxy_base_url = http://10.0.0.20:6080/vnc_auto.html" >> /etc/nova/nova.conf

systemctl restart nova-compute

su -s /bin/bash nova -c "nova-manage cell_v2 discover_hosts"
openstack compute service list