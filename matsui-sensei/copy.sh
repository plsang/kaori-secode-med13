#!/bin/bash

if [ "$#" -ne 4 ]; then
  echo "Usage: $0 <filelist> <pat> <segment> <feature>" >&2
  exit 1
fi

featdir=/net/per610a/export/das11f/plsang/trecvidmed13/feature

filelist=$1
pat=$2
segment=$3
feature=$4

out_dir=$featdir/$segment/$feature-kinddevel/$pat/
if [ ! -d $out_dir ]
then
	mkdir -p $out_dir
fi

count=0
while read video; do    
	in_dir=$featdir/$segment/$feature/devel/$video
	let count++;
	msg="[$count] cp -R $in_dir $out_dir"
	echo $msg
	cp -R $in_dir $out_dir
done < $filelist