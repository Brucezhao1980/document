import yaml
import random
import string

random_str = ''.join(random.sample(string.ascii_letters + string.digits, 6))  # 随机6位字符串
f = open('par_4.yaml', 'r', encoding='utf-8')
cfg = f.read()
data = yaml.load(cfg, Loader=yaml.FullLoader)
print(data)

key = list(data)[0]['params'][0]['name']
print(key)
c_dict = {}

for i in data:
    if i != "enum":
        for value in list(data)[0]['params'][0]['enum']:
            # print(value)
            c_dict[key] = value
            print(c_dict)
    else:
        c_dict[key] = random.randint(1, 10)
        print(c_dict)
        c_dict[key] = random_str
        print(c_dict)
