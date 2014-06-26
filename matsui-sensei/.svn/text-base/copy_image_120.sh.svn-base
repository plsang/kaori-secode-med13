#!/bin/bash

if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <filelist> <pat>" >&2
  exit 1
fi

featdir=/net/per610a/export/das11f/plsang/trecvidmed13/feature/keyframes/covdet.hessian.sift.cb4000.devel.soft

filelist=$1
pat=$2
feature='covdet.hessian.sift.cb4000.devel.soft'

out_dir=$featdir-kinddevel/$pat/
if [ ! -d $out_dir ]
then
	mkdir -p $out_dir
fi

count=0
while read video; do    
	in_dir=$featdir/devel/$video.mat
	let count++;
	vid_out_dir=$out_dir/$video
	msg="[$count] cp -R $in_dir $vid_out_dir"
	echo $msg
	if [ ! -d $vid_out_dir ]
	then
		mkdir -p $vid_out_dir
	fi
	cp $in_dir $vid_out_dir
done < $filelist