#!bin/bash -ex
echo "create database store"

cat << EOF |mysql -uroot

create database keystone;
grant all privileges on keystone.* to keystone@'localhost' identified by 'password';
grant all privileges on keystone.* to keystone@'%' identified by 'password';
flush privileges;
exit
EOF

echo "install keystone"

apt -y install keystone python-openstackclient apache2 libapache2-mod-wsgi-py3 python-oauth2client

