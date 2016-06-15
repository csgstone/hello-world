#!/usr/bin/env python

import traceback
import sys
import os
import inspect
import json
import ConfigParser
import hashlib
import shutil
import re
import zipfile

HOST_URL="http://gameres.repong.cn:8080"

def md5Checksum(filePath):
    fh = open(filePath, 'rb')
    m = hashlib.md5()
    while True:
        data = fh.read(8192)
        if not data:
            break
        m.update(data)
    return m.hexdigest()


def collect_files(dir,assetsObj,basename,ignores):
    files = os.listdir(dir)
    for entry in files:
        beIgnore = False
        for pattern in ignores:
            if re.search(pattern, entry):
                print "%s ignored" % entry
                beIgnore = True
                break

        if beIgnore :
            continue

        fullpath=os.path.join(dir,entry)
        if os.path.isdir(fullpath):
		    collect_files(fullpath,assetsObj, os.path.join(basename,os.path.basename(fullpath)),ignores)
        else:
            if entry[0]=='.': continue
            key = os.path.join(basename,entry)

            assetsObj[key]={"md5":md5Checksum(fullpath)}


def main():
    from optparse import OptionParser
    parser = OptionParser("usage: %prog [options] {project_root}")
    parser.add_option("-o","--out", dest="outdir",help="out put dir")
    parser.add_option("-v", "--version", dest="version",default="", help="version")
    parser.add_option("--host", dest="hosturl",help="host url")
    parser.add_option("-p", action="store", type="string", dest="platform",help="platform(ios/android)")
    parser.add_option("-c","--compress",action="store_true",default=False, dest="compress",help="compress zip")
    parser.add_option("-m", dest="minFrameworkVersion",type="int",help="min framework version")
    parser.add_option("-u", dest="updateFrameworkUrl",help="update framework url")

    (opts, args) = parser.parse_args()

    if len(args) == 0:
        parser.error('invalid number of arguments')

    workingDir = os.path.dirname(inspect.getfile(inspect.currentframe()))
    assetsPath = os.path.join(workingDir, args[0])

    outdir = workingDir
    if opts.outdir:
        outdir = opts.outdir

    projectPath = os.path.join(outdir, "project.manifest")
    versionPath = os.path.join(outdir, "version.manifest")
    versionName = "None"
    if opts.version:
        versionName = opts.version.replace(" ","")

    host_url = HOST_URL
    if opts.hosturl:
        host_url = opts.hosturl.replace(" ","")

    platform = "ios"
    if opts.platform:
        platform = opts.platform.replace(" ","")

    minFrameworkVersion = -1
    if opts.minFrameworkVersion:
        minFrameworkVersion = opts.minFrameworkVersion

    updateFrameworkUrl = ""
    if opts.updateFrameworkUrl:
        updateFrameworkUrl = opts.updateFrameworkUrl.replace(" ","")
        
    compress = opts.compress

    print "assetsPath ",assetsPath
    print "outdir ",outdir
    print "compress",compress
    print "version" , versionName
    print "host_url" , host_url
    print "platform" , platform

    if not os.path.isdir(assetsPath):
        raise Exception("asset folder not exits")


    engineVersion = "3.0 beta"
    version = opts.version.replace(" ","")
    packageUrl = "%s/%s/" % (host_url,platform)
    remoteManifestUrl = "%s/%s/res/project.manifest" % (host_url,platform)
    remoteVersionUrl = "%s/%s/res/version.manifest" % (host_url,platform)
    assetsObj = {}
    collect_files(assetsPath+"src/",assetsObj,"src/",[".git",".svn"])
    collect_files(assetsPath+"res/",assetsObj,"res/",[".git",".svn"])

    manifestJson={}
    manifestJson["engineVersion"]=engineVersion
    manifestJson["version"]=version
    manifestJson["packageUrl"]=packageUrl
    manifestJson["remoteManifestUrl"]=remoteManifestUrl
    manifestJson["remoteVersionUrl"]=remoteVersionUrl
    manifestJson["minFrameworkVersion"]=minFrameworkVersion
    manifestJson["updateFrameworkUrl"]=updateFrameworkUrl
    manifestJson["assets"]={}
    manifestJson["searchPaths"]=[]

    print json.dumps(manifestJson)

    try:
        output=open(versionPath,'w')
        output.write(json.dumps(manifestJson))
        output.close()
    except Exception as e:
        raise Exception("error : create file failed")

    if compress:
        zipPath = "%s%s" % (versionPath,".zip")
        zfile = zipfile.ZipFile(zipPath, 'w',zipfile.ZIP_DEFLATED)
        zfile.write(versionPath)
        zfile.close()
        os.rename(zipPath,versionPath)
        #os.remove(versionPath)

    manifestJson["assets"]=assetsObj

    try:
        output = open(projectPath, 'w')
        output.write(json.dumps(manifestJson))
        output.close()
    except Exception as e:
        raise Exception("error : create file failed")

    if compress:
        zipPath = "%s%s" % (projectPath,".zip")
        zfile = zipfile.ZipFile(zipPath, 'w',zipfile.ZIP_DEFLATED)
        zfile.write(projectPath)
        zfile.close()
        os.rename(zipPath,projectPath)
        #os.remove(projectPath)

    print "Successed"
    

if __name__ == '__main__':
    try:
        main()
    except Exception as e:
        traceback.print_exc()
        sys.exit(1)
