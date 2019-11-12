#!/bin/bash -ex

echo "install ntp"
apt -y install ntp


echo "##### Backup NTP configuration... ##### "
sleep 7 
cp /etc/ntp.conf /etc/ntp.conf.bka
rm /etc/ntp.conf
cat /etc/ntp.conf.bka | grep -v ^# | grep -v ^$ >> /etc/ntp.conf
echo "pool 0.ubuntu.pool.ntp.org iburst"
sed -i 's/pool 0.ubuntu.pool.ntp.org iburst/ \
#pool 0.ubuntu.pool.ntp.org iburst/g' /etc/ntp.conf

echo "pool 1.ubuntu.pool.ntp.org iburst"
sed -i 's/pool 1.ubuntu.pool.ntp.org iburst/ \
#pool 1.ubuntu.pool.ntp.org iburst/g' /etc/ntp.conf

echo "pool 2.ubuntu.pool.ntp.org iburst"
sed -i 's/pool 2.ubuntu.pool.ntp.org iburst/ \
#pool 2.ubuntu.pool.ntp.org iburst/g' /etc/ntp.conf

echo "pool 3.ubuntu.pool.ntp.org iburst"
sed -i 's/pool 3.ubuntu.pool.ntp.org iburst/ \
#pool 3.ubuntu.pool.ntp.org iburst/g' /etc/ntp.conf

echo "pool 4.ubuntu.pool.ntp.org iburst"
sed -i 's/pool 4.ubuntu.pool.ntp.org iburst/ \
#pool 4.ubuntu.pool.ntp.org iburst/g' /etc/ntp.conf

echo "pool ntp.ubuntu.com"

sed -i 's/pool ntp.ubuntu.com/ \
#pool ntp.ubuntu.com \
server ntp.nict.jp iburst \
server ntp1.jst.mfeed.ad.jp iburst \
server ntp2.jst.mfeed.ad.jp iburst/g' /etc/ntp.conf


# line 53: add network range you allow to receive time syncing requests from clients
#restrict 10.0.0.0 mask 255.255.255.0 nomodify notrap


systemctl enable ntp
systemctl restart ntp

# show status
ntpq -p



# hoặc

# apt -y install chrony

# vi /etc/chrony/chrony.conf

# # line 17: comment out default settings and add NTP Servers for your timezone
# #pool ntp.ubuntu.com        iburst maxsources 4
# #pool 0.ubuntu.pool.ntp.org iburst maxsources 1
# #pool 1.ubuntu.pool.ntp.org iburst maxsources 1
# #pool 2.ubuntu.pool.ntp.org iburst maxsources 2
# server ntp.nict.jp iburst
# server ntp1.jst.mfeed.ad.jp iburst
# server ntp2.jst.mfeed.ad.jp iburst 

# # add to the end : add network range you allow to receive time syncing requests from clients
# allow 10.0.0.0/24


# systemctl enable chrony
# systemctl restart chrony
# # show status
# chronyc sources


# #set ntp clients
# apt -y install ntpdate

# ntpdate ntp.nict.jp

