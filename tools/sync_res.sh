#! /bin/sh


# Rsync parameters


rsync='rsync'
localdir=$1
sourcedir=$2
host=$3
project=$4
user=$5
port=$6
#host="121.43.105.131"
#project="resource/repong/"
#user="www"
#port=8004


function SyncRes() 
{
   if [ ! -d "$localdir" ]; then
       echo "Error: '$localdir' does not exist"
	     exit 1
   fi
   $rsync --port $port -avzr $localdir  $user@$host::$project$sourcedir
   if [ $? != 0 ]; then
       echo "Error: Sync '$localdir' failure"
	     exit 2
   fi
}

    
SyncRes
