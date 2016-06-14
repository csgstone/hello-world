#! /bin/sh

PROTOC_PATH="protoc"

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"


for protofile in `ls *.proto`
do
	echo "=======>$protofile"
	PREFIX=${protofile%.*}
	$PROTOC_PATH  --descriptor_set_out=${PREFIX}.pb $protofile
	xxd -i ${PREFIX}.pb ${PREFIX}.c
done


