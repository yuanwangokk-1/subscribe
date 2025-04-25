#!/bin/bash

# 设置语言环境
export LANG=en_US.UTF-8

# 输出颜色
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 确保以 root 权限运行
[[ $EUID -ne 0 ]] && echo -e "${YELLOW}请以root模式运行脚本${NC}" && exit 1

# 检测操作系统
if [[ -f /etc/redhat-release || $(grep -qiE "centos|red hat|redhat" /proc/version) ]]; then
    release="Centos"
elif grep -qi "alpine" /etc/issue; then
    release="alpine"
elif grep -qi "debian" /etc/issue || grep -qi "debian" /proc/version; then
    release="Debian"
elif grep -qi "ubuntu" /etc/issue || grep -qi "ubuntu" /proc/version; then
    release="Ubuntu"
else
    echo -e "${RED}脚本不支持当前的系统，请选择使用Ubuntu,Debian,Centos系统。${NC}" && exit 1
fi

op=$(grep -i pretty_name /etc/os-release 2>/dev/null | cut -d\" -f2 || cat /etc/redhat-release 2>/dev/null)
if [[ $op =~ [Aa]rch ]]; then
    echo -e "${RED}脚本不支持当前的 $op 系统，请选择使用Ubuntu,Debian,Centos系统。${NC}" && exit 1
fi

# 检测架构
case $(uname -m) in
    aarch64) cpu=arm64 ;;
    x86_64) cpu=amd64 ;;
    *) echo -e "${RED}目前脚本不支持$(uname -m)架构${NC}" && exit 1 ;;
esac

# 初始化变量
hostname=$(hostname)
UUID=${uuid:-$(uuidgen 2>/dev/null || /etc/s-box-ag/sing-box generate uuid)}
port_vm_ws=${vmpt:-$(shuf -i 10000-65535 -n 1)}
ARGO_DOMAIN=${agn:-}
ARGO_AUTH=${agk:-}

# 卸载函数
del() {
    [[ -n $(ps -e | grep cloudflared) ]] && kill -15 $(cat /etc/s-box-ag/sbargopid.log 2>/dev/null) >/dev/null 2>&1
    if [[ $release == "alpine" ]]; then
        rc-service sing-box stop >/dev/null 2>&1
        rc-update del sing-box default >/dev/null 2>&1
        rm -f /etc/init.d/sing-box
    else
        systemctl stop sing-box >/dev/null 2>&1
        systemctl disable sing-box >/dev/null 2>&1
        rm -f /etc/systemd/system/sing-box.service
    fi
    crontab -l 2>/dev/null | grep -v "sbargopid" | crontab -
    rm -rf /etc/s-box-ag
    echo "卸载完成"
    exit 0
}

# 显示 Argo 域名
agn() {
    argoname=$(cat /etc/s-box-ag/sbargoym.log 2>/dev/null)
    if [[ -n $argoname ]]; then
        echo "当前argo固定域名：$argoname"
        echo "当前argo固定域名token：$(cat /etc/s-box-ag/sbargotoken.log 2>/dev/null)"
    else
        argodomain=$(grep -a trycloudflare.com /etc/s-box-ag/argo.log 2>/dev/null | awk 'NR==2{print $2}' | cut -d/ -f3)
        if [[ -z $argodomain ]]; then
            echo "当前argo临时域名未生成，建议卸载重装ArgoSB脚本"
        else
            echo "当前argo最新临时域名：$argodomain"
        fi
    fi
    exit 0
}

# 列出配置
list() {
    if [[ -f /etc/s-box-ag/list.txt ]]; then
        cat /etc/s-box-ag/list.txt
    else
        echo "ArgoSB脚本未安装"
    fi
    exit 0
}

# 处理命令行参数
[[ "$1" == "del" ]] && del
[[ "$1" == "agn" ]] && agn
[[ "$1" == "list" ]] && list

# 检查 Sing-box 状态
status_cmd=$([[ $release == "alpine" ]] && echo "rc-service sing-box status" || echo "systemctl status sing-box")
status_pattern=$([[ $release == "alpine" ]] && echo "started" || echo "active")
if [[ -n $($status_cmd 2>/dev/null | grep -w "$status_pattern") && -f /etc/s-box-ag/sb.json ]]; then
    echo "ArgoSB脚本已在运行中" && exit 0
elif [[ -z $($status_cmd 2>/dev/null | grep -w "$status_pattern") && -f /etc/s-box-ag/sb.json ]]; then
    echo "ArgoSB脚本已安装，但未启动，脚本将卸载……" && del
fi

echo "VPS系统：$op"
echo "CPU架构：$cpu"
echo "ArgoSB脚本未安装，开始安装…………" && sleep 3

# 安装依赖
if command -v apt &>/dev/null; then
    apt update -y && apt install -y curl wget tar gzip cron jq
elif command -v yum &>/dev/null; then
    yum install -y curl wget jq tar
elif command -v apk &>/dev/null; then
    apk update -y && apk add wget curl tar jq tzdata openssl git grep dcron
else
    echo -e "${RED}不支持当前系统，请手动安装依赖。${NC}" && exit 1
fi

# 配置网络
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
    kill -15 $(pgrep warp-go) >/dev/null 2>&1 && sleep 2
    v4orv6
    systemctl start wg-quick@wgcf >/dev/null 2>&1
    systemctl restart warp-go >/dev/null 2>&1
    systemctl enable warp-go >/dev/null 2>&1
    systemctl start warp-go >/dev/null 2>&1
fi

# 安装 Sing-box
mkdir -p /etc/s-box-ag
sbcore=$(curl -Ls https://data.jsdelivr.com/v1/package/gh/SagerNet/sing-box | grep -Eo '"[0-9.]+",' | head -n1 | tr -d '",')
sbname="sing-box-$sbcore-linux-$cpu"
echo "下载sing-box最新正式版内核：$sbcore"
curl -L -o /etc/s-box-ag/sing-box.tar.gz --retry 2 https://github.com/SagerNet/sing-box/releases/download/v$sbcore/$sbname.tar.gz
if [[ -f /etc/s-box-ag/sing-box.tar.gz ]]; then
    tar xzf /etc/s-box-ag/sing-box.tar.gz -C /etc/s-box-ag
    mv /etc/s-box-ag/$sbname/sing-box /etc/s-box-ag
    rm -rf /etc/s-box-ag/{sing-box.tar.gz,$sbname}
else
    echo -e "${RED}下载失败，请检测网络${NC}" && exit 1
fi

# 配置 Sing-box
echo "当前vmess主协议端口：$port_vm_ws"
echo "当前uuid密码：$UUID"
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
      "type": "vmess",
      "tag": "vmess-sb",
      "listen": "::",
      "listen_port": $port_vm_ws,
      "users": [
        {
          "uuid": "$UUID",
          "alterId": 0
        }
      ],
      "transport": {
        "type": "ws",
        "path": "/$UUID-vm",
        "max_early_data": 2048,
        "early_data_header_name": "Sec-WebSocket-Protocol"
      },
      "tls": {
        "enabled": false,
        "server_name": "www.bing.com",
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

# 设置 Sing-box 服务
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

# 安装并配置 Argo
argocore=$(curl -Ls https://data.jsdelivr.com/v1/package/gh/cloudflare/cloudflared | grep -Eo '"[0-9.]+",' | head -n1 | tr -d '",')
echo "下载cloudflared-argo最新正式版内核：$argocore"
curl -L -o /etc/s-box-ag/cloudflared --retry 2 https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-$cpu
chmod +x /etc/s-box-ag/cloudflared
if [[ -n "$ARGO_DOMAIN" && -n "$ARGO_AUTH" ]]; then
    name="固定"
    /etc/s-box-ag/cloudflared tunnel --no-autoupdate --edge-ip-version auto --protocol http2 run --token "$ARGO_AUTH" >/dev/null 2>&1 &
    echo "$!" > /etc/s-box-ag/sbargopid.log
    echo "$ARGO_DOMAIN" > /etc/s-box-ag/sbargoym.log
    echo "$ARGO_AUTH" > /etc/s-box-ag/sbargotoken.log
else
    name="临时"
    /etc/s-box-ag/cloudflared tunnel --url http://localhost:$port_vm_ws --edge-ip-version auto --no-autoupdate --protocol http2 > /etc/s-box-ag/argo.log 2>&1 &
    echo "$!" > /etc/s-box-ag/sbargopid.log
fi
echo "申请Argo$name隧道中……请稍等"
sleep 8
if [[ -n "$ARGO_DOMAIN" && -n "$ARGO_AUTH" ]]; then
    argodomain=$ARGO_DOMAIN
else
    argodomain=$(grep -a trycloudflare.com /etc/s-box-ag/argo.log 2>/dev/null | awk 'NR==2{print $2}' | cut -d/ -f3)
fi
if [[ -n $argodomain ]]; then
    echo "Argo$name隧道申请成功，域名为：$argodomain"
else
    echo -e "${RED}Argo$name隧道申请失败，请稍后再试${NC}" && del
fi

# 设置 cron
crontab -l 2>/dev/null | grep -v "sbargopid" > /tmp/crontab.tmp
if [[ -n "$ARGO_DOMAIN" && -n "$ARGO_AUTH" ]]; then
    echo "@reboot /bin/bash -c '/etc/s-box-ag/cloudflared tunnel --no-autoupdate --edge-ip-version auto --protocol http2 run --token $(cat /etc/s-box-ag/sbargotoken.log 2>/dev/null) >/dev/null 2>&1 & pid=\$! && echo \$pid > /etc/s-box-ag/sbargopid.log'" >> /tmp/crontab.tmp
else
    echo "@reboot /bin/bash -c '/etc/s-box-ag/cloudflared tunnel --url http://localhost:$port_vm_ws --edge-ip-version auto --no-autoupdate --protocol http2 > /etc/s-box-ag/argo.log 2>&1 & pid=\$! && echo \$pid > /etc/s-box-ag/sbargopid.log'" >> /tmp/crontab.tmp
fi
crontab /tmp/crontab.tmp
rm -f /tmp/crontab.tmp

# 生成 VMess 链接
vmatls_link1="vmess://$(echo "{\"v\": \"2\", \"ps\": \"vmess-ws-tls-argo-$hostname-443\", \"add\": \"104.16.0.0\", \"port\": \"443\", \"id\": \"$UUID\", \"aid\": \"0\", \"scy\": \"auto\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"$argodomain\", \"path\": \"/$UUID-vm?ed=2048\", \"tls\": \"tls\", \"sni\": \"$argodomain\", \"alpn\": \"\", \"fp\": \"\"}" | base64 -w0)"
echo "$vmatls_link1" > /etc/s-box-ag/jh.txt
vmatls_link2="vmess://$(echo "{\"v\": \"2\", \"ps\": \"vmess-ws-tls-argo-$hostname-8443\", \"add\": \"104.17.0.0\", \"port\": \"8443\", \"id\": \"$UUID\", \"aid\": \"0\", \"scy\": \"auto\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"$argodomain\", \"path\": \"/$UUID-vm?ed=2048\", \"tls\": \"tls\", \"sni\": \"$argodomain\", \"alpn\": \"\", \"fp\": \"\"}" | base64 -w0)"
echo "$vmatls_link2" >> /etc/s-box-ag/jh.txt
vmatls_link3="vmess://$(echo "{\"v\": \"2\", \"ps\": \"vmess-ws-tls-argo-$hostname-2053\", \"add\": \"104.18.0.0\", \"port\": \"2053\", \"id\": \"$UUID\", \"aid\": \"0\", \"scy\": \"auto\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"$argodomain\", \"path\": \"/$UUID-vm?ed=2048\", \"tls\": \"tls\", \"sni\": \"$argodomain\", \"alpn\": \"\", \"fp\": \"\"}" | base64 -w0)"
echo "$vmatls_link3" >> /etc/s-box-ag/jh.txt
vmatls_link4="vmess://$(echo "{\"v\": \"2\", \"ps\": \"vmess-ws-tls-argo-$hostname-2083\", \"add\": \"104.19.0.0\", \"port\": \"2083\", \"id\": \"$UUID\", \"aid\": \"0\", \"scy\": \"auto\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"$argodomain\", \"path\": \"/$UUID-vm?ed=2048\", \"tls\": \"tls\", \"sni\": \"$argodomain\", \"alpn\": \"\", \"fp\": \"\"}" | base64 -w0)"
echo "$vmatls_link4" >> /etc/s-box-ag/jh.txt
vmatls_link5="vmess://$(echo "{\"v\": \"2\", \"ps\": \"vmess-ws-tls-argo-$hostname-2087\", \"add\": \"104.20.0.0\", \"port\": \"2087\", \"id\": \"$UUID\", \"aid\": \"0\", \"scy\": \"auto\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"$argodomain\", \"path\": \"/$UUID-vm?ed=2048\", \"tls\": \"tls\", \"sni\": \"$argodomain\", \"alpn\": \"\", \"fp\": \"\"}" | base64 -w0)"
echo "$vmatls_link5" >> /etc/s-box-ag/jh.txt
vmatls_link6="vmess://$(echo "{\"v\": \"2\", \"ps\": \"vmess-ws-tls-argo-$hostname-2096\", \"add\": \"[2606:4700::]\", \"port\": \"2096\", \"id\": \"$UUID\", \"aid\": \"0\", \"scy\": \"auto\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"$argodomain\", \"path\": \"/$UUID-vm?ed=2048\", \"tls\": \"tls\", \"sni\": \"$argodomain\", \"alpn\": \"\", \"fp\": \"\"}" | base64 -w0)"
echo "$vmatls_link6" >> /etc/s-box-ag/jh.txt
vma_link7="vmess://$(echo "{\"v\": \"2\", \"ps\": \"vmess-ws-argo-$hostname-80\", \"add\": \"104.21.0.0\", \"port\": \"80\", \"id\": \"$UUID\", \"aid\": \"0\", \"scy\": \"auto\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"$argodomain\", \"path\": \"/$UUID-vm?ed=2048\", \"tls\": \"\"}" | base64 -w0)"
echo "$vma_link7" >> /etc/s-box-ag/jh.txt
vma_link8="vmess://$(echo "{\"v\": \"2\", \"ps\": \"vmess-ws-argo-$hostname-8080\", \"add\": \"104.22.0.0\", \"port\": \"8080\", \"id\": \"$UUID\", \"aid\": \"0\", \"scy\": \"auto\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"$argodomain\", \"path\": \"/$UUID-vm?ed=2048\", \"tls\": \"\"}" | base64 -w0)"
echo "$vma_link8" >> /etc/s-box-ag/jh.txt
vma_link9="vmess://$(echo "{\"v\": \"2\", \"ps\": \"vmess-ws-argo-$hostname-8880\", \"add\": \"104.24.0.0\", \"port\": \"8880\", \"id\": \"$UUID\", \"aid\": \"0\", \"scy\": \"auto\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"$argodomain\", \"path\": \"/$UUID-vm?ed=2048\", \"tls\": \"\"}" | base64 -w0)"
echo "$vma_link9" >> /etc/s-box-ag/jh.txt
vma_link10="vmess://$(echo "{\"v\": \"2\", \"ps\": \"vmess-ws-argo-$hostname-2052\", \"add\": \"104.25.0.0\", \"port\": \"2052\", \"id\": \"$UUID\", \"aid\": \"0\", \"scy\": \"auto\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"$argodomain\", \"path\": \"/$UUID-vm?ed=2048\", \"tls\": \"\"}" | base64 -w0)"
echo "$vma_link10" >> /etc/s-box-ag/jh.txt
vma_link11="vmess://$(echo "{\"v\": \"2\", \"ps\": \"vmess-ws-argo-$hostname-2082\", \"add\": \"104.26.0.0\", \"port\": \"2082\", \"id\": \"$UUID\", \"aid\": \"0\", \"scy\": \"auto\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"$argodomain\", \"path\": \"/$UUID-vm?ed=2048\", \"tls\": \"\"}" | base64 -w0)"
echo "$vma_link11" >> /etc/s-box-ag/jh.txt
vma_link12="vmess://$(echo "{\"v\": \"2\", \"ps\": \"vmess-ws-argo-$hostname-2086\", \"add\": \"104.27.0.0\", \"port\": \"2086\", \"id\": \"$UUID\", \"aid\": \"0\", \"scy\": \"auto\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"$argodomain\", \"path\": \"/$UUID-vm?ed=2048\", \"tls\": \"\"}" | base64 -w0)"
echo "$vma_link12" >> /etc/s-box-ag/jh.txt
vma_link13="vmess://$(echo "{\"v\": \"2\", \"ps\": \"vmess-ws-argo-$hostname-2095\", \"add\": \"[2400:cb00:2049::]\", \"port\": \"2095\", \"id\": \"$UUID\", \"aid\": \"0\", \"scy\": \"auto\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"$argodomain\", \"path\": \"/$UUID-vm?ed=2048\", \"tls\": \"\"}" | base64 -w0)"
echo "$vma_link13" >> /etc/s-box-ag/jh.txt

# 生成配置输出
baseurl=$(base64 -w 0 < /etc/s-box-ag/jh.txt)
line1=$(sed -n '1p' /etc/s-box-ag/jh.txt)
line6=$(sed -n '6p' /etc/s-box-ag/jh.txt)
line7=$(sed -n '7p' /etc/s-box-ag/jh.txt)
line13=$(sed -n '13p' /etc/s-box-ag/jh.txt)
echo "ArgoSB脚本安装完毕" && sleep 2
cat > /etc/s-box-ag/list.txt <<EOF
---------------------------------------------------------
---------------------------------------------------------
单节点配置输出：
1、443端口的vmess-ws-tls-argo节点，默认优选IPV4：104.16.0.0
$line1

2、2096端口的vmess-ws-tls-argo节点，默认优选IPV6：[2606:4700::]（本地网络支持IPV6才可用）
$line6

3、80端口的vmess-ws-argo节点，默认优选IPV4：104.21.0.0
$line7

4、2095端口的vmess-ws-argo节点，默认优选IPV6：[2400:cb00:2049::]（本地网络支持IPV6才可用）
$line13

---------------------------------------------------------
聚合节点配置输出：
5、Argo节点13个端口及不死IP全覆盖：7个关tls 80系端口节点、6个开tls 443系端口节点
$baseurl
---------------------------------------------------------
EOF
cat /etc/s-box-ag/list.txt
