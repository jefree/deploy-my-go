#!/bin/bash

# $1 - binary name
# $2 - host name
# $3 - folder and service name
# $4 - supervisor name
# $5 - branch name

SYSTEMD="systemd"
UPSTART="upstart"

date=`date +%Y%m%d%H%M%S`
sha1=`git rev-parse HEAD`
binary=$1
host=$2
service=$3
folder=$3
supervisor=$4
branch=$5

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
scp $binary $host:~

echo "======= START IMPLANTING ======"
ssh $host $deploy_string
echo "======= END IMPLANTING ======"

rm $binary
git stash pop
