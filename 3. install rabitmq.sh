#!/bin/bash -ex

apt -y install rabbitmq-server memcached python-pymysql

rabbitmqctl add_user openstack password

rabbitmqctl set_permissions openstack ".*" ".*" ".*"

systemctl restart rabbitmq-server
systemctl enable rabbitmq-server


sed -i 's/-l 127.0.0.1/ \
-l 0.0.0.0/g' /etc/memcached.conf

systemctl restart memcached
systemctl enable memcached