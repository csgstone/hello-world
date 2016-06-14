#! /bin/bash

#arg1 package to upload
#arg2 platfrom ios/android


UPLOAD_FILE=$1
PLATFORM=$2

if [ ! -e "$UPLOAD_FILE" ]; then
	echo "file not exits $UPLOAD_FILE"
	exit 1
fi

if [ ! $PLATFORM ]; then
	echo "please set platform ios/android"
	exit 2
fi

curl -F "file=@${UPLOAD_FILE}" \
					-F "uKey=bd9a9e76845a2e21f65e5cc28f3744ec" \
					-F "_api_key=f6b7b18021607c19c7a2450fdb96b6dc" \
					http://www.pgyer.com/apiv1/app/upload 


exit $?
