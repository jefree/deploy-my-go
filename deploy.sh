#!/bin/bash

# $1 - binary name
# $2 - server ip
# $3 - folder and service name
# $4 - key.pem file

SYSTEMD="systemd"
UPSTART="upstart"

date=`date +%Y%m%d%H%M%S`
sha1=`git rev-parse HEAD`
binary=$1
ip=$2
service=$3
folder=$3
key=$4
supervisor=$5
branch=$6

deploy_string="cp -r $folder $folder-$date && mv $binary $folder/"

if [ "$supervisor" == "$SYSTEMD" ]
then
	deploy_string="$deploy_string && sudo systemctl restart $service.service && echo $sha1 > $folder/version.txt"
elif [ "$supervisor" == "$UPSTART" ]
then
	deploy_string="$deploy_string && sudo initctl restart $service && echo $sha1 > $folder/version.txt"
else
	echo "====== ERROR UNKNOWN SUPERVISOR ======"
	exit 1
fi

cd $GOPATH/src/$binary
git stash

if [ "$branch" ]
then
git checkout $branch
fi

env GOOS=linux GOARCH=amd64 go build -v $binary
scp -i $key $binary ubuntu@$ip:~

echo "======= START IMPLANTING ======"
ssh -i $key ubuntu@$ip $deploy_string
echo "======= END IMPLANTING ======"

rm $binary
git stash pop
