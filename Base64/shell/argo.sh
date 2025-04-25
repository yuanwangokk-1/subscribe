#!/bin/bash

# Constants
VERSION="25.4.24-beta3"
CONFIG_DIR="/etc/s-box-ag"
SINGBOX_URL="https://github.com/SagerNet/sing-box/releases/download"
CLOUDFLARED_URL="https://github.com/cloudflare/cloudflared/releases/latest/download"
LOG_FILE="$CONFIG_DIR/install.log"

# Colors for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

# Initialize logging
init_logging() {
    mkdir -p "$CONFIG_DIR"
    touch "$LOG_FILE"
    exec 1>>"$LOG_FILE" 2>&1
}

# Print colored message
print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Check root privileges
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_message "$RED" "Please run as root"
        exit 1
    fi
}

# Detect system
detect_system() {
    local os_release
    os_release=$(cat /etc/os-release 2>/dev/null | grep -i pretty_name | cut -d\" -f2)
    
    if [[ -f /etc/redhat-release || "$os_release" =~ CentOS|Red Hat ]]; then
        SYSTEM="Centos"
        PKG_MANAGER="yum"
    elif [[ "$os_release" =~ Ubuntu ]]; then
        SYSTEM="Ubuntu"
        PKG_MANAGER="apt"
    elif [[ "$os_release" =~ Debian ]]; then
        SYSTEM="Debian"
        PKG_MANAGER="apt"
    elif [[ "$os_release" =~ Alpine ]]; then
        SYSTEM="alpine"
        PKG_MANAGER="apk"
    else
        print_message "$RED" "Unsupported system: $os_release. Please use Ubuntu, Debian, or Centos."
        exit 1
    fi

    if [[ "$os_release" =~ Arch ]]; then
        print_message "$RED" "Arch Linux is not supported."
        exit 1
    fi
}

# Detect architecture
detect_architecture() {
    case $(uname -m) in
        aarch64) ARCH="arm64";;
        x86_64) ARCH="amd64";;
        *) print_message "$RED" "Unsupported architecture: $(uname -m)"; exit 1;;
    esac
}

# Install dependencies
install_dependencies() {
    print_message "$YELLOW" "Installing dependencies..."
    case $PKG_MANAGER in
        apt)
            apt update -y
            apt install -y curl wget tar gzip cron jq
            ;;
        yum)
            yum install -y curl wget jq tar
            ;;
        apk)
            apk update
            apk add wget curl tar jq tzdata openssl git grep dcron
            ;;
    esac
}

# Download and install sing-box
install_singbox() {
    local sb_version sb_name
    sb_version=$(curl -Ls https://data.jsdelivr.com/v1/package/gh/SagerNet/sing-box | jq -r '.versions[0]')
    sb_name="sing-box-$sb_version-linux-$ARCH"
    
    print_message "$GREEN" "Downloading sing-box version: $sb_version"
    if ! curl -L -o "$CONFIG_DIR/sing-box.tar.gz" --retry 2 "$SINGBOX_URL/v$sb_version/$sb_name.tar.gz"; then
        print_message "$RED" "Failed to download sing-box"
        exit 1
    fi

    tar xzf "$CONFIG_DIR/sing-box.tar.gz" -C "$CONFIG_DIR"
    mv "$CONFIG_DIR/$sb_name/sing-box" "$CONFIG_DIR/"
    rm -rf "$CONFIG_DIR/sing-box.tar.gz" "$CONFIG_DIR/$sb_name"
}

# Configure sing-box
configure_singbox() {
    PORT_VM_WS=${PORT_VM_WS:-$(shuf -i 10000-65535 -n 1)}
    UUID=${UUID:-$("$CONFIG_DIR/sing-box" generate uuid)}
    
    print_message "$GREEN" "VMess port: $PORT_VM_WS"
    print_message "$GREEN" "UUID: $UUID"

    cat > "$CONFIG_DIR/sb.json" <<EOF
{
    "log": {
        "disabled": false,
        "level": "info",
        "timestamp": true
    },
    "inbounds": [{
        "type": "vmess",
        "tag": "vmess-sb",
        "listen": "::",
        "listen_port": ${PORT_VM_WS},
        "users": [{
            "uuid": "${UUID}",
            "alterId": 0
        }],
        "transport": {
            "type": "ws",
            "path": "${UUID}-vm",
            "max_early_data": 2048,
            "early_data_header_name": "Sec-WebSocket-Protocol"
        },
        "tls": {
            "enabled": false,
            "server_name": "www.bing.com",
            "certificate_path": "$CONFIG_DIR/cert.pem",
            "key_path": "$CONFIG_DIR/private.key"
        }
    }],
    "outbounds": [{
        "type": "direct",
        "tag": "direct"
    }]
}
EOF
}

# Install and configure cloudflared
install_cloudflared() {
    local argo_version
    argo_version=$(curl -Ls https://data.jsdelivr.com/v1/package/gh/cloudflare/cloudflared | jq -r '.versions[0]')
    
    print_message "$GREEN" "Downloading cloudflared version: $argo_version"
    if ! curl -L -o "$CONFIG_DIR/cloudflared" --retry 2 "$CLOUDFLARED_URL/cloudflared-linux-$ARCH"; then
        print_message "$RED" "Failed to download cloudflared"
        exit 1
    fi
    chmod +x "$CONFIG_DIR/cloudflared"
}

# Setup Argo tunnel
setup_argo_tunnel() {
    local name
    if [[ -n "$ARGO_DOMAIN" && -n "$ARGO_AUTH" ]]; then
        name="fixed"
        "$CONFIG_DIR/cloudflared" tunnel --no-autoupdate --edge-ip-version auto --protocol http2 run --token "$ARGO_AUTH" >/dev/null 2>&1 &
        echo "$!" > "$CONFIG_DIR/sbargopid.log"
        echo "$ARGO_DOMAIN" > "$CONFIG_DIR/sbargoym.log"
        echo "$ARGO_AUTH" > "$CONFIG_DIR/sbargotoken.log"
    else
        name="temporary"
        "$CONFIG_DIR/cloudflared" tunnel --url "http://localhost:$PORT_VM_WS" --edge-ip-version auto --no-autoupdate --protocol http2 > "$CONFIG_DIR/argo.log" 2>&1 &
        echo "$!" > "$CONFIG_DIR/sbargopid.log"
    fi
    
    sleep 8
    ARGO_DOMAIN=$( [[ -n "$ARGO_DOMAIN" ]] && cat "$CONFIG_DIR/sbargoym.log" || grep -a trycloudflare.com "$CONFIG_DIR/argo.log" | awk 'NR==2{print}' | awk -F// '{print $2}' | awk '{print $1}' )
    
    if [[ -z "$ARGO_DOMAIN" ]]; then
        print_message "$RED" "Failed to create Argo $name tunnel"
        cleanup
        exit 1
    fi
    print_message "$GREEN" "Argo $name tunnel created: $ARGO_DOMAIN"
}

# Generate VMess links
generate_vmess_links() {
    local hostname=$(hostname)
    local links=()
    
    # TLS-enabled links
    local tls_ports=(443 8443 2053 2083 2087 2096)
    local tls_ips=("104.16.0.0" "104.17.0.0" "104.18.0.0" "104.19.0.0" "104.20.0.0" "[2606:4700::]")
    
    for i in "${!tls_ports[@]}"; do
        links+=("vmess://$(echo "{ \"v\": \"2\", \"ps\": \"vmess-ws-tls-argo-$hostname-${tls_ports[i]}\", \"add\": \"${tls_ips[i]}\", \"port\": \"${tls_ports[i]}\", \"id\": \"$UUID\", \"aid\": \"0\", \"scy\": \"auto\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"$ARGO_DOMAIN\", \"path\": \"/$UUID-vm?ed=2048\", \"tls\": \"tls\", \"sni\": \"$ARGO_DOMAIN\", \"alpn\": \"\", \"fp\": \"\"}" | base64 -w0)")
    done
    
    # Non-TLS links
    local non_tls_ports=(80 8080 8880 2052 2082 2086 2095)
    local non_tls_ips=("104.21.0.0" "104.22.0.0" "104.24.0.0" "104.25.0.0" "104.26.0.0" "104.27.0.0" "[2400:cb00:2049::]")
    
    for i in "${!non_tls_ports[@]}"; do
        links+=("vmess://$(echo "{ \"v\": \"2\", \"ps\": \"vmess-ws-argo-$hostname-${non_tls_ports[i]}\", \"add\": \"${non_tls_ips[i]}\", \"port\": \"${non_tls_ports[i]}\", \"id\": \"$UUID\", \"aid\": \"0\", \"scy\": \"auto\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"$ARGO_DOMAIN\", \"path\": \"/$UUID-vm?ed=2048\", \"tls\": \"\"}" | base64 -w0)")
    done
    
    printf "%s\n" "${links[@]}" > "$CONFIG_DIR/jh.txt"
}

# Generate configuration output
generate_config_output() {
    local baseurl=$(base64 -w 0 < "$CONFIG_DIR/jh.txt")
    cat > "$CONFIG_DIR/list.txt" <<EOF
---------------------------------------------------------
Single Node Configuration:
1. VMess-WS-TLS-Argo (Port 443, IPv4: 104.16.0.0)
$(sed -n '1p' "$CONFIG_DIR/jh.txt")

2. VMess-WS-TLS-Argo (Port 2096, IPv6: [2606:4700::])
$(sed -n '6p' "$CONFIG_DIR/jh.txt")

3. VMess-WS-Argo (Port 80, IPv4: 104.21.0.0)
$(sed -n '7p' "$CONFIG_DIR/jh.txt")

4. VMess-WS-Argo (Port 2095, IPv6: [2400:cb00:2049::])
$(sed -n '13p' "$CONFIG_DIR/jh.txt")

---------------------------------------------------------
Aggregated Node Configuration:
5. All 13 ports (7 non-TLS, 6 TLS)
$baseurl
---------------------------------------------------------
EOF
}

# Cleanup function
cleanup() {
    if [[ -n $(pgrep cloudflared) ]]; then
        kill -15 "$(cat "$CONFIG_DIR/sbargopid.log" 2>/dev/null)" >/dev/null 2>&1
    fi
    
    if [[ "$SYSTEM" == "alpine" ]]; then
        rc-service sing-box stop 2>/dev/null
        rc-update del sing-box default 2>/dev/null
        rm -f /etc/init.d/sing-box
    else
        systemctl stop sing-box >/dev/null 2>&1
        systemctl disable sing-box >/dev/null 2>&1
        rm -f /etc/systemd/system/sing-box.service
    fi
    
    rm -rf "$CONFIG_DIR"
    print_message "$GREEN" "Cleanup completed"
}

# Main installation
main() {
    init_logging
    print_message "$GREEN" "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    print_message "$GREEN" "ArgoSB One-Click Script (Version: $VERSION)"
    print_message "$GREEN" "GitHub: github.com/yonggekkk"
    print_message "$GREEN" "Blog: ygkkk.blogspot.com"
    print_message "$GREEN" "YouTube: www.youtube.com/@ygkkk"
    print_message "$GREEN" "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    
    export LANG=en_US.UTF-8
    check_root
    detect_system
    detect_architecture
    install_dependencies
    install_singbox
    configure_singbox
    install_cloudflared
    setup_argo_tunnel
    generate_vmess_links
    generate_config_output
    
    print_message "$GREEN" "ArgoSB installation completed successfully"
    cat "$CONFIG_DIR/list.txt"
}

# Handle command-line arguments
case "$1" in
    del)
        cleanup
        ;;
    agn)
        if [[ -f "$CONFIG_DIR/sbargoym.log" ]]; then
            print_message "$GREEN" "Fixed Argo domain: $(cat "$CONFIG_DIR/sbargoym.log")"
            print_message "$GREEN" "Token: $(cat "$CONFIG_DIR/sbargotoken.log")"
        elif [[ -f "$CONFIG_DIR/argo.log" ]]; then
            local domain=$(grep -a trycloudflare.com "$CONFIG_DIR/argo.log" | awk 'NR==2{print}' | awk -F// '{print $2}' | awk '{print $1}')
            [[ -n "$domain" ]] && print_message "$GREEN" "Temporary Argo domain: $domain" || print_message "$YELLOW" "No temporary domain found. Consider reinstalling."
        else
            print_message "$RED" "ArgoSB not installed"
        fi
        ;;
    list)
        if [[ -f "$CONFIG_DIR/list.txt" ]]; then
            cat "$CONFIG_DIR/list.txt"
        else
            print_message "$RED" "ArgoSB not installed"
        fi
        ;;
    *)
        main
        ;;
esac
