#!/bin/bash

#install package for samba 
apt install samba samba-common-bin -y
  
systemctl start smbd nmbd

#firewall allow samba if you have set it up
ufw allow samba

echo "Do you want to public or private samba share?"
read type
echo -n "Enter the folder name: "
read name
echo -n "Any comment for the private file share: "
read comment

if [ $type = 'private' ]; then
        echo -n "Please create a user to access to the file: "
        read username
        echo -n "Enter the password: "
        read -s password
        echo "[$name]
        comment = $comment
        path = /home/$name
        browseable = yes
        guest ok = no
        writable = yes
        valid users = @samba" >> /etc/samba/smb.conf
        useradd $username
        echo $username:$password | chpasswd
        (echo $password; echo $password) | smbpasswd -s -a $username
        groupadd samba
        gpasswd -a $username samba
        mkdir -p /home/$name
        echo "Directory is created"
        setfacl -R -m g:samba:rwx /home/$name
        echo "Permission is set"

elif [ $type = 'public' ]; then
        echo "[$name]
        comment = $comment
        path = /home/$name
        browseable = yes
        writable = yes
        guest ok = yes" >> /etc/samba/smb.conf
        mkdir -p /home/$name
        setfacl -R -m "u:nobody:rwx" /home/$name
        echo "Permission is set"
fi

systemctl restart smbd nmbd
echo "Restart the Service: done"
