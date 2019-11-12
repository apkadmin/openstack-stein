#!bin/bash -ex
apt -y install software-properties-common
add-apt-repository cloud-archive:stein
apt update
apt -y upgrade