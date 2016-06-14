#! /bin/sh

sourcedir=$1

# Release parameters
params="captcha=436bd5ea&type=0&url="
domain="http://download.emagroup.cn/repong"
cdn="http://push.dnion.com/cdnUrlPush.do"



function CDNPush() 
{
   echo "---------------------------------------------------"
   result=$(curl -d  "$params$domain/$sourcedir" $cdn -s)
   status=$(echo $result|grep -wo "SUCCESS")
   if [ "$status" = ""  ]; then
        echo "Error: Release to cdn failure"
        exit 1
   else
        echo "Info: Release the CDN success"
   fi

}

CDNPush
