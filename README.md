
          +--------------------------+
         /     .-----------+--------/|
        /-----/           /        / |
       /     /===========+        /  |
      /     /           /        /   |
     /     /           /        /|   |
    +-----.--------------------+ |  /|
    |     | P@ssw0rd  |        | | / |
    |-----|-----------.        | |/| |
    |     |   Cub3    |        | / | |
    |     |           |========|/  | |
    |     |           |        |   | |
    |-----+           |        |   |/|
    |     |   v 1.0   |        |   / +
    |     |====+======|        |  / /
    |     |    |      |        | / /
    |     |    |      `========|/|/
    |     |    |               | /
    |     +----`---------------|/
    +--------------------------+


This is the Password Cub3 v 1.0, a password safe built to take advantages of automated processes and allow team members to collaborate.


For detailed information on how and why this product was designed, check out the DerbyCon talk here:
https://michaelvieau.com/index.php/training-conferences/



---------
  SETUP
---------
The setup was tested on CentOS 7.1


# Install MySQL
----------------
rpm -Uvh https://repo.mysql.com/mysql80-community-release-el7-3.noarch.rpm -y
sed -i 's/enabled=1/enabled=0/' /etc/yum.repos.d/mysql-community.repo
yum --enablerepo=mysql57-community install mysql-community-server -y
systemctl start mysqld.service
systemctl enable mysqld.service

# Find the temp password stored in the log file
grep "A temporary password" /var/log/mysqld.log


# Configure MySQL
------------------
mysql -u root -p
# Enter password from temp file
ALTER USER root@localhost IDENTIFIED BY '<New-Password-Here>';
flush privileges;
create database PasswordCub3;
use PasswordCub3;
create table passwords(ID int NOT NULL AUTO_INCREMENT, ClientName varchar(255), Password varchar(1000), PRIMARY KEY (ID));
create table users(ID int NOT NULL AUTO_INCREMENT, Username varchar(255), FullName varchar(255), PRIMARY KEY (ID));
exit;


# System setup
---------------
mkdir -p /PasswordCub3/ServerKeys
mkdir -p /PasswordCub3/ramdisk
mkdir -p /PasswordCub3/public-keys
groupadd ramdisk
groupadd PasswordCub3
groupadd Cub3Admins
chgrp ramdisk /PasswordCub3/ramdisk
chmod 770 /PasswordCub3/ramdisk
chmod 777 /PasswordCub3/public-keys
echo '%PasswordCub3   ALL=(root)      NOPASSWD: /bin/mount, /bin/umount' >> /etc/sudoers



---------------
  SETUP USER
---------------
useradd -c "${FULLNAME}" -G PasswordCub3,ramdisk ${USERNAME}
mkdir /home/${USERNAME}/.ssh
touch /home/${USERNAME}/.ssh/authorized_keys
chmod 700 /home/${USERNAME}/.ssh
chmod 644 /home/${USERNAME}/.ssh/authorized_keys
chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}/.ssh
echo "exec /PasswordCub3/Scripts/UserSide.sh" >> /home/${USERNAME}/.bash_profile







