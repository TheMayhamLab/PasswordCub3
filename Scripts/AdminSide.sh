!/bin/bash
# Name:         AdminSide.sh
# Purpose:      Access to the Password Cub3 DB
# By:           Michael Vieau / Kevin Bong
# Created:      2019.07.31
# Modified:     2019.08.07
# Rev Level     0.1
# -------------------------------------------------------
clear


# VARS
# -----
DBUSER="root"
DBPASS="dsUWMJ7tva-e#23a!"
PGPKEY="PasswordCub3"
RAMDISK="ramdisk"
ROOTDIR="/PasswordCub3"
KEYDIR="ServerKeys"

# -----------------------------------------------------------------
menu()
{
echo "+--------------------------+"
echo "|    Password Cub3 1.0     |"
echo "|     Admin Console        |"
echo "+--------------------------+"
echo ""
echo "1) * Run user side  script *"
echo "2) Add new user"
echo "3) Remove user"
echo "4) Rotate server keys"
echo "5) Encrypt priv key w/ pub keys"
echo "6) List current users"
echo ""
echo "0) Exit"
echo ""
echo -n "Enter a selection: "; read MENU

case ${MENU} in

  1)
	runuser
	;;
  2)
	adduser
	;;
  3)
	removeuser
	;;
  4)
	echo "Not done"
	rotatekeys
	;;
  5)
	privatekeytime
	;;
  6)
	listusers
	;;
  0)
	exit 0
	;;
  *)
	clear
	menu
	;;
esac
}
# -----------------------------------------------------------------
runuser()
{

${ROOTDIR}/Scripts/UserSide.sh

}
# -----------------------------------------------------------------
listusers()
{

mysql -u ${DBUSER} -p${DBPASS} PasswordCub3 -t -e "SELECT Username,Fullname,Admin FROM users" 2>/dev/null

menu
}
# -----------------------------------------------------------------
adduser()
{

echo -n "Enter the users fullname: "; read FULLNAME
echo -n "Enter the username to use: "; read USRNAME
echo -n "Will this user be an admin [y/N]: "; read ADMIN
echo -n "Enter in the user's public ssh key "; read PUBSSH

VALIDUSER=""
VALIDUSER=`grep ${USRNAME} /etc/passwd`
if [ -z "${VALIDUSER}" ]
then

  sudo useradd -c "${FULLNAME}" -G PasswordCub3,ramdisk ${USRNAME}
  sudo mkdir /home/${USRNAME}/.ssh
  sudo chown -R ${USER}:${USER} /home/${USRNAME}
  echo "${PUBSSH}" > /home/"${USRNAME}"/.ssh/authorized_keys
  sudo chmod 700 /home/${USRNAME}/.ssh
  sudo chmod 644 /home/${USRNAME}/.ssh/authorized_keys

  if [ "${ADMIN^^}" == "Y" ]
  then
    sudo bash -c 'echo "exec /PasswordCub3/Scripts/AdminSide.sh" >> /home/"${USRNAME}"/.bash_profile'
    ADMIN="y"
  else
    sudo bash -c 'echo "exec /PasswordCub3/Scripts/UserSide.sh" >> /home/'${USRNAME}'/.bash_profile'
    ADMIN="n"
  fi

  mysql -u ${DBUSER} -p${DBPASS} PasswordCub3 -t -e "INSERT INTO users (Username, Fullname, Admin) VALUES ('${USRNAME}', '${FULLNAME}', '${ADMIN}')" 2>/dev/null

  sudo chown -R ${USRNAME}:${USRNAME} /home/${USRNAME}

else
  echo "Sorry, that user already exists."
fi

cleanup
menu
}
# -----------------------------------------------------------------
removeuser()
{

echo -n "Enter the username to be removed: ";read USRNAME

VALIDUSER=""
VALIDUSER=`grep ${USRNAME} /etc/passwd`
if [ -z "${VALIDUSER}" ]
then
  echo "Username does not exist. Please check the username."
else

  mysql -u ${DBUSER} -p${DBPASS} PasswordCub3 -t -e "DELETE FROM users WHERE Username = '${USRNAME}'" 2>/dev/null

  sudo userdel -r ${USRNAME}
  rm -f ${ROOTDIR}/public-keys/${USRNAME}-pub.asc
fi

cleanup
menu
}
# -----------------------------------------------------------------
rotatekeys()
{

# Lock out users so while rotating keys

sudo mount -t tmpfs -o size=16m,gid=${GID} tmpfs ${ROOTDIR}/${RAMDISK}

# Create new keys

# Decrypt passwords in DB w/ old key
# Encrypt passwords in DB w/ new key

# Remove old keys

# Unlock users

cleanup
menu
}
# -----------------------------------------------------------------
privatekeytime()
{

##rm -f ${ROOTDIR}/${KEYDIR}/key.gpg.gpg
GID=`grep ramdisk /etc/group|cut -d":" -f3`
sudo mount -t tmpfs -o size=16m,gid=${GID} tmpfs ${ROOTDIR}/${RAMDISK}

# Remove any old keys from the keyring
sudo gpg --list-keys | grep uid | grep -v PasswordCub3 | cut -d"(" -f1|sed 's/uid//g' | sed 's/^[ \t]*//g' > ${ROOTDIR}/${RAMDISK}/temp.txt
for i in $(cat ${ROOTDIR}/${RAMDISK}/temp.txt)
do 
  sudo gpg --batch --yes --delete-key ${i}
done

gpg -q --import ${ROOTDIR}/ServerKeys/${PGPKEY}.asc
cp ${ROOTDIR}/${KEYDIR}/key.gpg.gpg ${ROOTDIR}/${RAMDISK}/key.gpg.gpg
sudo mv -f ${ROOTDIR}/${KEYDIR}/key.gpg.gpg ${ROOTDIR}/${KEYDIR}/key.gpg.gpg.bkp
gpg -o ${ROOTDIR}/${RAMDISK}/key.gpg -d ${ROOTDIR}/${RAMDISK}/key.gpg.gpg

##gpg --export-secret-keys PasswordCub3 > ${ROOTDIR}/${RAMDISK}/key.gpg

# Any public keys in the public-keys folder are considered good and should be imported.
sudo gpg --batch --yes --import ${ROOTDIR}/public-keys/*.asc
sudo gpg --list-keys | grep uid | grep -v PasswordCub3 | cut -d"(" -f1 | sed 's/uid//g' | sed 's/^[ \t]*//g' > ${ROOTDIR}/${RAMDISK}/temp.txt


for i in $(cat ${ROOTDIR}/${RAMDISK}/temp.txt);do USERS+=" -r ${i}";done
sudo gpg -q -o ${ROOTDIR}/${KEYDIR}/key.gpg.gpg ${USERS} -e ${ROOTDIR}/${RAMDISK}/key.gpg

cleanup
menu

}
# -----------------------------------------------------------------
cleanup()
{

rm -rf ${ROOTDIR}/${RAMDISK}/* 2>/dev/null
sudo umount ${ROOTDIR}/${RAMDISK} 2>/dev/null
echo RELOADAGENT | gpg-connect-agent >/dev/null
PASS=""

}

# Run the functions
menu
