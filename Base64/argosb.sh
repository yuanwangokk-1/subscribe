#!/bin/bash
export LANG=en_US.UTF-8

# 检查 root 权限
[[ $EUID -ne 0 ]] && { echo -e "\033[33m请以root模式运行脚本\033[0m"; exit 1; }

# 检测操作系统
if [[ -f /etc/redhat-release || $(grep -qi "centos|red hat|redhat" /proc/version) ]]; then
    release="Centos"
elif grep -qi "alpine" /etc/issue; then
    release="alpine"
elif grep -qi "debian" /etc/issue || grep -qi "debian" /proc/version; then
    release="Debian"
elif grep -qi "ubuntu" /etc/issue || grep -qi "ubuntu" /proc/version; then
    release="Ubuntu"
else
    echo -e "\033[31m脚本不支持当前系统，请使用Ubuntu、Debian或Centos系统。\033[0m"
    exit 1
fi

# 检查 Arch Linux
op=$(cat /etc/redhat-release 2>/dev/null || grep -i pretty_name /etc/os-release 2>/dev/null | cut -d\" -f2)
if [[ $op =~ [Aa]rch ]]; then
    echo -e "\033[31m脚本不支持 $op 系统，请使用Ubuntu、Debian或Centos系统。\033[0m"
    exit 1
fi

# 检测 CPU 架构
case $(uname -m) in
    aarch64) cpu=arm64;;
    x86_64) cpu=amd64;;
    *) echo -e "\033[31m目前脚本不支持$(uname -m)架构\033[0m"; exit 1;;
esac

# 虚拟化检测
vi=$(systemd-detect-virt 2>/dev/null || virt-what 2>/dev/null)

# 变量
hostname=$(hostname)
export UUID=${uuid:-$(uuidgen)}
export port_vless=${vmpt:-$(shuf -i 10000-65535 -n 1)}
export ARGO_DOMAIN=${agn:-''}
export ARGO_AUTH=${agk:-''}

# 颜色输出函数
red() { echo -e "\033[31m$1\033[0m"; }
yellow() { echo -e "\033[33m$1\033[0m"; }

# 卸载函数
del() {
    [[ -n $(pgrep cloudflared) ]] && kill -15 $(cat /etc/s-box-ag/sbargopid.log 2>/dev/null) >/dev/null 2>&1
    if [[ $release == "alpine" ]]; then
        rc-service sing-box stop 2>/dev/null
        rc-update del sing-box default 2>/dev/null
        rm -f /etc/init.d/sing-box
    else
        systemctl stop sing-box >/dev/null 2>&1
        systemctl disable sing-box >/dev/null 2>&1
        rm -f /etc/systemd/system/sing-box.service
    fi
    crontab -l | grep -v "sbargopid" | crontab -
    rm -rf /etc/s-box-ag
    echo "卸载完成"
    exit 0
}

# 显示 Argo 域名
agn() {
    argoname=$(cat /etc/s-box-ag/sbargoym.log 2>/dev/null)
    if [[ -z $argoname ]]; then
        argodomain=$(grep -a trycloudflare.com /etc/s-box-ag/argo.log 2>/dev/null | awk 'NR==2{print $2}' | cut -d/ -f3)
        [[ -z $argodomain ]] && echo "当前Argo临时域名未生成，建议卸载重装ArgoSB脚本" || echo "当前Argo最新临时域名：$argodomain"
    else
        echo "当前Argo固定域名：$argoname"
        echo "当前Argo固定域名token：$(cat /etc/s-box-ag/sbargotoken.log 2>/dev/null)"
    fi
    exit 0
}

# 列出节点配置
list() {
    [[ -f /etc/s-box-ag/list.txt ]] && cat /etc/s-box-ag/list.txt || echo "ArgoSB脚本未安装"
    exit 0
}

# 处理命令行参数
case $1 in
    del) del;;
    agn) agn;;
    list) list;;
esac

# 检查 sing-box 状态
if [[ $release == "alpine" ]]; then
    status_cmd="rc-service sing-box status"
    status_pattern="started"
else
    status_cmd="systemctl status sing-box"
    status_pattern="active"
fi

if [[ -n $($status_cmd 2>/dev/null | grep -w "$status_pattern") && -f /etc/s-box-ag/sb.json ]]; then
    echo "ArgoSB脚本已在运行中"
    exit 0
elif [[ -z $($status_cmd 2>/dev/null | grep -w "$status_pattern") && -f /etc/s-box-ag/sb.json ]]; then
    echo "ArgoSB脚本已安装，但未启动，脚本将卸载……"
    del
fi

echo "VPS系统：$op"
echo "CPU架构：$cpu"
echo "ArgoSB脚本未安装，开始安装…………"
sleep 3

# 安装依赖
if command -v apt >/dev/null; then
    apt update -y
    apt install -y curl wget tar gzip cron jq
elif command -v yum >/dev/null; then
    yum install -y curl wget jq tar
elif command -v apk >/dev/null; then
    apk update
    apk add wget curl tar jq tzdata openssl git grep dcron
else
    red "不支持当前系统，请手动安装依赖。"
    exit 1
fi

# 检查并配置 WARP
warpcheck() {
    wgcfv6=$(curl -s6m5 https://www.cloudflare.com/cdn-cgi/trace -k | grep warp | cut -d= -f2)
    wgcfv4=$(curl -s4m5 https://www.cloudflare.com/cdn-cgi/trace -k | grep warp | cut -d= -f2)
}

v4orv6() {
    [[ -z $(curl -s4m5 icanhazip.com -k) ]] && echo -e "nameserver 2a00:1098:2b::1\nnameserver 2a00:1098:2c::1\nnameserver 2a01:4f8:c2c:123f::1" > /etc/resolv.conf
}

warpcheck
if [[ ! $wgcfv4 =~ on|plus && ! $wgcfv6 =~ on|plus ]]; then
    v4orv6
else
    systemctl stop wg-quick@wgcf >/dev/null 2>&1
    kill -15 $(pgrep warp-go) >/dev/null 2>&1
    sleep 2
    v4orv6
    systemctl start wg-quick@wgcf >/dev/null 2>&1
    systemctl restart warp-go >/dev/null 2>&1
    systemctl enable warp-go >/dev/null 2>&1
    systemctl start warp-go >/dev/null 2>&1
fi

# 创建目录
mkdir -p /etc/s-box-ag

# 下载并安装 sing-box
sbcore=$(curl -Ls https://data.jsdelivr.com/v1/package/gh/SagerNet/sing-box | grep -Eo '"[0-9.]+",' | head -n1 | tr -d '",')
sbname="sing-box-$sbcore-linux-$cpu"
echo "下载sing-box最新正式版内核：$sbcore"
curl -L -o /etc/s-box-ag/sing-box.tar.gz --retry 2 https://github.com/SagerNet/sing-box/releases/download/v$sbcore/$sbname.tar.gz
if [[ -f /etc/s-box-ag/sing-box.tar.gz ]]; then
    tar xzf /etc/s-box-ag/sing-box.tar.gz -C /etc/s-box-ag
    mv /etc/s-box-ag/$sbname/sing-box /etc/s-box-ag/
    rm -rf /etc/s-box-ag/{sing-box.tar.gz,$sbname}
else
    red "下载sing-box失败，请检查网络"
    exit 1
fi

# 生成 VLESS 配置
echo "当前VLESS端口：$port_vless"
echo "当前UUID：$UUID"
sleep 3

cat > /etc/s-box-ag/sb.json <<EOF
{
  "log": {
    "disabled": false,
    "level": "info",
    "timestamp": true
  },
  "inbounds": [
    {
      "type": "vless",
      "tag": "vless-sb",
      "listen": "::",
      "listen_port": $port_vless,
      "users": [
        {
          "uuid": "$UUID",
          "flow": ""
        }
      ],
      "transport": {
        "type": "ws",
        "path": "/$UUID-vless",
        "max_early_data": 2048,
        "early_data_header_name": "Sec-WebSocket-Protocol"
      },
      "tls": {
        "enabled": true,
        "server_name": "$ARGO_DOMAIN",
        "certificate_path": "/etc/s-box-ag/cert.pem",
        "key_path": "/etc/s-box-ag/private.key"
      }
    }
  ],
  "outbounds": [
    {
      "type": "direct",
      "tag": "direct"
    }
  ]
}
EOF

# 配置 sing-box 服务
if [[ $release == "alpine" ]]; then
    cat > /etc/init.d/sing-box <<EOF
#!/sbin/openrc-run
description="sing-box service"
command="/etc/s-box-ag/sing-box"
command_args="run -c /etc/s-box-ag/sb.json"
command_background=true
pidfile="/var/run/sing-box.pid"
EOF
    chmod +x /etc/init.d/sing-box
    rc-update add sing-box default
    rc-service sing-box start
else
    cat > /etc/systemd/system/sing-box.service <<EOF
[Unit]
After=network.target nss-lookup.target
[Service]
User=root
WorkingDirectory=/root
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_RAW
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_RAW
ExecStart=/etc/s-box-ag/sing-box run -c /etc/s-box-ag/sb.json
ExecReload=/bin/kill -HUP \$MAINPID
Restart=on-failure
RestartSec=10
LimitNOFILE=infinity
[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload
    systemctl enable sing-box >/dev/null 2>&1
    systemctl start sing-box
    systemctl restart sing-box
fi

# 下载并安装 cloudflared
argocore=$(curl -Ls https://data.jsdelivr.com/v1/package/gh/cloudflare/cloudflared | grep -Eo '"[0-9.]+",' | head -n1 | tr -d '",')
echo "下载cloudflared-argo最新正式版内核：$argocore"
curl -L -o /etc/s-box-ag/cloudflared --retry 2 https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-$cpu
chmod +x /etc/s-box-ag/cloudflared

# 设置 Argo 隧道
if [[ -n "$ARGO_DOMAIN" && -n "$ARGO_AUTH" ]]; then
    name="固定"
    /etc/s-box-ag/cloudflared tunnel --no-autoupdate --edge-ip-version auto --protocol http2 run --token "$ARGO_AUTH" >/dev/null 2>&1 &
    echo "$!" > /etc/s-box-ag/sbargopid.log
    echo "$ARGO_DOMAIN" > /etc/s-box-ag/sbargoym.log
    echo "$ARGO_AUTH" > /etc/s-box-ag/sbargotoken.log
else
    name="临时"
    /etc/s-box-ag/cloudflared tunnel --url http://localhost:$port_vless --edge-ip-version auto --no-autoupdate --protocol http2 > /etc/s-box-ag/argo.log 2>&1 &
    echo "$!" > /etc/s-box-ag/sbargopid.log
fi

echo "申请Argo$name隧道中……请稍等"
sleep 8

argodomain=$([[ -n "$ARGO_DOMAIN" && -n "$ARGO_AUTH" ]] && cat /etc/s-box-ag/sbargoym.log 2>/dev/null || grep -a trycloudflare.com /etc/s-box-ag/argo.log 2>/dev/null | awk 'NR==2{print $2}' | cut -d/ -f3)
if [[ -z $argodomain ]]; then
    red "Argo$name隧道申请失败，请稍后再试"
    del
else
    echo "Argo$name隧道申请成功，域名为：$argodomain"
fi

# 设置 crontab
crontab -l | grep -v "sbargopid" > /tmp/crontab.tmp
if [[ -n "$ARGO_DOMAIN" && -n "$ARGO_AUTH" ]]; then
    echo "@reboot /bin/bash -c '/etc/s-box-ag/cloudflared tunnel --no-autoupdate --edge-ip-version auto --protocol http2 run --token \$(cat /etc/s-box-ag/sbargotoken.log 2>/dev/null) >/dev/null 2>&1 & pid=\$! && echo \$pid > /etc/s-box-ag/sbargopid.log'" >> /tmp/crontab.tmp
else
    echo "@reboot /bin/bash -c '/etc/s-box-ag/cloudflared tunnel --url http://localhost:$port_vless --edge-ip-version auto --no-autoupdate --protocol http2 > /etc/s-box-ag/argo.log 2>&1 & pid=\$! && echo \$pid > /etc/s-box-ag/sbargopid.log'" >> /tmp/crontab.tmp
fi
crontab /tmp/crontab.tmp
rm -f /tmp/crontab.tmp

# 生成 VLESS 链接
cat > /etc/s-box-ag/jh.txt <<EOF
vless://$UUID@104.16.0.0:443?encryption=none&security=tls&sni=$argodomain&type=ws&host=$argodomain&path=/$UUID-vless?ed=2048#vless-ws-tls-argo-$hostname-443
vless://$UUID@[2606:4700::]:2096?encryption=none&security=tls&sni=$argodomain&type=ws&host=$argodomain&path=/$UUID-vless?ed=2048#vless-ws-tls-argo-$hostname-2096
vless://$UUID@104.21.0.0:80?encryption=none&security=none&type=ws&host=$argodomain&path=/$UUID-vless?ed=2048#vless-ws-argo-$hostname-80
vless://$UUID@[2400:cb00:2049::]:2095?encryption=none&security=none&type=ws&host=$argodomain&path=/$UUID-vless?ed=2048#vless-ws-argo-$hostname-2095
EOF

baseurl=$(base64 -w 0 < /etc/s-box-ag/jh.txt)
line1=$(sed -n 1p /etc/s-box-ag/jh.txt)
line2=$(sed -n 2p /etc/s-box-ag/jh.txt)
line3=$(sed -n 3p /etc/s-box-ag/jh.txt)
line4=$(sed -n 4p /etc/s-box-ag/jh.txt)

# 输出节点配置
cat > /etc/s-box-ag/list.txt <<EOF
---------------------------------------------------------
单节点配置输出：
1、443端口的VLESS-WS-TLS节点，默认优选IPv4：104.16.0.0
$line1

2、2096端口的VLESS-WS-TLS节点，默认优选IPv6：[2606:4700::]（本地网络支持IPv6才可用）
$line2

3、80端口的VLESS-WS节点，默认优选IPv4：104.21.0.0
$line3

4、2095端口的VLESS-WS节点，默认优选IPv6：[2400:cb00:2049::]（本地网络支持IPv6才可用）
$line4

---------------------------------------------------------
聚合节点配置输出：
5、Argo节点4个端口：2个TLS节点（443, 2096），2个非TLS节点（80, 2095）
$baseurl
---------------------------------------------------------
EOF

echo "ArgoSB脚本安装完毕"
cat /etc/s-box-ag/list.txt