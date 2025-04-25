#!/bin/bash

# 检查是否以 root 运行
if [[ $EUID -ne 0 ]]; then
    echo "请使用 root 权限运行此脚本！" 
    exit 1
fi

# 安装必要依赖
echo "安装依赖：curl wget jq tar"
if command -v apt &> /dev/null; then
    apt update -y
    apt install -y curl wget jq tar
elif command -v yum &> /dev/null; then
    yum install -y curl wget jq tar
elif command -v apk &> /dev/null; then
    apk add curl wget jq tar
else
    echo "不支持的 Linux 发行版，请手动安装依赖。"
    exit 1
fi

# 下载 argosb.sh 脚本
echo "下载 argosb.sh..."
wget -O /tmp/argosb.sh https://raw.githubusercontent.com/yonggekkk/ArgoSB-script/main/argosb.sh
chmod +x /tmp/argosb.sh

# 运行脚本并捕获输出
echo "正在安装 ArgoSB..."
/tmp/argosb.sh > /tmp/argosb_output.log 2>&1

# 提取节点信息并保存
if [ -f "/etc/s-box-ag/list.txt" ]; then
    echo "节点信息已保存到 argo_nodes.txt"
    cp /etc/s-box-ag/list.txt ./argo_nodes.txt
else
    echo "安装失败，请检查日志：/tmp/argosb_output.log"
    exit 1
fi

# 显示关键信息
echo "===================================="
echo "ArgoSB 安装完成！"
echo "节点配置已保存至: $(pwd)/argo_nodes.txt"
echo "===================================="
