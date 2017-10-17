#!/bin/bash

# $1 - binary name
# $2 - server ip
# $3 - folder and service name
# $4 - key.pem file

SYSTEMD=1
UPSTART=2

date=`date +%Y%m%d%H%M%S`
binary=$1
ip=$2
service=$3
folder=$3
key=$4
supervisor=$5

deploy_string="cp -r ${folder} ${folder}-${date} && mv ${binary} ${folder}/"

if [$supervisor -eq SYSTEMD]
	deploy_string="$base_deploy_string && sudo systemctl restart ${service}.service"
elif [$supervisor -eq UPSTART]
then
	deploy_string="$base_deploy_string && sudo initctl restart ${service}"
else
	echo "====== ERROR UNKNOWN SUPERVISOR ======"
	exit 1
fi

cd ${GOPATH}/src/${binary}
git stash
git checkout master
env GOOS=linux GOARCH=amd64 go build -v ${binary}
scp -i ${key} ${binary} ubuntu@${ip}:~
ssh -i ${key} ubuntu@${ip} ${deploy_string}
rm ${binary}
git stash pop
