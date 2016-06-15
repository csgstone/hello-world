#!/bin/sh

CLIENT_ID="b6e2a570-e4f7-11e5-b90a-ef52c64f702a"
CLIENT_SECRET="fdf9de8c-0a10-4e8f-b071-56b7a2f7c66a"
API_BASE_URL="https://api.teambition.com"
ACCESS_TOKEN="hwik7fd-t2Oeks2djGtV6n3GRF0=CF0E_OZM3a76dbfa13be209bbb92f34d13493a191e4fe529f68cd633c0f004772b1dc20609cddd4d5aafcf09660a5333f6ddf526541baca8054a8a372b0a074a80c34135ec197501b98377df9845d7a611c5ace1b0081ad07f2987f5802fb920df90b73dec728b1680329c0da2d365fa90c6b794"

CLIENT_STAGE_ID="5666582e417068d92b5f6e7a"
SERVER_STAGE_ID="5673b403819eb9850ac2af4c"
DESIGN_STAGE_ID="56693728887d3e3f36305705"
BUG_STAGE_ID="5666580a128cd06f160c444b"

OUTFILE=$1

if [ ! ${OUTFILE} ]; then
	OUTFILE="ChangeLog.txt"
fi


function request() {
	local method=$1
	local api=$2
	local data=$3

	curl \
	-X "${method}" \
	-H "Content-Type: application/json; charset=utf-8" \
	-H "Authorization: OAuth2 ${ACCESS_TOKEN}" \
	--data "${data}" \
	"${API_BASE_URL}/${api}"
}

#request "GET" "api/users/me" ""

#fetch stage list
#request "GET" "api/tasklists/5666580a128cd06f160c4448" "" | jq .


Now=`date "+%Y-%m-%d"`
YESTERDAY=`date -v -1d "+%Y-%m-%d"`
FILTER='{"isDone":true,"accomplished__gt":"'${YESTERDAY}'","accomplished__lt":"'${Now}'"}'


echo "==========客户端==========" > ${OUTFILE}
request "GET" "api/stages/${CLIENT_STAGE_ID}/tasks" "${FILTER}" | jq -r '.[] | "*"+ .content + " by "+.executor.name' >> ${OUTFILE}
echo "=========================" >> ${OUTFILE}
echo "" >> ${OUTFILE}

echo "==========服务器==========" >> ${OUTFILE}
request "GET" "api/stages/${SERVER_STAGE_ID}/tasks" "${FILTER}" | jq -r '.[] | "*"+ .content + " by "+.executor.name' >> ${OUTFILE}
echo "=========================" >> ${OUTFILE}
echo "" >> ${OUTFILE}


echo "==========策划==========" >> ${OUTFILE}
request "GET" "api/stages/${DESIGN_STAGE_ID}/tasks" "${FILTER}" | jq -r '.[] | "*"+ .content + " by "+.executor.name' >> ${OUTFILE}
echo "=======================" >> ${OUTFILE}
echo "" >> ${OUTFILE}

echo "==========BugFix==========" >> ${OUTFILE}
request "GET" "api/stages/${BUG_STAGE_ID}/tasks" "${FILTER}" | jq -r '.[] | "*"+ .content + " by "+.executor.name' >> ${OUTFILE}
echo "==========================" >> ${OUTFILE}
echo "" >> ${OUTFILE}

echo ""


