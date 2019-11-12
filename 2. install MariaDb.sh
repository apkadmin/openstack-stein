echo "install mariadb"
apt -y install mariadb-server

echo "setup sercure"
mysql_secure_installation

#echo "login mariadb"
#mysql -u root -p

echo "setup bind-address"
sed -i 's/bind-address            = 127.0.0.1/\
bind-address            = 0.0.0.0/g' /etc/mysql/mariadb.conf.d/50-server.cnf

echo "max_connections"
sed -i 's/#max_connections        = 100/\
max_connections        = 500/g' /etc/mysql/mariadb.conf.d/50-server.cnf

echo "character-set-server"
sed -i 's/character-set-server  = utf8mb4/\
character-set-server  = utf8/g' /etc/mysql/mariadb.conf.d/50-server.cnf

echo "collation-server"
sed -i 's/collation-server      = utf8mb4_general_ci/\
collation-server = utf8_general_ci/g' /etc/mysql/mariadb.conf.d/50-server.cnf

# hoac
#  ALTER DATABASE glance CHARACTER SET utf8 COLLATE utf8_general_ci;
echo "restart mariadb"
systemctl enable mariadb
systemctl restart mariadb