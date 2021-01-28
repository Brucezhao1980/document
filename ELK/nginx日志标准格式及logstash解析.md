

## nginx日志标准格式
```
        log_format  access
                        # client
                        '$http_x_real_ip $http_x_forwarded_for $remote_addr $remote_port - $remote_user '
                        '[$time_local] "$http_user_agent" "$http_referer" "$ssl_protocol" "$ssl_cipher" '
                        # request
                        '"$request_id" "$request_method" "$scheme" "$server_name" "$request" '
                        '$https $limit_rate "$request_filename" "$request_uri" "$http_cookie" '
                        '$request_length "$request_completion" $request_time '
                        # response
                        '"$server_protocol" $status [$time_local] $content_length "$content_type" $body_bytes_sent '
                        # server
                        # '"$host" "$document_root" "$document_uri" '
                        '"$document_root" "$document_uri" '
                        # proxy pass
                        '$proxy_add_x_forwarded_for $proxy_host $proxy_port "$realpath_root" "$uri" "$query_string" '
                        # upstream
                        '$upstream_addr $upstream_cache_status $upstream_connect_time $upstream_header_time '
                        '$upstream_response_length $upstream_response_time $upstream_status ';
```

## 日志实例

```
- - 123.101.239.193 16737 - - [09/Jul/2019:11:54:14 +0800] "Dalvik/2.1.0 (Linux; U; Android 7.1.1; OPPO R9s Build/NMF26F)" "-" "TLSv1.2" "ECDHE-RSA-AES128-GCM-SHA256" "c7aaf8e2c538918636654867e47efa41" "GET" "https" "mposp2way.cnepay.com" "GET /uploads/banner/main_home_ad_1_android.jpg HTTP/1.1" on 0 "/usr/local/nginx/html/uploads/banner/main_home_ad_1_android.jpg" "/uploads/banner/main_home_ad_1_android.jpg" "-" 482 "OK" 0.029 "HTTP/1.1" 200 [09/Jul/2019:11:54:14 +0800] - "-" 44223 "/usr/local/nginx/html" "/uploads/banner/main_home_ad_1_android.jpg" 123.101.239.193 mposp2way_v1 80 "/usr/local/nginx/html" "/uploads/banner/main_home_ad_1_android.jpg" "-" 10.1.30.1:29001 - 0.000 0.001 44223 0.002 200

```


## Logstash grok 解析正则

```
(?:%{IPV4:x_real_ip}|-) (?:%{IPV4:x_forward_for}|-) %{IPV4:remote_ip} %{NUMBER:remote_port} (?:%{USER:ident}|-) %{NOTSPACE:auth} \[%{DATA:timestamp}\] "%{DATA:http_user_agent}" (?:"(?:%{URI:http_referrer}|-)"|%{QS:http_referrer}) "%{NOTSPACE:ssl_protocol}" "%{NOTSPACE:ssl_chiper}" "%{BASE16NUM:request_id}" "%{WORD:http_method}" "%{WORD:http_schema}" "%{HOSTNAME:hostname}" "(?:%{WORD:request_verb} %{NOTSPACE:request} (?:HTTP/%{NUMBER:http_version})?)" (?:{WORD:is_https_on}|) %{NUMBER:limit_rate} "%{NOTSPACE:request_filename}" "%{NOTSPACE:request_uri}" "%{DATA:cookie}" %{NUMBER:request_lenth} "%{WORD:request_completion}" %{NUMBER:request_time} "%{DATA:server_protocol}" %{NUMBER:reponse_status} \[%{DATA:reps_bgn_time}\] (?:%{NUMBER:content_length}|-) "%{DATA:content_type}" %{NUMBER:body_bytes_sent} "%{NOTSPACE:document_root}" "%{NOTSPACE:document_uri}" (?:%{IPV4:proxy_add_x_forward_for}|-) (?:%{NOTSPACE:proxy_host}|-) (?:%{NUMBER:proxy_port}|-) "%{NOTSPACE:realpath_root}" "%{NOTSPACE:uri}" "%{NOTSPACE:query_string}" (?:%{URIHOST:upstream_addr}|-) (?:%{DATA:upstream_cache_status}|-) (?:%{NUMBER:upstream_connect_time}|-) (?:%{NUMBER:upstream_header_time}|-) (?:%{NUMBER:upstream_response_length}|-) (?:%{NUMBER:upstream_response_time}|-) (?:%{NUMBER:upstream_status}|-)
```

## Logstash grok 转意之后的解析正则
```
"(?:%{IPV4:x_real_ip}|-) (?:%{IPV4:x_forward_for}|-) %{IPV4:remote_ip} %{NUMBER:remote_port} (?:%{USER:ident}|-) %{NOTSPACE:auth} \[%{DATA:timestamp}\] \"%{DATA:http_user_agent}\" (?:\"(?:%{URI:http_referrer}|-)\"|%{QS:http_referrer}) \"%{NOTSPACE:ssl_protocol}\" \"%{NOTSPACE:ssl_chiper}\" \"%{BASE16NUM:request_id}\" \"%{WORD:http_method}\" \"%{WORD:http_schema}\" \"%{HOSTNAME:hostname}\" \"(?:%{WORD:request_verb} %{NOTSPACE:request} (?:HTTP/%{NUMBER:http_version})?)\" (?:%{WORD:is_https_on}|) %{NUMBER:limit_rate} \"%{NOTSPACE:request_filename}\" \"%{NOTSPACE:request_uri}\" \"%{DATA:cookie}\" %{NUMBER:request_lenth} \"%{WORD:request_completion}\" %{NUMBER:request_time} \"%{DATA:server_protocol}\" %{NUMBER:reponse_status} \[%{DATA:reps_bgn_time}\] (?:%{NUMBER:content_length}|-) \"%{DATA:content_type}\" %{NUMBER:body_bytes_sent} \"%{NOTSPACE:document_root}\" \"%{NOTSPACE:document_uri}\" (?:%{IPV4:proxy_add_x_forward_for}|-) (?:%{NOTSPACE:proxy_host}|-) (?:%{NUMBER:proxy_port}|-) \"%{NOTSPACE:realpath_root}\" \"%{NOTSPACE:uri}\" \"%{NOTSPACE:query_string}\" (?:%{URIHOST:upstream_addr}|-) (?:%{DATA:upstream_cache_status}|-) (?:%{NUMBER:upstream_connect_time}|-) (?:%{NUMBER:upstream_header_time}|-) (?:%{NUMBER:upstream_response_length}|-) (?:%{NUMBER:upstream_response_time}|-) (?:%{NUMBER:upstream_status}|-)"

```