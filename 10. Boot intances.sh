cat << EOF > ~/keystonerc
export OS_PROJECT_DOMAIN_NAME=default
export OS_USER_DOMAIN_NAME=default
export OS_PROJECT_NAME=hiroshima
export OS_USERNAME=serverworld
export OS_PASSWORD=userpassword
export OS_AUTH_URL=http://10.0.0.2:5000/v3
export OS_IDENTITY_API_VERSION=3
export OS_IMAGE_API_VERSION=2
export PS1='\u@\h \W(keystone)\$ '
EOF


chmod 600 ~/keystonerc

source ~/keystonerc

echo "source ~/keystonerc " >> ~/.bash_profile

openstack flavor list

openstack image list

openstack network list

openstack security group create secgroup01

openstack security group list

ssh-keygen -q -N ""

openstack keypair create --public-key ~/.ssh/id_rsa.pub mykey

openstack keypair list

netID=$(openstack network list | grep sharednet1 | awk '{ print $2 }')


openstack server create --flavor m1.small --image Ubuntu1804 --security-group secgroup01 --nic net-id=$netID --key-name mykey Ubuntu_1804