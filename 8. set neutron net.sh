#Configure Neutron services.

touch /etc/systemd/network/ens39.network
sleep 3
cat << EOF >> /etc/systemd/network/ens39.network
[Match]
Name=eth1

[Network]
LinkLocalAddressing=no
IPv6AcceptRA=no
EOF

systemctl restart systemd-networkd


sed -i 's/\[ml2_type_flat\]/ \
[ml2_type_flat]\
flat_networks = physnet1/g' /etc/neutron/plugins/ml2/ml2_conf.ini

sed -i 's/\[linux_bridge\]/ \
[linux_bridge] \
physical_interface_mappings = physnet1:ens39/g' /etc/neutron/plugins/ml2/linuxbridge_agent.ini

sed -i 's/#enable_vxlan = true/ \
enable_vxlan = false/g' /etc/neutron/plugins/ml2/linuxbridge_agent.ini

systemctl restart neutron-linuxbridge-agent


#config vitural network

projectID=$(openstack project list | grep service | awk '{print $2}')

# create network named [sharednet1]
openstack network create --project $projectID --share --provider-network-type flat --provider-physical-network physnet1 sharednet1

# create subnet [10.0.0.0/24] in [sharednet1]
openstack subnet create subnet1 --network sharednet1 --project $projectID --subnet-range 10.0.0.0/24 --allocation-pool start=10.0.0.200,end=10.0.0.254 \
--gateway 10.0.0.1 --dns-nameserver 10.0.0.10

# confirm settings
openstack network list

openstack subnet list