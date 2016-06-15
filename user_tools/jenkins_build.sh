#! /bin/bash

#command required:
#${COCOS_CONSOLE_ROOT}  clone git@192.168.1.91:lemonade/hope_protocol.git   folder bin
#${NDK_ROOT}
#${ANDROID_NDK_ROOT}


GIT_REMOTE="git@192.168.1.91:lemonade/hope.git"
GIT_BRANCH="develop"
TOOLS_PLISTBUDDY=/usr/libexec/PlistBuddy
TOOLS_TEXTUREPACKER="/Applications/TexturePacker.app/Contents/MacOS/TexturePacker"

PLATFORM=ios  #ios or android
BUILD_MODE=release     #debug or release
INTERNAL_BUILD="false"
DISABLE_HOTFIX="false"
LUABYTECODE="false"
LUAKEEPDEBUG="false"

usage()
{
    echo "Usage: `basename $0` [-bkdi] [-p platform] [-m mode] -s svn url"
    echo ""
    echo "-d disable hotfix functional" 
    echo "-i is internal build. if is internal build app will skip channel login step" 
    echo "-p platform ios/android" 
    echo "-m mode release by default" 
    echo "-b save lua to bytecodes" 
    echo "-k keep lua debug info" 
    exit 1
}

exitWithMessage() {
    echo "--------------------------------"
    echo -e "${1}"
    echo "--------------------------------"
    exit ${2}
}

while getopts :bdikp:m:s: opt
do
    case "$opt" in
      b)  
		LUABYTECODE="true"
		;;
	  k)  
		LUAKEEPDEBUG="true"
		;;
	  d)  
		DISABLE_HOTFIX="true"
		;;
	  i)  
		INTERNAL_BUILD="true"
		;;
      p)  
		PLATFORM="$OPTARG"
		;;
	  m)  
		BUILD_MODE="$OPTARG"
		;;
	  s)  
		RES_SVN_URL="$OPTARG"
		;;
      \?)
      	usage
	  	;;
    esac
done


echo "==========================================================="
echo "===================start build============================="
echo "==========================================================="
echo ""
echo "<REQUIRED VALUES>:"
echo "APP_GOTYE_APPKEY=${APP_GOTYE_APPKEY}"
echo "XGPUSH_APPID=${XGPUSH_APPID}"
echo "XGPUSH_APPKEY=${XGPUSH_APPKEY}"
echo "BUGLY_APPID=${BUGLY_APPID}"
echo "BUGLY_APPKEY=${BUGLY_APPKEY}"
echo "APP_LANGUAGE=${APP_LANGUAGE}"
echo "GATE_HOSTS=${GATE_HOSTS}"
echo "GAMERES_HOSTS=${GAMERES_HOSTS}"
echo "APP_FRAMEWORK_MINIVERSION=${APP_FRAMEWORK_MINIVERSION}"
echo "APP_FRAMEWORK_UPGRADEURL=${APP_FRAMEWORK_UPGRADEURL}"
echo "WORKSPACE=${WORKSPACE}"
echo "BUNDLE_IDENTIFIER=${BUNDLE_IDENTIFIER}"
echo "PRODUCT_NAME=${PRODUCT_NAME}"
echo "IOS_ARCHIVE_METHOD=${IOS_ARCHIVE_METHOD}"
echo "IOS_SIGN_IDENTITY=${IOS_SIGN_IDENTITY}"
echo ""
echo "<PARAMS>:"
echo "DISABLE_HOTFIX=$DISABLE_HOTFIX"
echo "LUABYTECODE=$LUABYTECODE"
echo "LUAKEEPDEBUG=$LUAKEEPDEBUG"
echo "INTERNAL_BUILD=$INTERNAL_BUILD"
echo "PLATFORM=$PLATFORM"
echo "BUILD_MODE=$BUILD_MODE"
echo "RES_SVN_URL=$RES_SVN_URL"
echo ""
echo "==========================================================="
echo "==========================================================="
echo ""


if [ -z "$RES_SVN_URL" ]; then 
    exitWithMessage "You must specify svn url with -s option" 1
fi

if [ ! "${PLATFORM}" ]; then
	exitWithMessage "Error: arg1 PLATFORM not set" 1
fi

if [ ! "${BUILD_MODE}" ]; then
	exitWithMessage "Error: arg1 BUILD_MODE not set" 1
fi

if [ ! "${GAMERES_HOSTS}" ]; then
	exitWithMessage "Error: GAMERES_HOSTS not set" 1
fi

if [ ! "${APP_FRAMEWORK_MINIVERSION}" ]; then
	APP_FRAMEWORK_MINIVERSION=-1
	APP_FRAMEWORK_UPGRADEURL=""
fi

if [ ! "${IOS_ARCHIVE_METHOD}" ]; then
	IOS_ARCHIVE_METHOD="development"
fi

function cleanGitWorkspace() {
	echo ""
	echo "--------------------------------"
    echo "-------cleanGitWorkspace--------"
    echo "--------------------------------"

	local gitRemote=$1
	local gitBranch=$2

	cd ${WORKSPACE}/client

	git checkout $gitBranch || exitWithMessage "checkout $gitBranch fail." 1
	rm -rf *
	git checkout HEAD .
	git pull $gitRemote $gitBranch

	if [ "$?" -ne 0 ]; then
        exitWithMessage "Error: cleanGitWorkspace faild." 1
    fi
}

function getGitVersionNum() {
	cd "${WORKSPACE}/client"
	echo "$(git rev-list --count HEAD src 2>/dev/null)"
}

function cleanSVNWorkspace() { 
	echo ""
	echo "--------------------------------"
    echo "-------cleanSVNWorkspace--------"
    echo "--------------------------------"

	local svnUrl=$1

	cd ${WORKSPACE}/client/res && rm -rf * 
	svn checkout ${svnUrl} ./

	if [ "$?" -ne 0 ]; then
        exitWithMessage "Error: cleanSVNWorkspace faild." 1
    fi
}

function getSvnVersionNum() {
	cd ${WORKSPACE}/client/res
	local svnVersion="$(svnversion)"
	local versionNum="$(echo "${svnVersion}" | cut -d : -f 1 | sed -e 's:M::' -e 's:S::' -e 's:P::')"
	echo $versionNum
}

function config_plist() {
	echo ""
	echo "--------------------------------"
    echo "-------config_plist--------"
    echo "--------------------------------"

    local plistfile=$1

    if [ ! -e "${plistfile}" ] ; then
		exitWithMessage "plist not find ${plistfile}" 1
	fi

	if [ "${APP_GOTYE_APPKEY}" ]; then
		$TOOLS_PLISTBUDDY -c "Set :data:GOTYE_APPKEY $APP_GOTYE_APPKEY" "$plistfile"
	fi

	if [ "${XGPUSH_APPID}" ]; then
		$TOOLS_PLISTBUDDY -c "Add :data:XGAPPID string $XGPUSH_APPID" "$plistfile" || $TOOLS_PLISTBUDDY -c "Set :data:XGAPPID $XGPUSH_APPID" "$plistfile"
	fi

	if [ "${XGPUSH_APPKEY}" ]; then
		$TOOLS_PLISTBUDDY -c "Add :data:XGAPPKEY string $XGPUSH_APPKEY" "$plistfile" || $TOOLS_PLISTBUDDY -c "Set :data:XGAPPKEY $XGPUSH_APPKEY" "$plistfile"
	fi

	if [ "${BUGLY_APPID}" ]; then
		$TOOLS_PLISTBUDDY -c "Add :data:BuglyAPPID string $BUGLY_APPID" "$plistfile" || $TOOLS_PLISTBUDDY -c "Set :data:BuglyAPPID $BUGLY_APPID" "$plistfile"
	fi

	if [ "${BUGLY_APPKEY}" ]; then
		$TOOLS_PLISTBUDDY -c "Add :data:BuglyAPPKey string $BUGLY_APPKEY" "$plistfile" || $TOOLS_PLISTBUDDY -c "Set :data:BuglyAPPKey $BUGLY_APPKEY" "$plistfile"
	fi

    if [ "${APP_LANGUAGE}" ]; then
    	$TOOLS_PLISTBUDDY -c "Set :data:LANGUAGE $APP_LANGUAGE" "$plistfile"
	fi

	if [ "${GATE_HOSTS}" ]; then
		$TOOLS_PLISTBUDDY -c "Add :data:GateHosts string $GATE_HOSTS" "$plistfile" || $TOOLS_PLISTBUDDY -c "Set :data:GateHosts $GATE_HOSTS" "$plistfile"
	fi 

	$TOOLS_PLISTBUDDY -c "Add :data:InternalBuild bool $INTERNAL_BUILD" "$plistfile" || $TOOLS_PLISTBUDDY -c "Set :data:InternalBuild $INTERNAL_BUILD" "$plistfile"

	$TOOLS_PLISTBUDDY -c "Add :data:DisableHotfix bool $DISABLE_HOTFIX" "$plistfile" || $TOOLS_PLISTBUDDY -c "Set :data:DisableHotfix $DISABLE_HOTFIX" "$plistfile"
	
}

function compile_ios() {
	echo ""
	echo "--------------------------------"
    echo "-------compile_ios--------"
    echo "--------------------------------"

	local mode=$1
	local schema_name=$2
	local signIdentity=$3
	local bundleid=$4
	local dundlename=$5
	local archive_method=$6
	
	local xcode_project="${WORKSPACE}/client/frameworks/runtime-src/proj.ios_mac/client.xcodeproj"
	local archive_path="${WORKSPACE}/client/publish/ios/${schema_name}"
	local export_plist="${WORKSPACE}/client/frameworks/runtime-src/proj.ios_mac/exportOptions.plist"

	cd ${WORKSPACE}/client


	if [ "${bundleid}" ]; then
		local bundleid_watch="${bundleid}.watchkitapp"
    	local bundleid_watch_ext="${bundleid_watch}.watchkitextension"
    	local app_infoplist="${WORKSPACE}/client/frameworks/runtime-src/proj.ios_mac/ios/Info.plist"
    	local watch_infoplist="${WORKSPACE}/client/frameworks/runtime-src/proj.ios_mac/watch/Info.plist"
    	local watchext_infoplist="${WORKSPACE}/client/frameworks/runtime-src/proj.ios_mac/watch Extension/Info.plist"

    	$TOOLS_PLISTBUDDY -c "Set :CFBundleIdentifier ${bundleid}" "$app_infoplist"
    	
    	$TOOLS_PLISTBUDDY -c "Set :CFBundleIdentifier ${bundleid_watch}" "$watch_infoplist"
    	$TOOLS_PLISTBUDDY -c "Set :WKCompanionAppBundleIdentifier ${bundleid}" "$watch_infoplist"

    	$TOOLS_PLISTBUDDY -c "Set :CFBundleIdentifier ${bundleid_watch_ext}" "$watchext_infoplist"
    	$TOOLS_PLISTBUDDY -c "Set :NSExtension:NSExtensionAttributes:WKAppBundleIdentifier ${bundleid_watch}" "$watchext_infoplist"
	fi

	if [ "${dundlename}" ]; then
		$TOOLS_PLISTBUDDY -c "Set :CFBundleDisplayName ${dundlename}" "${WORKSPACE}/client/frameworks/runtime-src/proj.ios_mac/ios/Info.plist"
	fi

	if [ "${archive_method}" ]; then
		$TOOLS_PLISTBUDDY -c "Set :method ${archive_method}" "$export_plist"
	fi

	local buildsettings=""
	if [ "${IOS_SIGN_IDENTITY}" ]; then
		buildsettings="CODE_SIGN_IDENTITY=${IOS_SIGN_IDENTITY}"
	fi

	xcodebuild \
	-project "${xcode_project}"\
	-scheme "${schema_name}"\
	-configuration "${mode}" \
	-jobs 8 \
	-archivePath "${archive_path}" \
	"${buildsettings}" \
	archive

	if [ "$?" -ne 0 ]; then
        exitWithMessage "Error: compile ios faild." 1
    fi

    xcrun xcodebuild \
    -exportArchive \
    -exportOptionsPlist "${export_plist}" \
    -exportPath "${WORKSPACE}/client/publish/ios/" \
    -archivePath "${archive_path}.xcarchive"

	#cocos compile -p ios -m $mode -j 8 --sign-identity "$signIdentity"
	
}

function compile_android() {
	echo ""
	echo "--------------------------------"
    echo "-------compile_android--------"
    echo "--------------------------------"

	local mode=$1
	local ndkmode=$2
	local abi=$3
	local bundleid=$4
	local appname=$5

	local project_src="${WORKSPACE}/client/frameworks/runtime-src/proj.android.ema"
	local project_ndk="${WORKSPACE}/client/frameworks/runtime-src/proj.android"

	cd ${WORKSPACE}/client

	if [ "${bundleid}" ]; then
    	sed -i.bak "s/\(manifestpackage=\).*/\1${bundleid}/" "${project_src}/project.properties"
    	rm -rf "${project_src}/project.properties.bak"
	fi

	if [ "${appname}" ]; then
		local stringxml="${WORKSPACE}/client/frameworks/runtime-src/proj.android.ema/res/values/string.xml"
		sed -i.bak "s/\(name=\"app_name\"\>\).*\(\<\/string\>/)/\1${appname}\2/" "${stringxml}"
		rm -rf "${stringxml}.bak"
	fi

	cocos compile -p android -j 8 -m $mode --project-src $project_src --project-ndk $project_ndk --ndk-mode $ndkmode --compile-script 0 --app-abi "${abi}"

	if [ "$?" -ne 0 ]; then
        exitWithMessage "Error: compile android faild." 1
    fi
}

function setLuaConfig() {
	echo ""
	echo "--------------------------------"
    echo "-------setLuaConfig--------"
    echo "--------------------------------"

	local configFile=$1
	local mode=$2

	if [ "$mode" = "debug" ]; then
		sed -i.bak 's/\(^DEBUG =\).*/\1 1/' $configFile && rm -f "$configFile.bak"
		sed -i.bak 's/\(^DEBUG_FPS =\).*/\1 true/' $configFile && rm -f "$configFile.bak"
	else
		sed -i.bak 's/\(^DEBUG =\).*/\1 0/' $configFile && rm -f "$configFile.bak"
		sed -i.bak 's/\(^DEBUG_FPS =\).*/\1 false/' $configFile && rm -f "$configFile.bak"
	fi
}

function compileLua() {
	echo ""
	echo "--------------------------------"
    echo "-------compileLua--------"
    echo "--------------------------------"

    local keepDebug=$1

    local opts=""

    if [ $keepDebug = "true" ]; then
		opts="-g"
	fi

	cd "${WORKSPACE}/client"

	cocos luacompile ${opts} -s "src" -d "src" && find ./src -name "*.lua" | xargs rm -f

	cocos luacompile ${opts} -s "res" -d "res" && find ./res -name "*.lua" | xargs rm -f
}

function packLuaScripts() {
	echo ""
	echo "--------------------------------"
    echo "-------packLuaScripts--------"
    echo "--------------------------------"

    local rootFolder=$1
    local folderOrFiles=$2
    local outZipFile=$3

    if [ -e  $outZipFile ]; then
    	rm $outZipFile
    fi

    cd ${rootFolder}

    for p in $folderOrFiles
    do
    	if [ -d $p ]; then
    		find $p -name '*.lua' -o -name '*.luac' | xargs zip -m "$outZipFile"
    	elif [ -e $p ]; then
    		zip -m "$outZipFile" $p
    	fi
    done

    cd -
}

function cryptFile() {
	echo ""
	echo "--------------------------------"
    echo "-------cryptFile:$1 --------"
    echo "--------------------------------"

    cocos crypt -v $1
}


function compress_textures() {
	echo ""
	echo "--------------------------------"
    echo "-------compress_textures--------"
    echo "--------------------------------"

	local folder=$1
	local pngquantTool="${WORKSPACE}/tools/pngquant"
	echo "=======>With Space File Warnning:<"
	find $folder -regex '.* .*'
	find $folder -regex '.* .*' -delete
	echo "=======>With Space File Warnning:>"

	local pngList=`find $folder -name "*.png"`
	for pngFile in $pngList
	do
		$pngquantTool --force --ext .png $pngFile
		#$pngquantTool --force --ext .png --verbose $pngFile
	done
}

function auto_polygon() {
	echo ""
	echo "--------------------------------"
    echo "-------auto_polygon--------"
    echo "--------------------------------"


    for pngFile in `find "${WORKSPACE}/client/res/map" -name "*.png"`
	do
		local plistFile="${pngFile%.*}.plist"
		if [ ! -e ${plistFile} ]; then #skip atlas file
			${TOOLS_TEXTUREPACKER} --data "${pngFile}.pg" --sheet "${pngFile}" --texture-format png --shape-padding 0 --padding 0 --size-constraints AnySize --disable-rotation --trim-mode Polygon --prepend-folder-name ${pngFile}
		fi
	done
}

function encrypt_textures() {
	echo ""
	echo "--------------------------------"
    echo "-------encrypt_textures--------"
    echo "--------------------------------"

    local folder=$1
    local filelist=`find $folder -name "*.png"`
    for f in $filelist
    do
    	cocos crypt -v $f
	done
}

function gen_armature_binary() {
	echo ""
	echo "--------------------------------"
    echo "-------gen_armature_binary--------"
    echo "--------------------------------"

    cd ${WORKSPACE}/tools

    python gen_armature_binary.py
}

function build_manifest() {
	echo ""
	echo "--------------------------------"
    echo "-------build_manifest--------"
    echo "--------------------------------"

    local versionNum=$1
    local hostURL=$2
    local platform=$3
    local framework_mini_version=$4
    local framework_upgrade_url=$5

    cd ${WORKSPACE}/tools
    python build_manifest.py -v "$versionNum" -o "../client/res" --host "${hostURL}" -p ${platform} ../client/ -m $framework_mini_version -u "$framework_upgrade_url"

    if [ "$?" -ne 0 ]; then
        exitWithMessage "Error: build_manifest faild." 1
    fi
}

function packing_gameres() {
	echo ""
	echo "--------------------------------"
    echo "-------packing_gameres--------"
    echo "--------------------------------"

	rm -rf "${WORKSPACE}/client/res/.svn"
	cd "${WORKSPACE}/client" || exitWithMessage "cd ${WORKSPACE}/client fail" 1
	tar -czf gameres.tar.gz --exclude "^.*"  src/ res/ config.json || exitWithMessage "packing gameres.tar.gz fail" 1
	cp gameres.tar.gz "${WORKSPACE}/client/publish/${PLATFORM}" || exitWithMessage "cp gameres.tar.gz fail" 1
}


if [ ! -d ${WORKSPACE} ]; then
	exitWithMessage "$WORKSPACE not exitst" 1
fi

cd ${WORKSPACE}

#cleanGitWorkspace "$GIT_REMOTE" "$GIT_BRANCH"
GIT_VERSION_NUM="$(getGitVersionNum)"

cleanSVNWorkspace "$RES_SVN_URL"
SVN_VERSION_NUM="$(getSvnVersionNum)"

VERSION=$[${SVN_VERSION_NUM}+${GIT_VERSION_NUM}]

echo "GIT_VERSION_NUM:$GIT_VERSION_NUM + SVN_VERSION_NUM:$SVN_VERSION_NUM = $VERSION" 

setLuaConfig "${WORKSPACE}/client/src/config.lua" "$BUILD_MODE"

if [ $LUABYTECODE = "true" ]; then
	compileLua "${LUAKEEPDEBUG}"
fi

SRC_SCRIPT_PACKAGE_PATH="${WORKSPACE}/client/src/scripts.zip"

packLuaScripts "${WORKSPACE}/client/src" "cocos quick dragonbones app shared config.lua protobuf.lua" "$SRC_SCRIPT_PACKAGE_PATH"

if [ ! -e "${SRC_SCRIPT_PACKAGE_PATH}" ] ; then
	exitWithMessage "no src script file zip archive generated " 1
fi

RES_SCRIPT_PACKAGE_PATH="${WORKSPACE}/client/res/scripts.zip"

packLuaScripts "${WORKSPACE}/client/res" "map scripts" "$RES_SCRIPT_PACKAGE_PATH"

if [ ! -e "${RES_SCRIPT_PACKAGE_PATH}" ] ; then
	exitWithMessage "no res script file zip archive generated " 1
fi


cryptFile $SRC_SCRIPT_PACKAGE_PATH
cryptFile $RES_SCRIPT_PACKAGE_PATH

auto_polygon

#compress png textures
compress_textures "${WORKSPACE}/client/res"

#encrypt png textures
encrypt_textures "${WORKSPACE}/client/res"

#convert xml to dbb
gen_armature_binary

if [ $PLATFORM = "ios" ]; then
	config_plist "${WORKSPACE}/client/frameworks/runtime-src/proj.ios_mac/ios/config.plist"
elif [ $PLATFORM = "android" ]; then
	config_plist "${WORKSPACE}/client/frameworks/runtime-src/proj.android.ema/config.plist"
fi


#compress manifest file before upload
build_manifest "${VERSION}" "${GAMERES_HOSTS}" "${PLATFORM}" ${APP_FRAMEWORK_MINIVERSION} "${APP_FRAMEWORK_UPGRADEURL}"

#security -v unlock-keychain "-p" "111111" "~/Library/Keychains/login.keychain"

#####compile and upload###########
if [ $PLATFORM = "ios" ]; then
	compile_ios "$BUILD_MODE" "client iOS"  "iPhone Developer: Zheng Sun (S74ZTW785T)" ${BUNDLE_IDENTIFIER} ${PRODUCT_NAME} ${IOS_ARCHIVE_METHOD}
elif [ $PLATFORM = "android" ]; then
	compile_android "$BUILD_MODE" "$BUILD_MODE" "armeabi:armeabi-v7a" ${BUNDLE_IDENTIFIER} ${PRODUCT_NAME}
fi

packing_gameres

exit $?


