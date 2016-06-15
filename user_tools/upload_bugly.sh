#! /bin/bash


APP_KEY=$1
APP_ID=$2
PID=$3
UPLOAD_FILE=$4
TITLE=$5
CHANGELOG=$6
SECTET=$7
PASSWORD=$8

if [ ${SECTET} = "5" ]; then
	USERS="${PASSWORD}"
else
	USERS=""
fi

exitWithMessage() {
    echo "--------------------------------"
    echo -e "${1}"
    echo "--------------------------------"
    exit ${2}
}

if [ ! -e "$UPLOAD_FILE" ]; then
	exitWithMessage "file not exits $UPLOAD_FILE" 1
fi


curl --insecure -o ./bugly_return.txt \
-F "file=@${UPLOAD_FILE}" \
-F "app_id=${APP_ID}" \
-F "pid=${PID}" \
-F "title=${TITLE}"\
 -F "description=${CHANGELOG}" \
 -F "secret=${SECTET}" \
 -F "users=${USERS}" \
 -F "password=${PASSWORD}" \
 https://api.bugly.qq.com/beta/apiv1/exp?app_key=${APP_KEY}

if [ "$?" -ne 0 ]; then
    exitWithMessage "curl fail" 1
fi

JSON=`cat bugly_return.txt`
echo "$JSON"

RTCODE=$(echo ${JSON} | jq '.rtcode == 0')
if [ "$RTCODE" = "false" ]; then
	exitWithMessage "bugly return error $JSON" 1
fi

DOWNLOAD_URL=$(echo ${JSON} | jq '.data.url')

echo "DOWNLOAD_URL ${DOWNLOAD_URL}"

exit $?
