#!/bin/bash
# 全部变量
LOOP_COND=100
LOG_PREFIX_PATH=/data/logs/

# 需要检测的docker实例列表
CONTAINER_NAMES=( "versatile" "operation" "nacos" "rmqconsole" "broker-a-m" "rmqnamesrv-a" "account" "kline" "cfd" "open-api" "gateway" "futuretrading_web" )

MAIL_LIST="292737314@qq.com,bomb_as@163.com"
PROFILE="DEV"

DOCKER_INSTANCE_SIZE=${#CONTAINER_NAMES[@]}

function print_docker_info() {
    echo "DOCKER_INSTANCE_SIZE: "${DOCKER_INSTANCE_SIZE}
    echo -n "docker实例包括: ["
    COUNT=0
    for ELEM in ${CONTAINER_NAMES[@]}
    do
        echo -n "${ELEM}"
        if [ $COUNT -ne $((${DOCKER_INSTANCE_SIZE}-1)) ]; then
            echo -n "; "
        fi
        COUNT=$((COUNT+1))
    done
    echo "]"  # e.g. [Intance1, Instance2]
}

function check_docker_instance() {
    COUNT=0
    for ELEM in ${CONTAINER_NAMES[@]}
    do
        docker ps | tail -n +2 | awk '{print $NF}' | grep -i $ELEM &>/dev/null
        RES=$?
        if [ $RES -ne 0 ]; then
	    CURR_TIME=`date --rfc-3339=seconds`
	    echo "[$PROFILE] $CURR_TIME - docker server [$ELEM] has stopped, please check it!!!" | mail -s "Docker服务监控告警" ${MAIL_LIST} &>/dev/null
        else
	    COUNT=$((COUNT+1))
        fi
    done

    if [ $COUNT -eq ${DOCKER_INSTANCE_SIZE} ]; then
        echo -e "\e[1;32m" # 显示健康的绿色
        echo -e "Docker全服务健康。。。。\n"
    fi
}

function check_log_last_modify_time() {
    cd ${LOG_PREFIX_PATH} # 切换到logs目录
    echo "Current Path: "$PWD
    # 遍历日志目录, 生成服务日志路径数组	
    LOG_LIST=$(ls -la | awk '{print $9}' | tail -n +4 | sort)
    set OLD_IFS $IFS
    set IFS=,
    ARR=($LOG_LIST)
    echo "开始check_log_last_modify_time...."
    for line in ${ARR[@]} 
    do
	CURR_PATH="${LOG_PREFIX_PATH}${line}"
	echo ${CURR_PATH}
	LATEST_LOG_FILE=$(ls -althr | tail -n 1 | awk '{print $NF}')
	if [ ${LATEST_LOG_FILE} != "." ]; then
	    MODIFY_TIME=''
	    IS_CHINESE=-1
	    stat "${LATEST_LOG_FILE}" | grep "最近更改"
	    RES=$?
	    if [ $RES -eq 0 ]; then
		MODIFY_TIME=$(stat "${LATEST_LOG_FILE}" | grep "最近更改" | awk '{split($(NF-1),VAR,"."); print VAR[1]}')
		IS_CHINESE=1
	    else
		MODIFY_TIME=$(stat "${LATEST_LOG_FILE}" | grep "Modify:" | awk '{split($(NF-1),VAR,"."); print VAR[1]}')
		IS_CHINESE=0
	    fi
	    #echo "MODIFY_TIME: "${MODIFY_TIME}
	    sudo touch temp_file
	    LATTEST_TIME=''
	    if [ ${IS_CHINESE} -eq 1 ]; then
		LATTEST_TIME=$(stat temp_file | grep "最近更改" | awk '{split($(NF-1),VAR,"."); print VAR[1]}')
	    else
		LATTEST_TIME=$(stat temp_file | grep "最近更改" | awk '{split($(NF-1),VAR,"."); print VAR[1]}')
	    fi
	    #echo "LATTEST_TIME: "${LATTEST_TIME}
	    TIME_DELTA=`echo eval $(($(date +%s -d "${LATTEST_TIME}") - $(date +%s -d "${MODIFY_TIME}"))) | cut -d ' ' -f2`
	    #echo "TIME_DELTA: "${TIME_DELTA}
	    if [[ ${TIMh_DELTA} -gt 180 ]] || [[ ${TIME_DELTA} -lt -180 ]]; then
		echo "${LATEST_LOG_FILE} has 180 seconds logs to lost!"
	    fi
	    echo ""
	    #break
	fi
    done
    set IFS $OLD_IFS
    echo "结束check_log_last_modify_time...."
}

# 主逻辑
# 1: 打印待监测实例
print_docker_info

# 2: 循环检测实例活跃状态
while [ $LOOP_COND -eq 100 ]
do
    check_docker_instance
    check_log_last_modify_time
    sleep 30
done

# 3: 测试日志最近的修改
check_log_last_modify_time

echo -e "\e[1;m"
exit 0
