#!/bin/bash

#---------------------------------------------------------------------

#This script is going to assist you to update SSL cert for car domain
#If found any problem, please correct it 
#Any updates will be made here
#Created by Jalen , 8 June, 2021

#---------------------------------------------------------------------

echo "Please enter your domain name (exmaple: xxx.com):"
read domain 

echo "Please input the privcate key here, type ~ when you finish your input: "
read -d "~" mainkey
echo ""

echo "Please enter the full cert here, type ~ when you finish your input: "
read -d "~" maincert 
echo ""

#echo "the key is $mainkey"
#echo "The full cert is $maincert"

if [ -z "$mainkey" ] || [ -z "$maincert" ]; then
echo "Error! you have not input key or cert!!!!!"
        exit 0
else
        `echo "$mainkey" > ./files/nginx/nginx_ssl/$domain.key`
	`echo "$maincert" > ./files/nginx/nginx_ssl/$domain.crt`
        `cat ./files/nginx/nginx_ssl/$domain.key ./files/nginx/nginx_ssl/$domain.crt > ./files/haproxy/haproxy_ssl/$domain.pem`
fi

key_gen="`openssl pkey -in ./files/nginx/nginx_ssl/$domain.key -pubout -outform pem | sha256sum`"
crt_gen="`openssl x509 -in ./files/nginx/nginx_ssl/$domain.crt -pubkey -noout -outform pem | sha256sum`"


echo "$key_gen"
echo "$crt_gen"

if [[ "$key_gen" == "$crt_gen" ]]; then
	echo "They are matched!"
	echo "A syncssl playbook will be executed on cdn56 server"
	#we are going to test via cdn56 if the SSL cert has been updated 
	ansible-playbook playbook/all.yml -i hosts.yml -t syncssl -l *cdn56*
	echo "Please enter the doamin of the website(example:xxx.com): "
	read test_domain
	#echo "Please enter the test url"
	#read url
	echo "Please enter the port:"
	read port
	#`curl $url --resolve $test_domain:$sourcce_port:23.226.14.28 -Iv`
	echo | openssl s_client -connect 23.226.14.28:$port -servername $test_domain 2>/dev/null |openssl x509 -noout -issuer -subject -dates
	echo " "

	echo "------------------------------------------------------------------"
	echo "Do you want to continue?! If y/Y/Yes/yes, I will run the next ansible playbook in order to update the SSL cert to all of the edge servers:"
	read reply
	if [ $reply == 'Y' ] || [ $reply == 'y' ] || [ $reply == 'Yes' ] || [ $reply == 'yes' ]; then
		`ansible-playbook playbook/all.yml -i hosts.yml -t syncssl -ledge`
        else
		echo "Remeber!!!!!!! You have not yet updated the SSL cert to ALL Servers!!!"
	fi
else
        echo "They are not matched! Please check the KEY and CERT you just input!!!!!!!!"
fi
