#!/bin/bash
trap no_ctrlc SIGINT SIGTERM

# Name:         UserSide.sh
# Purpose:      Access to the Password Cub3 DB
# By:           Michael Vieau / Kevin Bong
# Created:      2019.07.31
# Modified:     2019.08.28
# Rev Level     0.1
# -------------------------------------------------------
clear


# VARS
# -----
DBNAME="PasswordCub3"
DBUSER="root"
DBPASS="dsUWMJ7tva-e#23a!"
GPGFILE="gpg-gen-file.txt"
PGPKEY="PasswordCub3"
RAMDISK="ramdisk"
ROOTDIR="/PasswordCub3"
KEYDIR="ServerKeys"

# -----------------------------------------------------------------
menu()
{
echo "+--------------------------+"
echo "|    Password Cub3 v1.0    |"
echo "+--------------------------+"
echo ""
echo "1) Enter new password into DB"
echo "2) List clients"
echo "3) Get password from DB"
echo "4) Remove entery"
echo "5) Generate GPG keys"
echo ""
echo "0) Exit"
echo ""
echo -n "Enter a selection: "; read MENU

case ${MENU} in

  1)
	newpassword
	;;
  2)
	listclients
	;;
  3)
	getpassword
	;;
  4)
	removepassword
	;;
  5)
	setupkeys
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
listclients()
{
mysql -u ${DBUSER} -p${DBPASS} PasswordCub3 -t -e "SELECT ClientName FROM passwords" 2>/dev/null
menu
}
# -----------------------------------------------------------------
setupkeys()
{

cp -f ${ROOTDIR}/${GPGFILE} ~/${GPGFILE}
sed -i "s/USER/${USER}/g" ~/${GPGFILE}

${ROOTDIR}/Scripts/Math.sh &
PID=$!
gpg --batch --gen-key ~/${GPGFILE}
gpg --export -a -o ${ROOTDIR}/public-keys/${USER}-pub.asc
kill ${PID}

rm -f ~/${GPGFILE}

echo "Please ask an admin to Ecnrypt priv key w/ pub keys from the admin menu."
echo -n "You will not be able to access passwords until they do. Press a key to continue. "; read -n1 JUNK

cleanup
menu
}
# -----------------------------------------------------------------
getpassword()
{

echo -n "Enter client name: "; read CLIENTNAME

# Mount the RAM disk
GID=`grep ramdisk /etc/group|cut -d":" -f3`
sudo mount -t tmpfs -o size=16m,gid=${GID} tmpfs ${ROOTDIR}/${RAMDISK}

# Pull encrypted client password from DB
PASS=`mysql -u ${DBUSER} -p${DBPASS} ${DBNAME} -t -e "SELECT Password FROM passwords WHERE ClientName = '${CLIENTNAME}'" 2>/dev/null | grep -v \- | grep -v Password | cut -d" " -f2`

if [ -z "${PASS}" ]
then
  echo "Invalid client name or no password stored for that client."
  menu
fi

# Import servers public key
gpg -q --import ${ROOTDIR}/ServerKeys/${DBNAME}.asc

# Working with the server key
cp ${ROOTDIR}/${KEYDIR}/key.gpg.gpg ${ROOTDIR}/${RAMDISK}/key.gpg.gpg

# Decrypt server priv key into memory
gpg -q --yes -o ${ROOTDIR}/${RAMDISK}/key.gpg -d ${ROOTDIR}/${RAMDISK}/key.gpg.gpg 

# Undo base63 encoding
echo ${PASS} | base64 -d >> ${ROOTDIR}/${RAMDISK}/password.txt

# Use server priv key to decrypt client password
PASSWORD=`gpg -q --yes --secret-keyring ${ROOTDIR}/${RAMDISK}/key.gpg -d ${ROOTDIR}/${RAMDISK}/password.txt`

# Display password
echo "--------------------------------------"
echo "Your password is: " ${PASSWORD}
echo "--------------------------------------"

cleanup
menu
}
# -----------------------------------------------------------------
newpassword()
{
echo -n "Enter client name: "; read CLIENTNAME
echo -n "Enter the new password you would like to store: "; read INPUT

gpg -q --import ${ROOTDIR}/ServerKeys/${DBNAME}.asc

NEWPASS=`echo ${INPUT} | gpg -q --yes --encrypt -r ${PGPKEY} --armor | base64 --wrap 0 | grep -v "gpg:"`
mysql -u ${DBUSER} -p${DBPASS} ${DBNAME} -t -e "INSERT INTO passwords (ClientName, Password) VALUES ('${CLIENTNAME}', '${NEWPASS}')" 2>/dev/null

menu
}
# -----------------------------------------------------------------
removepassword()
{

echo -n "Enter client name: "; read CLIENTNAME

PASS=`mysql -u ${DBUSER} -p${DBPASS} ${DBNAME} -t -e "SELECT ClientName FROM passwords WHERE ClientName = '${CLIENTNAME}'" 2>/dev/null | grep -v \- | grep -v clientName | cut -d" " -f2`

if [ -z "${PASS}" ]
then
  echo "Invalid client name."
  menu
fi

echo -n "This will permanently remove the entry for ${CLIENTNAME}. Please conform removal: (y/N) "; read CONFIRM

if [ "${CONFIRM^^}" == "Y" ]
then
  mysql -u ${DBUSER} -p${DBPASS} ${DBNAME} -t -e "DELETE FROM passwords WHERE ClientName = '${CLIENTNAME}'" 2>/dev/null
  echo "${CLIENTNAME} has been removed."
else
  echo "No changes made."
fi

menu

}
# -----------------------------------------------------------------
cleanup()
{

gpg --batch --yes --delete-keys PasswordCub3
rm -rf ${ROOTDIR}/${RAMDISK}/* 2>/dev/null
sudo umount ${ROOTDIR}/${RAMDISK} 2>/dev/null
echo RELOADAGENT | gpg-connect-agent >/dev/null
PASS=""

}

# Run the functions
menu

