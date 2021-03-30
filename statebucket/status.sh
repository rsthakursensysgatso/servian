#/bin/bash

cmd=`../terraform show |grep aws_alb|awk '{print $3}'|cut -d'"' -f 2`
res=`curl -s $cmd/healthcheck/`
resp="OK"
if [ $res == $resp ]
then
   echo "App Responding Ok!!!!!!"
else
   exit 1
fi
