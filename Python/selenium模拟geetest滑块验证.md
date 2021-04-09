selenium模拟geetest滑块验证

参考连接  https://blog.csdn.net/csdn_okcheng/article/details/112598837





```python
from selenium import webdriver
from selenium.webdriver import ActionChains
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.common.action_chains import ActionChains
from PIL import Image
import time

# driver = webdriver.Chrome()
driver = webdriver.Firefox()
driver.get('https://webnano.test.supers.io/user/login')

driver.implicitly_wait(30)  # 隐性等待，最长等30秒

print('设置浏览器全屏打开')
driver.maximize_window()
driver.delete_all_cookies()

# 截图获取图片
def get_snap(driver):
    driver.save_screenshot('snap.png')
    snap_obj = Image.open('snap.png')
    return snap_obj


def get_image(driver):
    img_element = driver.find_element_by_xpath(
        '//div[@class="geetest_panel_next"]//canvas[@class="geetest_canvas_slice geetest_absolute"]')
    size = img_element.size
    location = img_element.location
    left = location['x']
    top = location['y']
    right = left + size['width']
    bottom = top + size['height']
    snap_obj = get_snap(driver)
    img_obj = snap_obj.crop((left, top, right, bottom))
    return img_obj

# 获取移动距离
def get_distance(img1, img2):
    start_x = 60
    threhold = 60  # 阈值
    for x in range(start_x, img1.size[0]):
        for y in range(img1.size[1]):
            rgb1 = img1.load()[x, y]
            rgb2 = img2.load()[x, y]
            res1 = abs(rgb1[0] - rgb2[0])
            res2 = abs(rgb1[1] - rgb2[1])
            res3 = abs(rgb1[2] - rgb2[2])
            if not (res1 < threhold and res2 < threhold and res3 < threhold):
                return x - 9


def get_tracks(distance):
    distance += 0
    v0 = 2
    s = 0
    t = 1
    mid = distance * 3 / 5
    forward_tracks = []
    while s < distance:
        if s < mid:
            a = 2
        else:
            a = -3
        v = v0
        tance = v * t + 1 / 2 * a * t * t
        tance = round(tance)
        s += tance
        v0 = v + a * t
        forward_tracks.append(tance)
    # back_tracks = [-2, -1, -2]  # 20
    return {"forward_tracks": forward_tracks}  # , 'back_tracks': back_tracks}


try:
    driver.get('https://webnano.test.supers.io/user/login')
    driver.implicitly_wait(3)
    input_username = driver.find_elements_by_tag_name("input")[0]
    input_password = driver.find_elements_by_tag_name("input")[1]
    input_username.send_keys('231712@qq.com')
    input_password.send_keys('abc123456')
    driver.find_elements_by_tag_name("button")[0].click()
    time.sleep(2)  # 等待验证码加载
    none_img = get_image(driver)
    driver.execute_script("var x=document.getElementsByClassName('geetest_canvas_fullbg geetest_fade "
                          "geetest_absolute')[0]; "
                          "x.style.display='block';"
                          "x.style.opacity=1"
                          )
    block_img = get_image(driver)
    geetest_slider_button = driver.find_element_by_class_name('geetest_slider_button')

    distance = get_distance(block_img, none_img)
    print(distance)
    tracks_dic = get_tracks(distance)
    print(tracks_dic)
    ActionChains(driver).click_and_hold(geetest_slider_button).perform()
    forword_tracks = tracks_dic['forward_tracks']
    print(forword_tracks)
    # back_tracks = tracks_dic['back_tracks']
    # print(back_tracks)
    for forword_track in forword_tracks:
        ActionChains(driver).move_by_offset(xoffset=forword_track, yoffset=0).perform()
    time.sleep(0.1)
    # for back_tracks in back_tracks:
    #     ActionChains(driver).move_by_offset(xoffset=back_tracks, yoffset=0).perform()
    print(forword_tracks)
    ActionChains(driver).move_by_offset(xoffset=-3, yoffset=0).perform()
    ActionChains(driver).move_by_offset(xoffset=3, yoffset=0).perform()
    time.sleep(0.1)
    ActionChains(driver).release().perform()

    time.sleep(30)
finally:
    driver.close()
```