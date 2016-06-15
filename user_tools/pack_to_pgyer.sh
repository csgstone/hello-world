#! /bin/bash
#crontab:    */30 * * * * sh /Users/bigbear/hotfix/hope/tools/publish_assets.sh -p ios 1> ~/publish_assets.log 2>&1
#to facilitate crontab , cd to your local full path of "hope/tools"
. /etc/profile
. ~/.bash_profile


hopeDir=`pwd|tr -d " "|sed 's/\/hope\/tools//' `
while getopts d: arg
do
	case $arg in
		d)
			hopeDir=$OPTARG
			;;
		?)
			echo "usage: sh pack_to_poger.sh -d /User/bigbear/hotfix"
			exit 1
			;;
	esac
done



cd $hopeDir/hope/tools

cd $hopeDir/hope/client/res
svn checkout svn://192.168.1.92/hope/Tools/game/res/ ./
rm -rf .svn
cd -

 VERSION="0"

python prebuild.py -p ios

python build_manifest.py -v "$VERSION" -m "../client/res/project.manifest" ../client/


cd $hopeDir/hope/client

#keychain=`security list-keychains|grep login.keychain|tr -d " "|tr -d "\""`
#echo "xxxxxx$keychain"
#security -v unlock-keychain "-p" "111111" $keychain
security -v unlock-keychain "-p" "111111" "~/Library/Keychains/login.keychain"



cocos compile -p ios -m release -j 8 --sign-identity "iPhone Developer: Zheng Sun (S74ZTW785T)"
cocos compile -p android -m release -j 8 --compile-script 0

ios_shorturl=`curl -F "file=@publish/ios/client iOS.ipa" \
-F "uKey=bd9a9e76845a2e21f65e5cc28f3744ec" \
-F "_api_key=f6b7b18021607c19c7a2450fdb96b6dc" \
http://www.pgyer.com/apiv1/app/upload \
|tr "," "\n"  \
|grep "appShortcutUrl" \
|sed 's/"appShortcutUrl"://' \
|tr -d \"`


android_shorturl=`curl -F "file=@publish/android/client-release-signed.apk" \
-F "uKey=bd9a9e76845a2e21f65e5cc28f3744ec" \
-F "_api_key=f6b7b18021607c19c7a2450fdb96b6dc" \
http://www.pgyer.com/apiv1/app/upload \
|tr "," "\n"  \
|grep "appShortcutUrl" \
|sed 's/"appShortcutUrl"://' \
|tr -d \"`


ios_url="http://www.pgyer.com/$ios_shorturl"
android_url="http://www.pgyer.com/$android_shorturl"

cd $hopeDir/hope/tools

echo "iOS:$ios_url"
echo "Android:$android_url"
sh wechat-post.sh "iOS" $ios_url 2
sh wechat-post.sh "Android" $android_url 2

cd $hopeDir/hope/client

rm -rf *
git checkout HEAD .

cd res
svn checkout svn://192.168.1.92/hope/Tools/game/res/ ./
rm -rf .svn


