openstack user create --domain default --project service --password servicepassword neutron
openstack role add --project service --user neutron admin
openstack service create --name neutron --description "OpenStack Networking service" network
export controller=10.0.0.2
openstack endpoint create --region RegionOne network public http://$controller:9696
openstack endpoint create --region RegionOne network internal http://$controller:9696
openstack endpoint create --region RegionOne network admin http://$controller:9696

cat << EOF | mysql -uroot
create database neutron_ml2;
grant all privileges on neutron_ml2.* to neutron@'localhost' identified by 'password';
grant all privileges on neutron_ml2.* to neutron@'%' identified by 'password';
flush privileges;
 exit
EOF
apt -y install neutron-server neutron-plugin-ml2 neutron-linuxbridge-agent neutron-l3-agent neutron-dhcp-agent neutron-metadata-agent python3-neutronclient
mv /etc/neutron/neutron.conf /etc/neutron/neutron.conf.org


cat << EOF >>/etc/neutron/neutron.conf

# create new
[DEFAULT]
core_plugin = ml2
service_plugins = router
auth_strategy = keystone
state_path = /var/lib/neutron
dhcp_agent_notification = True
allow_overlapping_ips = True
notify_nova_on_port_status_changes = True
notify_nova_on_port_data_changes = True
# RabbitMQ connection info
transport_url = rabbit://openstack:password@10.0.0.2

[agent]
root_helper = sudo /usr/bin/neutron-rootwrap /etc/neutron/rootwrap.conf

# Keystone auth info
[keystone_authtoken]
www_authenticate_uri = http://10.0.0.2:5000
auth_url = http://10.0.0.2:5000
memcached_servers = 10.0.0.2:11211
auth_type = password
project_domain_name = default
user_domain_name = default
project_name = service
username = neutron
password = servicepassword

# MariaDB connection info
[database]
connection = mysql+pymysql://neutron:password@10.0.0.2/neutron_ml2

# Nova auth info
[nova]
auth_url = http://10.0.0.2:5000
auth_type = password
project_domain_name = default
user_domain_name = default
region_name = RegionOne
project_name = service
username = nova
password = servicepassword

[oslo_concurrency]
lock_path = $state_path/tmp
EOF

chmod 640 /etc/neutron/neutron.conf
chgrp neutron /etc/neutron/neutron.conf


touch /etc/radvd.conf

sleep 3
cat << EOF >> /etc/radvd.conf
interface ens38
{
AdvSendAdvert on;
MinRtrAdvInterval 30;
MaxRtrAdvInterval 100;
prefix 2001:db8:1:0::/64
{
AdvOnLink on;
AdvAutonomous on;
AdvRouterAddr off;
};

};
EOF


sed -i 's/#interface_driver = <None>/ \
interface_driver = linuxbridge/g' /etc/neutron/l3_agent.ini

sed -i 's/#interface_driver = <None>/ \
interface_driver = linuxbridge/g' /etc/neutron/dhcp_agent.ini

sed -i 's/#enable_isolated_metadata = false/ \
enable_isolated_metadata = true/g' /etc/neutron/dhcp_agent.ini

sed -i 's/#nova_metadata_host = 127.0.0.1/ \
nova_metadata_host = 10.0.0.2/g' /etc/neutron/metadata_agent.ini

sed -i 's/#metadata_proxy_shared_secret =/ \
metadata_proxy_shared_secret = metadata_secret/g' /etc/neutron/metadata_agent.ini
sed -i 's/#memcache_servers = localhost:11211/ \
memcache_servers = 10.0.0.2:11211/g' /etc/neutron/metadata_agent.ini


sed -i 's/#tenant_network_types = local/ \
type_drivers = flat,vlan,vxlan \
tenant_network_types = \
mechanism_drivers = linuxbridge \
extension_drivers = port_security/g' /etc/neutron/plugins/ml2/ml2_conf.ini

sed -i 's/#firewall_driver = <None>/\
enable_security_group = True \
firewall_driver = iptables \
enable_ipset = True/g' /etc/neutron/plugins/ml2/linuxbridge_agent.ini

sed -i 's/#local_ip = <None>/ \
local_ip = 10.0.0.2/g' /etc/neutron/plugins/ml2/linuxbridge_agent.ini


cat << EOF >> /etc/nova/nova.conf
[neutron]
auth_url = http://10.0.0.30:5000
auth_type = password
project_domain_name = default
user_domain_name = default
region_name = RegionOne
project_name = service
username = neutron
password = servicepassword
service_metadata_proxy = True
metadata_proxy_shared_secret = metadata_secret
EOF

sed -i 's/\[DEFAULT\]/ \
[DEFAULT] \
use_neutron = True \
linuxnet_interface_driver = nova.network.linux_net.LinuxBridgeInterfaceDriver \
firewall_driver = nova.virt.firewall.NoopFirewallDriver \
vif_plugging_is_fatal = True \
vif_plugging_timeout = 300/g' /etc/nova/nova.conf


ln -s /etc/neutron/plugins/ml2/ml2_conf.ini /etc/neutron/plugin.ini

su -s /bin/bash neutron -c "neutron-db-manage --config-file /etc/neutron/neutron.conf --config-file /etc/neutron/plugin.ini upgrade head"


for service in server l3-agent dhcp-agent metadata-agent linuxbridge-agent; do
systemctl restart neutron-$service
systemctl enable neutron-$service
done

systemctl restart nova-api nova-compute

openstack network agent list
