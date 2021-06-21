```
#!/bin/bash


i=231700

while [ $i -le 231710 ]
do
        curl -G -d "country=78&email=$i@qq.com&verificationcode=123123&password=abc123456"  https://webnano.test.supers.io/account/app/user_registered/registered >./123.txt
    let i++ 
    echo $i@qq.com >>./456.txt
done

for line in $(cat 456.txt)
do
      curl -G -d "mobileOrEmail=$line&password=abc123456" https://webnano.test.supers.io/account/app/user_action/user_login |awk -F "[\"\"]" '{print $20,$28}' >>token.txt
done
```

