echo "start ntp"
systemctl restart ntp
sleep 3
echo "hello"
systemctl restart rabbitmq-server
sleep 3
echo "hello"
systemctl restart mariadb
sleep 3
echo "hello"
systemctl restart memcached
sleep 3
echo "hello"
systemctl restart apache2
sleep 3
echo "hello"
systemctl restart glance-api
sleep 3

# systemctl enable rabbitmq-server
# systemctl enable mariadb
# systemctl enable memcached
# systemctl enable apache2
# systemctl enable glance-api
# systemctl enable ntp

for service in server l3-agent dhcp-agent metadata-agent linuxbridge-agent; do
systemctl restart neutron-$service
# systemctl enable neutron-$service
done