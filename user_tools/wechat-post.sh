#!/bin/sh
MESSAGE=$1
DOWNLOAD_URL=$2
APPID=$3
CHANGELOG=$4

CORPID="wx9f4710df0f76e956"
SECRET="6jdZSCt4G9bciZhRY_dCVhkT60BpMPB_GA_63u7zg6ObLlj5GupSUki5FXscQkD3"

JSONDATA=$(curl "https://qyapi.weixin.qq.com/cgi-bin/gettoken?corpid=$CORPID&corpsecret=$SECRET")
echo "JSON: $JSONDATA"

ACCESS_TOKEN=$(echo $JSONDATA | jq '.access_token' | tr -d '"') 
EXPIRES_IN=$(echo $JSONDATA | jq '.expires_in' | tr -d '"') 
echo "access_token: $ACCESS_TOKEN"
echo "expires_in: $EXPIRES_IN"

FORMAT_MESSAGE=$(/bin/echo "${MESSAGE}" | python -c 'import sys,json;print(json.dumps(sys.stdin.read()));')
FORMAT_CHANGELOG=$(/bin/echo "${CHANGELOG}" | python -c 'import sys,json;print(json.dumps(sys.stdin.read()));')

POST_MESSAGE='
{
	"touser":"@all",
	"toparty":"",
	"totag":"",
	"msgtype":"news",
	"agentid":"'$APPID'",
	"news":{
		"articles":
		[
			{
				"title":'${FORMAT_MESSAGE}',
				"description":'${FORMAT_CHANGELOG}',
				"url":"'${DOWNLOAD_URL}'",
				"picurl":"http://repong.cn/repong_logo.jpg"
			}
		]
	}
}'

FORMAT_POST_MESSAGE=$(/bin/echo $POST_MESSAGE | jq .)
bin/echo "$FORMAT_POST_MESSAGE"
#sleep 2s
URL="https://qyapi.weixin.qq.com/cgi-bin/message/send?access_token=$ACCESS_TOKEN"

curl -iv \
-H "Content-Type: application/json; charset=utf-8" \
-X POST --data "$FORMAT_POST_MESSAGE" \
$URL


