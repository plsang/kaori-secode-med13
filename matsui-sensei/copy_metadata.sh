#!/bin/bash

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <filelist>" >&2
  exit 1
fi

filelist=$1

out_dir=/net/per610a/export/das11f/plsang/trecvidmed13/metadata/segment-10/kinddevel/
if [ ! -d $out_dir ]
then
	mkdir -p $out_dir
fi

count=0
while read video; do    
	in_file=/net/per610a/export/das11f/plsang/trecvidmed13/metadata/segment-10/devel/$video.lst
	let count++;
	msg="[$count] cp -R $in_file $out_dir"
	echo $msg
	cp $in_file $out_dir
done < $filelist