#!/bin/bash

if [[ $EUID -ne 0 ]]; then
	echo -e "脚本必须root账号运行，请切换root用户后再执行本脚本!"
	exit 1
fi

if [[ `which python3` == "" ]]; then
	apt update || yum update
	apt install python3 -y || yum install python3 -y 
fi

cpunumber=$(cat /proc/cpuinfo| grep "processor"| wc -l)
cpup=$(expr ${cpunumber} \* 20)

if [[ `uname -m` == "aarch64" ]]; then
	memorylimit="${cpunumber}*0.6*1024*1024*1024"
elif [[ `uname -m` == "x86_64" ]]; then
	memorylimit="${cpunumber}*0.1*1024*1024*1024"
fi

checkstatus(){
	if [[ -f /tmp/cpu.py ]]; then
		systemctl stop KeepCPU
		systemctl disable KeepCPU
		rm /tmp/cpu.py && rm /etc/systemd/system/KeepCPU.service
	elif [[ -f /etc/systemd/system/KeepCPU.service ]] && [[ -f /root/cpu.py ]]; then
		systemctl stop KeepCPU
		systemctl disable KeepCPU
		rm /root/cpu.py && rm /etc/systemd/system/KeepCPU.service
	elif [[ `ps aux|grep cpumemory.py|wc -l` == 2 ]] && [[ -f /root/cpumemory.py ]]; then
		echo "检测到机器上已经部署过保号脚本了，程序退出。"
		exit 0
	fi
}

config_cpu(){
	checkstatus
	# 配置CPU占用开始
	cat > /etc/systemd/system/KeepCpuMemory.service <<EOF
[Unit]

[Service]
CPUQuota=${cpup}%
ExecStart=/usr/bin/python3 /root/cpumemory.py

[Install]
WantedBy=multi-user.target
EOF

cat > /root/cpumemory.py <<EOF
while True:
	x=1
EOF
	systemctl daemon-reload
	systemctl start KeepCpuMemory
	systemctl enable KeepCpuMemory
	echo "设置CPU占用保号完成。"
}

config_cpu_memory(){
	checkstatus
	cat > /etc/systemd/system/KeepCpuMemory.service <<EOF
[Unit]

[Service]
CPUQuota=${cpup}%
ExecStart=/usr/bin/python3 /root/cpumemory.py

[Install]
WantedBy=multi-user.target
EOF

	cat > /root/cpumemory.py <<EOF
import platform
memory = bytearray(int(${memorylimit}))
while True:
	pass
EOF
	systemctl daemon-reload
	systemctl start KeepCpuMemory
	systemctl enable KeepCpuMemory
	echo "设置CPU、内存占用保号完成。"
}

removesh(){
	if [[ -f /root/cpu.py ]]; then
		systemctl stop KeepCPU
		systemctl disable KeepCPU
		rm /root/cpu.py && rm /etc/systemd/system/KeepCPU.service
	elif [[ -f /root/cpumemory.py ]]; then
		systemctl stop KeepCpuMemory
		systemctl disable KeepCpuMemory
		rm /root/cpumemory.py && rm /etc/systemd/system/KeepCpuMemory.service
	fi
	echo "保号脚本卸载完成！"
}

show_menu(){
    echo ""
    echo "请选择要执行的操作:"
    echo "1. 配置 CPU 占用"
    echo "2. 配置 CPU 和内存占用"
    echo "3. 卸载脚本"
    echo "0. 退出"
    echo ""

    read -p "请输入选项数字: " option

    case $option in
        1)
            config_cpu
            ;;
        2)
            config_cpu_memory
            ;;
        3)
            removesh
            ;;
        0)
            exit 0
            ;;
        *)
            echo "无效的选项，请重新选择。"
            show_menu
            ;;
    esac
}

show_menu