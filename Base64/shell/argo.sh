#!/bin/bash

# Set locale
export LANG=en_US.UTF-8

# Colors for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Ensure script runs as root
if [[ $EUID -ne 0 ]]; then
    echo -e "${YELLOW}Please run this script as root${NC}" >&2
    exit 1
fi

# Detect OS
detect_os() {
    if [[ -f /etc/redhat-release || $(grep -qiE "centos|red hat|redhat" /proc/version) ]]; then
        OS="Centos"
    elif grep -qi "alpine" /etc/issue; then
        OS="alpine"
    elif grep -qi "debian" /etc/issue || grep -qi "debian" /proc/version; then
        OS="Debian"
    elif grep -qi "ubuntu" /etc/issue || grep -qi "ubuntu" /proc/version; then
        OS="Ubuntu"
    else
        echo -e "${RED}Unsupported system. Please use Ubuntu, Debian, or Centos.${NC}" >&2
        exit 1
    fi

    OS_NAME=$(grep -i pretty_name /etc/os-release 2>/dev/null | cut -d\" -f2 || cat /etc/redhat-release 2>/dev/null)
    if [[ $OS_NAME =~ [Aa]rch ]]; then
        echo -e "${RED}Unsupported system: $OS_NAME. Please use Ubuntu, Debian, or Centos.${NC}" >&2
        exit 1
    fi
}

# Detect architecture
detect_arch() {
    case $(uname -m) in
        aarch64) ARCH="arm64" ;;
        x86_64) ARCH="amd64" ;;
        *) echo -e "${RED}Unsupported architecture: $(uname -m)${NC}" >&2; exit 1 ;;
    esac
}

# Install dependencies
install_dependencies() {
    case $OS in
        Debian|Ubuntu)
            apt update -y
            apt install -y curl wget tar gzip cron jq
            ;;
        Centos)
            yum install -y curl wget jq tar
            ;;
        alpine)
            apk update -y
            apk add wget curl tar jq tzdata openssl git grep dcron
            ;;
        *)
            echo -e "${RED}Unsupported system for dependency installation${NC}" >&2
            exit 1
            ;;
    esac
}

# Check WARP status and configure network
configure_network() {
    WGCF_V6=$(curl -s6m5 https://www.cloudflare.com/cdn-cgi/trace -k | grep warp | cut -d= -f2)
    WGCF_V4=$(curl -s4m5 https://www.cloudflare.com/cdn-cgi/trace -k | grep warp | cut -d= -f2)

    if [[ ! $WGCF_V4 =~ on|plus && ! $WGCF_V6 =~ on|plus ]]; then
        configure_resolv
    else
        systemctl stop wg-quick@wgcf >/dev/null 2>&1
        kill -15 $(pgrep warp-go) >/dev/null 2>&1
        sleep 2
        configure_resolv
        systemctl start wg-quick@wgcf >/dev/null 2>&1
        systemctl restart warp-go >/dev/null 2>&1
        systemctl enable warp-go >/dev/null 2>&1
        systemctl start warp-go >/dev/null 2>&1
    fi
}

configure_resolv() {
    if [[ -z $(curl -s4m5 icanhazip.com -k) ]]; then
        cat > /etc/resolv.conf <<EOF
nameserver 2a00:1098:2b::1
nameserver 2a00:1098:2c::1
nameserver 2a01:4f8:c2c:123f::1
EOF
    fi
}

# Uninstall ArgoSB
uninstall() {
    if [[ -n $(ps -e | grep cloudflared) ]]; then
        kill -15 $(cat /etc/s-box-ag/sbargopid.log 2>/dev/null) >/dev/null 2>&1
    fi

    if [[ $OS == "alpine" ]]; then
        rc-service sing-box stop >/dev/null 2>&1
        rc-update del sing-box default >/dev/null 2>&1
        rm -f /etc/init.d/sing-box
    else
        systemctl stop sing-box >/dev/null 2>&1
        systemctl disable sing-box >/dev/null 2>&1
        rm -f /etc/systemd/system/sing-box.service
    fi

    # Remove cron jobs
    crontab -l 2>/dev/null | grep -v "sbargopid" | crontab -

    rm -rf /etc/s-box-ag
    echo "Uninstallation complete"
    exit 0
}

# Show Argo domain
show_argo_domain() {
    ARGO_NAME=$(cat /etc/s-box-ag/sbargoym.log 2>/dev/null)
    if [[ -n $ARGO_NAME ]]; then
        echo "Current fixed Argo domain: $ARGO_NAME"
        echo "Current fixed Argo token: $(cat /etc/s-box-ag/sbargotoken.log 2>/dev/null)"
    else
        ARGO_DOMAIN=$(grep -a trycloudflare.com /etc/s-box-ag/argo.log 2>/dev/null | awk 'NR==2{print $2}' | cut -d/ -f3)
        if [[ -z $ARGO_DOMAIN ]]; then
            echo "Argo temporary domain not generated. Consider reinstalling ArgoSB."
        else
            echo "Current temporary Argo domain: $ARGO_DOMAIN"
        fi
    fi
    exit 0
}

# List configuration
list_config() {
    if [[ -f /etc/s-box-ag/list.txt ]]; then
        cat /etc/s-box-ag/list.txt
    else
        echo "ArgoSB script not installed"
    fi
    exit 0
}

# Install Sing-box
install_singbox() {
    mkdir -p /etc/s-box-ag
    SB_VERSION=$(curl -Ls https://data.jsdelivr.com/v1/package/gh/SagerNet/sing-box | jq -r '.versions[0]')
    SB_NAME="sing-box-$SB_VERSION-linux-$ARCH"
    echo "Downloading Sing-box version: $SB_VERSION"
    curl -L -o /etc/s-box-ag/sing-box.tar.gz --retry 2 https://github.com/SagerNet/sing-box/releases/download/v$SB_VERSION/$SB_NAME.tar.gz

    if [[ -f /etc/s-box-ag/sing-box.tar.gz ]]; then
        tar xzf /etc/s-box-ag/sing-box.tar.gz -C /etc/s-box-ag
        mv /etc/s-box-ag/$SB_NAME/sing-box /etc/s-box-ag
        rm -rf /etc/s-box-ag/{sing-box.tar.gz,$SB_NAME}
    else
        echo -e "${RED}Download failed. Check your network.${NC}" >&2
        exit 1
    fi
}

# Configure Sing-box
configure_singbox() {
    PORT=${port_vm_ws:-$(shuf -i 10000-65535 -n 1)}
    UUID=${UUID:-$(/etc/s-box-ag/sing-box generate uuid)}
    echo "VMess port: $PORT"
    echo "UUID: $UUID"
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
      "listen_port": $PORT,
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
}

# Setup Sing-box service
setup_service() {
    if [[ $OS == "alpine" ]]; then
        cat > /etc/init.d/sing-box <<EOF
#!/sbin/openrc-run
description="Sing-box service"
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
}

# Install and configure Argo Tunnel
setup_argo() {
    ARGO_VERSION=$(curl -Ls https://data.jsdelivr.com/v1/package/gh/cloudflare/cloudflared | jq -r '.versions[0]')
    echo "Downloading Cloudflared version: $ARGO_VERSION"
    curl -L -o /etc/s-box-ag/cloudflared --retry 2 https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-$ARCH
    chmod +x /etc/s-box-ag/cloudflared

    if [[ -n "$ARGO_DOMAIN" && -n "$ARGO_AUTH" ]]; then
        NAME="fixed"
        /etc/s-box-ag/cloudflared tunnel --no-autoupdate --edge-ip-version auto --protocol http2 run --token "$ARGO_AUTH" >/dev/null 2>&1 &
        echo "$!" > /etc/s-box-ag/sbargopid.log
        echo "$ARGO_DOMAIN" > /etc/s-box-ag/sbargoym.log
        echo "$ARGO_AUTH" > /etc/s-box-ag/sbargotoken.log
    else
        NAME="temporary"
        /etc/s-box-ag/cloudflared tunnel --url http://localhost:$PORT --edge-ip-version auto --no-autoupdate --protocol http2 > /etc/s-box-ag/argo.log 2>&1 &
        echo "$!" > /etc/s-box-ag/sbargopid.log
    fi

    echo "Applying for $NAME Argo tunnel..."
    sleep 8

    if [[ -n "$ARGO_DOMAIN" && -n "$ARGO_AUTH" ]]; then
        ARGO_DOMAIN=$(cat /etc/s-box-ag/sbargoym.log 2>/dev/null)
    else
        ARGO_DOMAIN=$(grep -a trycloudflare.com /etc/s-box-ag/argo.log 2>/dev/null | awk 'NR==2{print $2}' | cut -d/ -f3)
    fi

    if [[ -z $ARGO_DOMAIN ]]; then
        echo -e "${RED}$NAME Argo tunnel application failed. Please try again later.${NC}" >&2
        uninstall
    fi
    echo "Argo $NAME tunnel applied successfully: $ARGO_DOMAIN"
}

# Setup cron for Argo persistence
setup_cron() {
    crontab -l 2>/dev/null | grep -v "sbargopid" > /tmp/crontab.tmp
    if [[ -n "$ARGO_DOMAIN" && -n "$ARGO_AUTH" ]]; then
        echo "@reboot /bin/bash -c '/etc/s-box-ag/cloudflared tunnel --no-autoupdate --edge-ip-version auto --protocol http2 run --token $(cat /etc/s-box-ag/sbargotoken.log 2>/dev/null) >/dev/null 2>&1 & pid=\$! && echo \$pid > /etc/s-box-ag/sbargopid.log'" >> /tmp/crontab.tmp
    else
        echo "@reboot /bin/bash -c '/etc/s-box-ag/cloudflared tunnel --url http://localhost:$PORT --edge-ip-version auto --no-autoupdate --protocol http2 > /etc/s-box-ag/argo.log 2>&1 & pid=\$! && echo \$pid > /etc/s-box-ag/sbargopid.log'" >> /tmp/crontab.tmp
    fi
    crontab /tmp/crontab.tmp
    rm -f /tmp/crontab.tmp
}

# Generate VMess links
generate_vmess_links() {
    HOSTNAME=$(hostname)
    cat > /etc/s-box-ag/jh.txt <<EOF
vmess://$(echo "{\"v\": \"2\", \"ps\": \"vmess-ws-tls-argo-$HOSTNAME-443\", \"add\": \"104.16.0.0\", \"port\": \"443\", \"id\": \"$UUID\", \"aid\": \"0\", \"scy\": \"auto\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"$ARGO_DOMAIN\", \"path\": \"/$UUID-vm?ed=2048\", \"tls\": \"tls\", \"sni\": \"$ARGO_DOMAIN\", \"alpn\": \"\", \"fp\": \"\"}" | base64 -w0)
vmess://$(echo "{\"v\": \"2\", \"ps\": \"vmess-ws-tls-argo-$HOSTNAME-8443\", \"add\": \"104.17.0.0\", \"port\": \"8443\", \"id\": \"$UUID\", \"aid\": \"0\", \"scy\": \"auto\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"$ARGO_DOMAIN\", \"path\": \"/$UUID-vm?ed=2048\", \"tls\": \"tls\", \"sni\": \"$ARGO_DOMAIN\", \"alpn\": \"\", \"fp\": \"\"}" | base64 -w0)
vmess://$(echo "{\"v\": \"2\", \"ps\": \"vmess-ws-tls-argo-$HOSTNAME-2053\", \"add\": \"104.18.0.0\", \"port\": \"2053\", \"id\": \"$UUID\", \"aid\": \"0\", \"scy\": \"auto\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"$ARGO_DOMAIN\", \"path\": \"/$UUID-vm?ed=2048\", \"tls\": \"tls\", \"sni\": \"$ARGO_DOMAIN\", \"alpn\": \"\", \"fp\": \"\"}" | base64 -w0)
vmess://$(echo "{\"v\": \"2\", \"ps\": \"vmess-ws-tls-argo-$HOSTNAME-2083\", \"add\": \"104.19.0.0\", \"port\": \"2083\", \"id\": \"$UUID\", \"aid\": \"0\", \"scy\": \"auto\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"$ARGO_DOMAIN\", \"path\": \"/$UUID-vm?ed=2048\", \"tls\": \"tls\", \"sni\": \"$ARGO_DOMAIN\", \"alpn\": \"\", \"fp\": \"\"}" | base64 -w0)
vmess://$(echo "{\"v\": \"2\", \"ps\": \"vmess-ws-tls-argo-$HOSTNAME-2087\", \"add\": \"104.20.0.0\", \"port\": \"2087\", \"id\": \"$UUID\", \"aid\": \"0\", \"scy\": \"auto\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"$ARGO_DOMAIN\", \"path\": \"/$UUID-vm?ed=2048\", \"tls\": \"tls\", \"sni\": \"$ARGO_DOMAIN\", \"alpn\": \"\", \"fp\": \"\"}" | base64 -w0)
vmess://$(echo "{\"v\": \"2\", \"ps\": \"vmess-ws-tls-argo-$HOSTNAME-2096\", \"add\": \"[2606:4700::]\", \"port\": \"2096\", \"id\": \"$UUID\", \"aid\": \"0\", \"scy\": \"auto\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"$ARGO_DOMAIN\", \"path\": \"/$UUID-vm?ed=2048\", \"tls\": \"tls\", \"sni\": \"$ARGO_DOMAIN\", \"alpn\": \"\", \"fp\": \"\"}" | base64 -w0)
vmess://$(echo "{\"v\": \"2\", \"ps\": \"vmess-ws-argo-$HOSTNAME-80\", \"add\": \"104.21.0.0\", \"port\": \"80\", \"id\": \"$UUID\", \"aid\": \"0\", \"scy\": \"auto\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"$ARGO_DOMAIN\", \"path\": \"/$UUID-vm?ed=2048\", \"tls\": \"\"}" | base64 -w0)
vmess://$(echo "{\"v\": \"2\", \"ps\": \"vmess-ws-argo-$HOSTNAME-8080\", \"add\": \"104.22.0.0\", \"port\": \"8080\", \"id\": \"$UUID\", \"aid\": \"0\", \"scy\": \"auto\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"$ARGO_DOMAIN\", \"path\": \"/$UUID-vm?ed=2048\", \"tls\": \"\"}" | base64 -w0)
vmess://$(echo "{\"v\": \"2\", \"ps\": \"vmess-ws-argo-$HOSTNAME-8880\", \"add\": \"104.24.0.0\", \"port\": \"8880\", \"id\": \"$UUID\", \"aid\": \"0\", \"scy\": \"auto\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"$ARGO_DOMAIN\", \"path\": \"/$UUID-vm?ed=2048\", \"tls\": \"\"}" | base64 -w0)
vmess://$(echo "{\"v\": \"2\", \"ps\": \"vmess-ws-argo-$HOSTNAME-2052\", \"add\": \"104.25.0.0\", \"port\": \"2052\", \"id\": \"$UUID\", \"aid\": \"0\", \"scy\": \"auto\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"$ARGO_DOMAIN\", \"path\": \"/$UUID-vm?ed=2048\", \"tls\": \"\"}" | base64 -w0)
vmess://$(echo "{\"v\": \"2\", \"ps\": \"vmess-ws-argo-$HOSTNAME-2082\", \"add\": \"104.26.0.0\", \"port\": \"2082\", \"id\": \"$UUID\", \"aid\": \"0\", \"scy\": \"auto\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"$ARGO_DOMAIN\", \"path\": \"/$UUID-vm?ed=2048\", \"tls\": \"\"}" | base64 -w0)
vmess://$(echo "{\"v\": \"2\", \"ps\": \"vmess-ws-argo-$HOSTNAME-2086\", \"add\": \"104.27.0.0\", \"port\": \"2086\", \"id\": \"$UUID\", \"aid\": \"0\", \"scy\": \"auto\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"$ARGO_DOMAIN\", \"path\": \"/$UUID-vm?ed=2048\", \"tls\": \"\"}" | base64 -w0)
vmess://$(echo "{\"v\": \"2\", \"ps\": \"vmess-ws-argo-$HOSTNAME-2095\", \"add\": \"[2400:cb00:2049::]\", \"port\": \"2095\", \"id\": \"$UUID\", \"aid\": \"0\", \"scy\": \"auto\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"$ARGO_DOMAIN\", \"path\": \"/$UUID-vm?ed=2048\", \"tls\": \"\"}" | base64 -w0)
EOF
}

# Generate configuration output
generate_config_output() {
    BASE_URL=$(base64 -w 0 < /etc/s-box-ag/jh.txt)
    LINE1=$(sed -n '1p' /etc/s-box-ag/jh.txt)
    LINE6=$(sed -n '6p' /etc/s-box-ag/jh.txt)
    LINE7=$(sed -n '7p' /etc/s-box-ag/jh.txt)
    LINE13=$(sed -n '13p' /etc/s-box-ag/jh.txt)

    cat > /etc/s-box-ag/list.txt <<EOF
---------------------------------------------------------
---------------------------------------------------------
Single Node Configuration:
1. VMess-WS-TLS-Argo node on port 443, default IPv4: 104.16.0.0
$LINE1

2. VMess-WS-TLS-Argo node on port 2096, default IPv6: [2606:4700::] (requires IPv6 support)
$LINE6

3. VMess-WS-Argo node on port 80, default IPv4: 104.21.0.0
$LINE7

4. VMess-WS-Argo node on port 2095, default IPv6: [2400:cb00:2049::] (requires IPv6 support)
$LINE13

---------------------------------------------------------
Aggregated Node Configuration:
5. Argo nodes covering 13 ports and IPs: 7 non-TLS ports (80 series), 6 TLS ports (443 series)
$BASE_URL
---------------------------------------------------------
EOF
    cat /etc/s-box-ag/list.txt
}

# Main logic
main() {
    detect_os
    detect_arch
    HOSTNAME=$(hostname)

    # Handle command-line arguments
    case "$1" in
        del) uninstall ;;
        agn) show_argo_domain ;;
        list) list_config ;;
    esac

    # Check Sing-box status
    STATUS_CMD=$([[ $OS == "alpine" ]] && echo "rc-service sing-box status" || echo "systemctl status sing-box")
    STATUS_PATTERN=$([[ $OS == "alpine" ]] && echo "started" || echo "active")

    if [[ -n $($STATUS_CMD 2>/dev/null | grep -w "$STATUS_PATTERN") && -f /etc/s-box-ag/sb.json ]]; then
        echo "ArgoSB script is already running"
        exit 0
    elif [[ -z $($STATUS_CMD 2>/dev/null | grep -w "$STATUS_PATTERN") && -f /etc/s-box-ag/sb.json ]]; then
        echo "ArgoSB script is installed but not running. Uninstalling..."
        uninstall
    fi

    echo "VPS System: $OS_NAME"
    echo "CPU Architecture: $ARCH"
    echo "Installing ArgoSB script..."
    sleep 3

    install_dependencies
    configure_network
    install_singbox
    configure_singbox
    setup_service
    setup_argo
    setup_cron
    generate_vmess_links
    generate_config_output

    echo "ArgoSB script installation completed"
}

main "$@"
