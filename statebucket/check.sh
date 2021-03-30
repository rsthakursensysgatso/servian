./statebucket/status.sh

if [ $? -eq 0 ];then
        echo "Sucessful deployment!!! :)"
else
  echo "Unccessulful deployment :("
fi
