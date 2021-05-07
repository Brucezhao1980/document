#!/bin/bash
 
FILENAME=account

function While_read_LINE(){
#读取行内容
cat $FILENAME | while read LINE
do
echo "$LINE"

##拆分字符串到数组
str=$LINE

IFS=";"
arr=($str)

s1=${arr[0]}
s2=${arr[1]}

curl -G -d "country=78&email=${s1}&verificationcode=123123&password=${s2}"  https://*********/account/app/user_registered/registered >./123.txt
done
}
While_read_LINE
