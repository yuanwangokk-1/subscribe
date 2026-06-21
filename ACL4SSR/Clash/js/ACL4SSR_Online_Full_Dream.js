// 随机延迟
function sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
}
function randInt(min, max) {
    return Math.floor(Math.random() * (max - min + 1)) + min;
}
async function jitterDelay(min = 200, max = 500) {
    await sleep(randInt(min, max));
}

// 判断 HTML
function looksLikeHtml(text) {
    if (!text) return false;
    const t = text.trim().toLowerCase();
    if (t.startsWith("<!doctype html") || t.startsWith("<html") || t.includes("<head") || t.includes("<body")) return true;
    if (t.includes("</html>")) return true;
    return false;
}

// fetch 重试
async function fetchWithRetry(url, maxRetries = 3) {
    let lastErr;

    for (let attempt = 1; attempt <= maxRetries; attempt++) {
        try {
            const res = await fetch(url, { cache: "no-store" });

            if (!res.ok) {
                throw new Error(`HTTP ${res.status}`);
            }

            const text = await res.text();

            if (looksLikeHtml(text)) {
                throw new Error("HTML response");
            }

            return text;
        } catch (e) {
            lastErr = e;
            if (attempt < maxRetries) {
                await jitterDelay(200, 500);
                continue;
            }
        }
    }

    throw lastErr;
}



async function main(config) {

    //config["disable-keep-alive"] = false;
    //config["keep-alive-idle"] = 60;
    //config["keep-alive-interval"] = 45;
    //config["tcp-concurrent"] = true;

    /*
    config.sniffer = {
        sniff: {
            TLS: {
                ports: [443, 8443],
            },
            HTTP: {
                ports: [80, 8080, 8880],
            },
            QUIC: {
                ports: [443, 8443],
            },
        },
        "override-destination": false,
        enable: true,
        "force-dns-mapping": true,
        "skip-domain": [
            "Mijia Cloud",
            "dlg.io.mi.com",
            "+.push.apple.com"
        ],
    };*/

    config.tun = {
        enable: true,
        stack: "system",
        "strict-route": false,
        "auto-route": true,
        "dns-hijack": [
            "any:53"
        ],
        mtu: 1500,
        "disable-icmp-forwarding": true,
        device: "Mihomo",
        "auto-detect-interface": true
    }

    config.dns = {
        enable: true,
        ipv6: false,
        "prefer-h3": false,
        "use-hosts": true,
        "use-system-hosts": true,
        "respect-rules": true,
        "enhanced-mode": "fake-ip",
        "fake-ip-range": "198.18.0.1/16",
        rebind: false,
        "default-nameserver": [
            "119.29.29.29",
            "223.5.5.5"
        ],
        "nameserver": [
            "https://doh.pub/dns-query",
            //"https://223.5.5.5/dns-query",
            "https://dns.alidns.com/dns-query"
            /*"https://cloudflare-dns.com/dns-query",
            "https://public.dns.iij.jp/dns-query",
            "https://dns.google/dns-query"*/
        ],
        /*"fallback": [
            "https://dns.cloudflare.com/dns-query",
            "https://public.dns.iij.jp/dns-query",
            "https://dns.google/dns-query"
        ],*/
        "proxy-server-nameserver": [
            "https://doh.pub/dns-query",
            //"https://223.5.5.5/dns-query",
            "https://dns.alidns.com/dns-query"
        ],
        /*"fallback-filter": {
            "domain": [
                "+.google.com",
                "+.facebook.com",
                "+.youtube.com"
            ],
            "geoip": true,
            "geoip-code": "CN",
            "ipcidr": [
                "240.0.0.0/4",
                "0.0.0.0/32"
            ]
        },*/
        "nameserver-policy": {
            "geosite:cn": [
                "https://doh.pub/dns-query",
                "https://dns.alidns.com/dns-query"
            ],
            "geosite:geolocation-!cn": [
                "https://cloudflare-dns.com/dns-query",
                "https://dns.google/dns-query"
            ],

            /*"geosite:gfw": [
                "https://cloudflare-dns.com/dns-query",
                "https://dns.google/dns-query"
            ],*/
            /*"geosite:cn,private": [
                "system",
                "https://doh.pub/dns-query",
                "https://dns.alidns.com/dns-query"
            ],
            "geoip:cn,private": [
                "system",
                "https://doh.pub/dns-query",
                "https://dns.alidns.com/dns-query"
            ],
            "rule-set:MyDirect": [
                "system",
                "https://doh.pub/dns-query",
                "https://dns.alidns.com/dns-query"
            ],*/
        },
        "fake-ip-filter": [
            "geosite:connectivity-check",
            "geosite:private",
            //"geosite:cn",
            "+.lan",
            "+.local",
            "+.arpa",
            "time.*.com",
            "ntp.*.com",
            "+.market.xiaomi.com",
            "localhost.ptlogin2.qq.com",
            "+.msftncsi.com",
            "www.msftconnecttest.com",
            "mtalk.google.com",
            "mtalk4.google.com",
            "mtalk-staging.google.com",
            "mtalk-dev.google.com",
            "alt1-mtalk.google.com",
            "alt1-mtalk.google.com",
            "alt2-mtalk.google.com",
            "alt3-mtalk.google.com",
            "alt4-mtalk.google.com",
            "alt5-mtalk.google.com",
            "alt6-mtalk.google.com",
            "alt7-mtalk.google.com",
            "alt8-mtalk.google.com"
        ]
    };




    // 固定的 proxy-groups（保持你原来的不变）
    const proxyGroups = [
        {
            name: "🚀 节点选择",
            type: "select",
            proxies: [
                "♻️ 自动选择",
                "🚀 手动切换1",
                "🇺🇲 美国自动",
                "🇭🇰 香港自动",
                "🇨🇳 台湾自动",
                "🇸🇬 狮城自动",
                "🇯🇵 日本自动",
                "DIRECT",
            ],
        },
        {
            name: "🚀 手动切换1",
            "include-all": true,
            type: "select",
        },
        {
            name: "♻️ 自动选择",
            "include-all": true,
            type: "url-test",
            url: "https://cp.cloudflare.com",
            interval: 300,
            tolerance: 200,
            lazy: true,
            timeout: 5000,
            "max-failed-times": 5
        },
        {
            name: "🌍 国外媒体",
            type: "select",
            proxies: [
                "🚀 节点选择",
                "♻️ 自动选择",
                "🚀 手动切换1",
                "🇺🇲 美国自动",
                "🇭🇰 香港自动",
                "🇨🇳 台湾自动",
                "🇸🇬 狮城自动",
                "🇯🇵 日本自动",
                "DIRECT",
            ],
        },
        {
            name: "📢 谷歌FCM",
            type: "select",
            proxies: [
                "🚀 节点选择",
                "♻️ 自动选择",
                "🚀 手动切换1",
                "🇺🇲 美国自动",
                "🇭🇰 香港自动",
                "🇨🇳 台湾自动",
                "🇸🇬 狮城自动",
                "🇯🇵 日本自动",
                "DIRECT",
            ],
        },
        {
            name: "Ⓜ️ 微软云盘",
            type: "select",
            proxies: [
                "🚀 节点选择",
                "♻️ 自动选择",
                "🚀 手动切换1",
                "🇺🇲 美国自动",
                "🇭🇰 香港自动",
                "🇨🇳 台湾自动",
                "🇸🇬 狮城自动",
                "🇯🇵 日本自动",
                "DIRECT",
            ],
        },
        {
            name: "Ⓜ️ 微软服务",
            type: "select",
            proxies: [
                "🚀 节点选择",
                "♻️ 自动选择",
                "🚀 手动切换1",
                "🇺🇲 美国自动",
                "🇭🇰 香港自动",
                "🇨🇳 台湾自动",
                "🇸🇬 狮城自动",
                "🇯🇵 日本自动",
                "DIRECT",
            ],
        },
        {
            name: "🍎 苹果服务",
            type: "select",
            proxies: [
                "🚀 节点选择",
                "♻️ 自动选择",
                "🚀 手动切换1",
                "🇺🇲 美国自动",
                "🇭🇰 香港自动",
                "🇨🇳 台湾自动",
                "🇸🇬 狮城自动",
                "🇯🇵 日本自动",
                "DIRECT",
            ],
        },
        {
            name: "🎮 游戏平台",
            "include-all": true,
            type: "select",
            proxies: [
                "🚀 节点选择",
                "♻️ 自动选择",
                "🚀 手动切换1",
                "🇺🇲 美国自动",
                "🇭🇰 香港自动",
                "🇨🇳 台湾自动",
                "🇸🇬 狮城自动",
                "🇯🇵 日本自动",
                "DIRECT",
            ],
        },
        {
            name: "🔑 RemoteSSH",
            "include-all": true,
            type: "select",
            proxies: [
                "🚀 节点选择",
                "♻️ 自动选择",
                "🚀 手动切换1",
                "🇺🇲 美国自动",
                "🇭🇰 香港自动",
                "🇨🇳 台湾自动",
                "🇸🇬 狮城自动",
                "🇯🇵 日本自动",
                "DIRECT",
            ],
        },
        {
            name: "🎯 全球直连",
            type: "select",
            proxies: [
                "DIRECT",
                "🚀 节点选择",
                "♻️ 自动选择",
                "🚀 手动切换1",
                "🇺🇲 美国自动",
                "🇭🇰 香港自动",
                "🇨🇳 台湾自动",
                "🇸🇬 狮城自动",
                "🇯🇵 日本自动",
            ],
        },
        {
            name: "🐟 漏网之鱼",
            type: "select",
            proxies: [
                "🚀 节点选择",
                "♻️ 自动选择",
                "🚀 手动切换1",
                "🇺🇲 美国自动",
                "🇭🇰 香港自动",
                "🇨🇳 台湾自动",
                "🇸🇬 狮城自动",
                "🇯🇵 日本自动",
                "DIRECT",
            ],
        },

        {
            name: "🇭🇰 香港自动",
            "include-all": true,
            filter: "(?i)香港|港|HK|hk|Hong Kong|HongKong|hongkong",
            type: "url-test",
            url: "https://cp.cloudflare.com",
            interval: 300,
            tolerance: 150,
            lazy: true,
            timeout: 5000,
            "max-failed-times": 5
        },
        {
            name: "🇨🇳 台湾自动",
            "include-all": true,
            filter: "(?i)台|新北|彰化|TW|Taiwan",
            type: "url-test",
            url: "https://cp.cloudflare.com",
            interval: 300,
            tolerance: 150,
            lazy: true,
            timeout: 5000,
            "max-failed-times": 5
        },
        {
            name: "🇺🇲 美国自动",
            "include-all": true,
            //filter:"(?i)美|波特兰|达拉斯|俄勒冈|凤凰城|费利蒙|硅谷|拉斯维加斯|洛杉矶|圣何塞|圣克拉拉|西雅图|芝加哥|US|United States|America|California",
            filter: "(?i)(?:美|波特兰|达拉斯|俄勒冈|凤凰城|费利蒙|硅谷|拉斯维加斯|洛杉矶|圣何塞|圣克拉拉|西雅图|芝加哥|(?<![A-Za-z])US(?:(?=\s*x\d)|(?![A-Za-z]))|USA|UnitedStates|United States|America|California)",
            type: "url-test",
            url: "https://cp.cloudflare.com",
            interval: 300,
            tolerance: 250,
            lazy: true,
            timeout: 5000,
            "max-failed-times": 5
        },
        {
            name: "🇯🇵 日本自动",
            "include-all": true,
            filter: "(?i)日本|川日|东京|大阪|泉日|埼玉|沪日|深日|JP|Japan",
            type: "url-test",
            url: "https://cp.cloudflare.com",
            interval: 300,
            tolerance: 150,
            lazy: true,
            timeout: 5000,
            "max-failed-times": 5
        },
        {
            name: "🇸🇬 狮城自动",
            "include-all": true,
            filter: "(?i)新加坡|坡|狮城|SG|Singapore",
            type: "url-test",
            url: "https://cp.cloudflare.com",
            interval: 300,
            tolerance: 150,
            lazy: true,
            timeout: 5000,
            "max-failed-times": 5
        }
    ];
    // 赋值给 config["proxy-groups"]
    config["proxy-groups"] = proxyGroups;

    // 确保有 rule-providers
    if (!config['rule-providers']) {
        config['rule-providers'] = {};
    }

    // 这里直接用你的原有 rule-providers 定义
    config["rule-providers"] = Object.assign(config["rule-providers"], {
        MyDirect: {
            type: "http",
            behavior: "classical",
            format: "text",
            interval: 86400,
            url: "https://raw.githubusercontent.com/WC-Dream/ACL4SSR/WD/Clash/direct.list",
            path: "./ruleset/MyDirect.txt",
        },
        FCM: {
            type: "http",
            behavior: "classical",
            format: "text",
            interval: 86400,
            url: "https://raw.githubusercontent.com/ACL4SSR/ACL4SSR/master/Clash/Ruleset/GoogleFCM.list",
            path: "./ruleset/FCM.txt",
        },
        Onedrive: {
            type: "http",
            behavior: "classical",
            format: "text",
            interval: 86400,
            url: "https://raw.githubusercontent.com/ACL4SSR/ACL4SSR/master/Clash/OneDrive.list",
            path: "./ruleset/Onedrive.txt",
        },
        Microsoft: {
            type: "http",
            behavior: "classical",
            format: "text",
            interval: 86400,
            url: "https://raw.githubusercontent.com/ACL4SSR/ACL4SSR/master/Clash/Microsoft.list",
            path: "./ruleset/Microsoft.txt",
        },
        Epic: {
            type: "http",
            behavior: "classical",
            format: "text",
            interval: 86400,
            url: "https://raw.githubusercontent.com/ACL4SSR/ACL4SSR/master/Clash/Ruleset/Epic.list",
            path: "./ruleset/Epic.txt",
        },
        Sony: {
            type: "http",
            behavior: "classical",
            format: "text",
            interval: 86400,
            url: "https://raw.githubusercontent.com/ACL4SSR/ACL4SSR/master/Clash/Ruleset/Sony.list",
            path: "./ruleset/Sony.txt",
        },
        Steam: {
            type: "http",
            behavior: "classical",
            format: "text",
            interval: 86400,
            url: "https://raw.githubusercontent.com/ACL4SSR/ACL4SSR/master/Clash/Ruleset/Steam.list",
            path: "./ruleset/Steam.txt",
        },
        MySteam: {
            type: "http",
            behavior: "classical",
            format: "text",
            interval: 86400,
            url: "https://raw.githubusercontent.com/WC-Dream/ACL4SSR/WD/Clash/steam.list",
            path: "./ruleset/MySteam.txt",
        },
        GlobalMedia: {
            type: "http",
            behavior: "classical",
            format: "text",
            interval: 86400,
            url: "https://raw.githubusercontent.com/ACL4SSR/ACL4SSR/master/Clash/ProxyMedia.list",
            path: "./ruleset/GlobalMedia.txt",
        },
        Proxy: {
            type: "http",
            behavior: "classical",
            format: "text",
            interval: 86400,
            url: "https://raw.githubusercontent.com/ACL4SSR/ACL4SSR/master/Clash/ProxyGFWlist.list",
            path: "./ruleset/Proxy.txt",
        },
        MyProxy: {
            type: "http",
            behavior: "classical",
            format: "text",
            interval: 86400,
            url: "https://raw.githubusercontent.com/WC-Dream/ACL4SSR/WD/Clash/proxy.list",
            path: "./ruleset/MyProxy.txt",
        },
        AI: {
            type: "http",
            behavior: "classical",
            format: "text",
            interval: 86400,
            url: "https://ruleset.skk.moe/Clash/non_ip/ai.txt",
            path: "./ruleset/AI.txt",
        },
        TikTok: {
            type: "http",
            behavior: "classical",
            format: "text",
            interval: 86400,
            url: "https://cdn.jsdmirror.com/gh/powerfullz/override-rules@master/ruleset/TikTok.list",
            path: "./ruleset/TikTok.list",
        },
        GoogleFCM: {
            type: "http",
            behavior: "classical",
            interval: 86400,
            format: "text",
            path: "./ruleset/FirebaseCloudMessaging.list",
            url: "https://cdn.jsdmirror.com/gh/powerfullz/override-rules@master/ruleset/FirebaseCloudMessaging.list",
        },
        SSH: {
            type: "http",
            behavior: "classical",
            interval: 86400,
            format: "text",
            path: "./ruleset/ssh.list",
            url: "https://raw.githubusercontent.com/WC-Dream/ACL4SSR/WD/Clash/ssh.list",
        },
        ChinaIP: {
            type: "http",
            behavior: "classical",
            interval: 86400,
            format: "text",
            path: "./ruleset/ChinaIP.list",
            url: "https://raw.githubusercontent.com/ACL4SSR/ACL4SSR/master/Clash/ChinaIp.list",
        },
        MoeGlobal: {
            type: "http",
            behavior: "classical",
            format: "text",
            interval: 86400,
            url: "https://ruleset.skk.moe/List/non_ip/global.conf",
            path: "./ruleset/MoeGlobal.txt",
        },
        MoeChina: {
            type: "http",
            behavior: "classical",
            format: "text",
            interval: 86400,
            url: "https://ruleset.skk.moe/List/non_ip/domestic.conf",
            path: "./ruleset/MoeChina.txt",
        },
        MoeChinaIP: {
            type: "http",
            behavior: "classical",
            format: "text",
            interval: 86400,
            url: "https://ruleset.skk.moe/List/ip/china_ip.conf",
            path: "./ruleset/MoeChinaIP.txt",
        }
        // SpeedTest: {
        //     type: "http",
        //     behavior: "domain",
        //     format: "text",
        //     interval: 86400,
        //     url: "https://ruleset.skk.moe/Clash/domainset/speedtest.txt",
        //     path: "./ruleset/SpeedTest.list",
        // },
        // ... 这里省略你的全部其他 rule-providers 定义
    });

    const providerToProxyGroup_back = {
        MyDirect: "🎯 全球直连",
        MyProxy: "🚀 节点选择",
        FCM: "📢 谷歌FCM",
        GoogleFCM: "📢 谷歌FCM",
        SSH: "🔑 RemoteSSH",
        Onedrive: "Ⓜ️ 微软云盘",
        Microsoft: "Ⓜ️ 微软服务",
        Epic: "🎮 游戏平台",
        Sony: "🎮 游戏平台",
        Steam: "🎮 游戏平台",
        MySteam: "🎮 游戏平台",
        AI: "🚀 节点选择",
        SpeedTest: "🚀 节点选择",
        GlobalMedia: "🌍 国外媒体",
        TikTok: "🌍 国外媒体",
        Proxy: "🚀 节点选择",
        MoeGlobal: "🚀 节点选择",
        MoeChina: "🎯 全球直连",
        MoeChinaIP: "🎯 全球直连",
        ChinaIP: "🎯 全球直连",
        // 其他 provider 可以根据需求继续加
    };

    const providerToProxyGroup = [

        { type: "rule", value: "GEOIP,LAN,🎯 全球直连,no-resolve" },
        { type: "rule", value: "RULE-SET,MyDirect,🎯 全球直连" },
        { type: "rule", value: "GEOSITE,PRIVATE,🎯 全球直连" },
        { type: "rule", value: "GEOIP,PRIVATE,🎯 全球直连,no-resolve" },

        // 自己的
        { type: "provider", name: "MyDirect", group: "🎯 全球直连" },
        { type: "provider", name: "MyProxy", group: "🚀 节点选择" },

        // 更细的规则
        { type: "provider", name: "SSH", group: "🔑 RemoteSSH" },
        { type: "provider", name: "FCM", group: "📢 谷歌FCM" },
        { type: "provider", name: "GoogleFCM", group: "📢 谷歌FCM" },
        { type: "provider", name: "Onedrive", group: "Ⓜ️ 微软云盘" },
        { type: "provider", name: "Microsoft", group: "Ⓜ️ 微软服务" },
        { type: "rule", value: "GEOSITE,APPLE,🍎 苹果服务" },
        { type: "provider", name: "Epic", group: "🎮 游戏平台" },
        { type: "provider", name: "Sony", group: "🎮 游戏平台" },
        { type: "provider", name: "Steam", group: "🎮 游戏平台" },
        { type: "provider", name: "MySteam", group: "🎮 游戏平台" },
        { type: "provider", name: "AI", group: "🚀 节点选择" },
        { type: "provider", name: "TikTok", group: "🌍 国外媒体" },
        { type: "rule", value: "GEOIP,NETFLIX,🌍 国外媒体,no-resolve" },
        { type: "provider", name: "GlobalMedia", group: "🌍 国外媒体" },
        { type: "rule", value: "GEOIP,GOOGLE,🚀 节点选择,no-resolve" },
        { type: "rule", value: "GEOSITE,TELEGRAM,🚀 节点选择" },
        { type: "rule", value: "GEOIP,TELEGRAM,🚀 节点选择,no-resolve" },

        // 大的
        { type: "provider", name: "Proxy", group: "🚀 节点选择" },
        { type: "rule", value: "GEOSITE,gfw,🚀 节点选择" },
        { type: "rule", value: "GEOSITE,CN,🎯 全球直连" },
        { type: "rule", value: "GEOIP,CN,🎯 全球直连,no-resolve" },
        { type: "provider", name: "MoeChina", group: "🎯 全球直连" },
        { type: "provider", name: "MoeChinaIP", group: "🎯 全球直连" },
        { type: "provider", name: "ChinaIP", group: "🎯 全球直连" },

        //兜底
        { type: "rule", value: "MATCH,🚀 节点选择" },

    ];


    // 新的 rules 数组
    config.rules = [];

    for (const item of providerToProxyGroup) {

        // ✅ 1) inline rule：原样 push，不 fetch 不解析
        if (item.type === "rule") {
            config.rules.push(item.value);
            continue;
        }

        // ✅ 2) provider：fetch + 解析 + 自动补代理组
        if (item.type === "provider") {

            const name = item.name;
            const provider = config["rule-providers"][name];
            if (!provider || !provider.url) continue;

            // 每个请求之间延迟
            await jitterDelay(200, 500);

            try {
                const text = await fetchWithRetry(provider.url, 3);

                const lines = text
                    .split("\n")
                    .map(l => l.trim())
                    .filter(l => l && !l.startsWith("#"));

                const proxyGroup = item.group || "🚀 节点选择";

                for (const rule of lines) {
                    if (rule.startsWith("USER-AGENT") || rule.startsWith("URL-REGEX")) continue;
                    if (rule.includes("7h1s_rul35et_i5_mad3_by_5ukk4w-ruleset.skk.moe")) continue;

                    if (rule.includes(",")) {
                        const parts = rule.split(",");
                        const lastPart = parts[parts.length - 1];

                        if (lastPart === proxyGroup) {
                            config.rules.push(rule);
                        } else if (rule.endsWith(",no-resolve")) {
                            const withoutNoResolve = rule.slice(0, -",no-resolve".length);
                            config.rules.push(`${withoutNoResolve},${proxyGroup},no-resolve`);
                        } else {
                            config.rules.push(`${rule},${proxyGroup}`);
                        }
                    } else {
                        config.rules.push(`${rule},${proxyGroup}`);
                    }
                }
            } catch (e) {
                console.log(`获取规则失败(已重试): ${name}`, e);
            }

            continue;
        }
    }



    config["geodata-mode"] = true;
    config["geox-url"] = {
        geoip: "https://cdn.jsdmirror.com/gh/Loyalsoldier/v2ray-rules-dat@release/geoip.dat",
        geosite: "https://cdn.jsdmirror.com/gh/Loyalsoldier/v2ray-rules-dat@release/geosite.dat",
        mmdb: "https://cdn.jsdmirror.com/gh/Loyalsoldier/geoip@release/Country.mmdb",
        asn: "https://cdn.jsdmirror.com/gh/Loyalsoldier/geoip@release/GeoLite2-ASN.mmdb",
    };

    return config;
}
