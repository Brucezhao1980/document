#!/bin/bash

#保留文件数
ReservedNum=5
FileDir=/data/logs/cfd
date=$(date "+%Y%m%d-%H%M%S")

FileNum=$(ls -l $FileDir|grep ^- |wc -l)

while(( $FileNum > $ReservedNum))
do
    OldFile=$(ls -rt $FileDir| head -1)
    echo  $date "Delete File:"$OldFile
    rm -rf $FileDir/$OldFile
    let "FileNum--"
done 
