from requests import cookies
from selenium import webdriver
import requests
# from ruamel import yaml
import json
import time
import re
import codecs

se = requests.session()
# 填写webdriver的保存目录
driver = webdriver.Chrome()

driver.implicitly_wait(28)  # 隐性等待，最长等30秒
# time.sleep(5)

print('设置浏览器全屏打开')
driver.maximize_window()

# 记得写完整的url 包括http和https
driver.get('https://webnano.test.supers.io')

if __name__ == '__main__':
    Post_url = "https://webnano.test.supers.io/account/app/user_action/user_login"
    Post_data = {
        'mobileOrEmail': '231702@qq.com',
        'password': 'abc123456'
    }
    Text = se.post(Post_url, data=Post_data).text.replace("'", '"').replace('/ ', '/')
    print(Text)
    # file_handle = open('cookies.txt', mode='w')
    doc = codecs.open('C:\\Users\\eqkil\\Desktop\\cookies.txt', 'w', 'utf-8')
    doc.write(Text)
    doc.close()

    # f2 = open("C:\\Users\\eqkil\\Desktop\\cookies.txt")
    # cookies = json.loads(f2.read())
    # for cook in cookies:
    #     driver.add_cookie(cook)
    # 方法1 将expiry类型变为int
    #     for cookie in cookies.txt:
    #         # 并不是所有cookie都含有expiry 所以要用dict的get方法来获取
    #         if isinstance(cookie.get('expiry'), float):
    #             cookie['expiry'] = int(cookie['expiry'])
    #         driver.add_cookie(cookie)

driver.refresh()
