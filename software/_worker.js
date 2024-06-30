import { connect } from 'cloudflare:sockets';
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                       寿与天齐天书版，永不怕封，基本上只要第一行CF不取消，就是永久                                                           //
//////////////////////////////////////////////////////////////////            注意事项              /////////////////////////////////////////////////////////////////////////
//1、本脚本是只支持clash，openclash和移动端clash meta没有问题，其他clash类软件自行测试，非clash不用想了，不能用。                                                                //
//2、去除了所有反代功能，使用CF策略直连，依赖反代有GPT等特殊需求的也不用想了，不能用。                                                                                           //
////////////////////////////////////////////////////////////////////////////下面说说优势/////////////////////////////////////////////////////////////////////////////////////
//1、完全的天书版，防止1101那天的来临，不用在意那些变量名，看后面的备注改就行，本脚本不支持任何的外部变量，一切都在脚本内部改,高手也可以适当的改一些变量名，达到私有变种workers。        //
//2、支持直接workers部署，notls裸奔。                                                                                                                                       //
//3、去除UUID规格限制，可以任意根据说明组合上百位的字符，防止被扫。                                                                                                            //
//4、附带私钥功能，防止被薅请求数，就算暴露了域名也不怕被爆请求数了。【大家还可以通过禁用workers--设置--触发器的workers.dev默认域名路由功能，降低被自动扫出的概率，提升安全性】        //
//5、完完全全的删掉了反代以及一堆多余的功能，纯手搓配置文件【在底部，有详细备注策略说明】，去除了任何的外连API，玩家甚至可以在保存配置文件后删掉订阅功能59-67行，就算完全被扫出ID也没用。//
//6、改进了连接效率，workers工作效率高，极低CPU中值挂钟时间及错误率，增加性能。                                                                                                //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

let 吂吅吆吇吋吒吔吖 = ["99280094-e683-476b-a3cd-0d37c3892c6f"]; //这是你的ID，去除UUID规格限制，支持大小写字母和数字任意组合，安全性提高更不容易扫出
let 咑咓咔咕咖咗 = ["Google"]; //这是你的私钥，提高隐秘性安全性，就算别人扫到你的域名也无法链接，再也不怕别人薅请求数了^_^【当节点使用的时候还是可能连接的，但属于CF自动代理，并不消耗你的请求数】
const 嗋嗌嗍 = 'vl'
const 嗋嗌嗍2 = 'ess'
const 嘼啴嘾 = '://'
const 嗼嗽嗾嗿 = 'cla'
const 嘃嘄嘅 = 'sh'
const 尝嚑嚒嚓 = '/?ed=2560' //一般不用改 '/?ed=2560' 使用这个代码并开启域名--速度--优化--协议优化--0-RTT连接恢复，可以改善使用体验，猜的^_^

const 堼堽堾堼 = 'visa.cn' //CF的节点，填域名或IP，由于CFcdn大多都是通用端口开放，所以好用的域名一个就够，会生成4个notls节点和4个tls的。
const 塴尘塶塷塸堑塺 = 'visa.cn' //CF的节点，IPV6的，改了双栈优先IPV6，填域名或IP

const 垛垜垝垞垟垠 = 'visa.cn' //非CF的节点，填域名或IP，可以挂自建的VPS节点啥的，走策略访问特殊需求网站
const 垨垩垪垫垬垭 = '443' //非CF的节点端口
const 垩堋堌堍 = 'true' //非CF的节点TLS开关，true，false

const 姃姄姅姆姇 = 'ts.skvless.us.kg' //备用节点，可以填自己的workers绑定的域名，CF自动小黄云代理，相当于有一个永久有效的备份节点，永不失联[这方法只针对托管域名到CF的玩家]
const 姷姸姹 = '2096' //端口
const 嫐嫑嫒嫓嫔 = 'true' //TLS开关，true，false

const 実宥宧宨宩 = 'visa.cn' //IPV6备用节点，改了双栈优先IPV6，意思同上，都是自定义的，想填备份的也行，想填别人的或自己的vps也行
const 宺宻宼寀寁 = '443' //端口
const 寏寔寕寖寗 = 'true' //TLS开关，true，false

const 嵈嵉嵊嵋嵌嵍 = '🌧️' //自己的节点名字【统一名字】

export default {
    async fetch(帡帢帣, 巌巍巎) {
        try {
            吂吅吆吇吋吒吔吖 = 巌巍巎.UID || 吂吅吆吇吋吒吔吖;
            const 帑帒帓帔 = 帡帢帣.headers.get('Upgrade');
            if (!帑帒帓帔 || 帑帒帓帔 !== 'websocket') {
                const url = new URL(帡帢帣.url);
                switch (url.pathname) {
                    case `/${吂吅吆吇吋吒吔吖}`:
                        {
                            const 核栺栻栽栾 = 斚斛斝斞斟(吂吅吆吇吋吒吔吖, 帡帢帣.headers.get('Host'));
                            return new Response(`${核栺栻栽栾}`, {
                                status: 200,
                                headers: {
                                    "Content-Type": "text/plain;charset=utf-8",
                                }
                            });
                        }
                    case `/${吂吅吆吇吋吒吔吖}/${嗼嗽嗾嗿}${嘃嘄嘅}`:
                        {
                            const 嗼嗽嗾嗿嘃嘄嘅核栺栻栽栾 = 晵晷晸晹晻晼晽晾晿(吂吅吆吇吋吒吔吖, 帡帢帣.headers.get('Host'));
                            return new Response(`${嗼嗽嗾嗿嘃嘄嘅核栺栻栽栾}`, {
                                status: 200,
                                headers: {
                                    "Content-Type": "text/plain;charset=utf-8",
                                }
                            });
                        }
                    default:
                        url.hostname = 'fuliba123.net'; //在这里添加伪装域名网站，建议自建的站点，或者国外小站;
                        url.protocol = 'https:';
                        帡帢帣 = new Request(url, 帡帢帣);
                        return await fetch(帡帢帣);
                }
            } else {
                const 幢幤幥幦幧幨 = 帡帢帣.headers.get('my-key')
                if (幢幤幥幦幧幨 == 咑咓咔咕咖咗) {
                    return await 峪峬峫(帡帢帣);
                }
            }
        } catch (err) {
            return new Response(err.toString());
        }
    },
};
async function 峪峬峫(request) {
    const 姶姷姸姹姺姻 = new WebSocketPair();
    const[幏幐幑幒, 宺宻宼寀寁寃] = Object.values(姶姷姸姹姺姻);
    宺宻宼寀寁寃.accept();
    let 崽崾崿嵀 = '';
    let 坱坲坳坴 = '';
    const 娱娜娝娞娟娠娡 = ( /** @type {string} */ 妢妤妦妧妩, /** @type {string | undefined} */ event) => {
        console.log(`[${崽崾崿嵀}:${坱坲坳坴}] ${妢妤妦妧妩}`, event || '');
    };
    const 尪尫尬尭尮 = request.headers.get('sec-websocket-protocol') || '';
    const 峲峳岘峵峷峸峹 = 庨庩庪库庬庮(宺宻宼寀寁寃, 尪尫尬尭尮);
    let 尲尳尴尵 = {
        value: null,
    };
    峲峳岘峵峷峸峹.pipeTo(new WritableStream({
        async write(帵帷帹帺帻) {
            if (尲尳尴尵.value) {
                const writer = 尲尳尴尵.value.writable.getWriter()
                await writer.write(帵帷帹帺帻);
                writer.releaseLock();
                return;
            }
            const {
                崽崾崿嵀 = '',
                嶦峄峃嶩 = '',
                幁幂帏幄幅,
                幮幯幰 = new Uint8Array([弻弼弽弿(), 弻弼弽弿2()]), //随机加密VL版本号，这属于从workers--到访问外网出口的VL版本号，原作者认为从CF出口应该没必要加密版本号，所以都采用了固定模式0,0或0,1，这样CF未来很容易通过VL版本号探测流量封禁，猜的^_^
            } = await 晛晜晞晟晠晡晰(帵帷帹帺帻);
            const 慊态慏慐 = new Uint8Array([幮幯幰[2], Math.floor(幮幯幰[1] / 2)]);
            const 応忝忞忟忡 = 帵帷帹帺帻.slice(幁幂帏幄幅);
            恺恻恽恾恿(尲尳尴尵, 崽崾崿嵀, 嶦峄峃嶩, 応忝忞忟忡, 宺宻宼寀寁寃, 慊态慏慐, 娱娜娝娞娟娠娡);
        },
    }));
    return new Response(null, {
        status: 101,
        webSocket: 幏幐幑幒,
    });
}

function 弻弼弽弿() {
    return Math.floor(Math.random() * 249) + 2;
}

function 弻弼弽弿2() {
    return Math.floor(Math.random() * 149) + 2;
}
async function 恺恻恽恾恿(尲尳尴尵, 崽崾崿嵀, 嶦峄峃嶩, 応忝忞忟忡, 宺宻宼寀寁寃, 懹忏懻惧懽, 戨戬截戫, ) {
    async function 抳抵抶抷(憡憢憣, 坱坲坳坴) {
        const 忸忹忺忻忼 = connect({
            hostname: 憡憢憣,
            port: 坱坲坳坴,
        });
        尲尳尴尵.value = 忸忹忺忻忼;
        const writer = 忸忹忺忻忼.writable.getWriter();
        await writer.write(応忝忞忟忡);
        writer.releaseLock();
        return 忸忹忺忻忼;
    }
    const 忸忹忺忻忼 = await 抳抵抶抷(崽崾崿嵀, 嶦峄峃嶩);
    愎愐愑愒愓愕愖愗(忸忹忺忻忼, 宺宻宼寀寁寃, 懹忏懻惧懽, 戨戬截戫);
}

function 庨庩庪库庬庮(慖慗惨慙惭慛, 慷慸慹慺慻慽) {
    const stream = new ReadableStream({
        start(controller) {
            慖慗惨慙惭慛.addEventListener('message', (event) => {
                const message = event.data;
                controller.enqueue(message);
            });
            const {
                earlyData
            } = 憟憠憡憢憣愤憥憦(慷慸慹慺慻慽);
            if (earlyData) {
                controller.enqueue(earlyData);
            }
        }
    });
    return stream;
}
async function 晛晜晞晟晠晡晰(
捚捛捜捝捞损, ) {
    //const version = new Uint8Array(捚捛捜捝捞损.slice(弻弼弽弿(), 弻弼弽弿2())); //随机加密版本数组，会适当降低连通效率，针对客户端--workers之间的数据沟通，若出现被抓特征墙，可以尝试使用，当然，这是猜的^_^
    //const version = new Uint8Array(捚捛捜捝捞损.slice(0, 1)); //不加密版本数组，连通性好
    const version = new Uint8Array(捚捛捜捝捞损.slice(0, 1)); //上面两行代码就是这行代码的变种，如果想改就择一复制替换这行代码内容吧
    const optLength = new Uint8Array(捚捛捜捝捞损.slice(17, 18))[0];
    const portIndex = 18 + optLength + 1;
    const portBuffer = 捚捛捜捝捞损.slice(portIndex, portIndex + 2);
    const 嶦峄峃嶩 = new DataView(portBuffer).getUint16(0);
    let addressIndex = portIndex + 2;
    const addressBuffer = new Uint8Array(
    捚捛捜捝捞损.slice(addressIndex, addressIndex + 1));
    const 戙戛戜戝戞戟戠 = addressBuffer[0];
    let addressLength = 0;
    let addressValueIndex = addressIndex + 1;
    let addressValue = '';
    switch (戙戛戜戝戞戟戠) {
        case 1:
            addressLength = 4;
            addressValue = new Uint8Array(
            捚捛捜捝捞损.slice(addressValueIndex, addressValueIndex + addressLength)).join('.');
            break;
        case 2:
            addressLength = new Uint8Array(
            捚捛捜捝捞损.slice(addressValueIndex, addressValueIndex + 1))[0];
            addressValueIndex += 1;
            addressValue = new TextDecoder().decode(
            捚捛捜捝捞损.slice(addressValueIndex, addressValueIndex + addressLength));
            break;
        case 3:
            addressLength = 16;
            const dataView = new DataView(
            捚捛捜捝捞损.slice(addressValueIndex, addressValueIndex + addressLength));
            const ipv6 = [];
            for (let i = 0; i < 8; i++) {
                ipv6.push(dataView.getUint16(i * 2).toString(16));
            }
            addressValue = ipv6.join(':');
            break;
    }
    return {
        崽崾崿嵀: addressValue,
        戙戛戜戝戞戟戠,
        嶦峄峃嶩,
        幁幂帏幄幅: addressValueIndex + addressLength,
        幮幯幰: version,
    };
}
async function 愎愐愑愒愓愕愖愗(挻挼挽挿, 宺宻宼寀寁寃, 捆捇捈, 揑揓揔揕揖揗揘) {
    let 摦摧摨摪 = 捆捇捈;
    let 拣拤拧择拪拫 = false;
    await 挻挼挽挿.readable.pipeTo(
    new WritableStream({
        start() {},
        /**
         * @param {Uint8Array} 搹搻搼搽榨搿
         */
        async write(搹搻搼搽榨搿) {
            拣拤拧择拪拫 = true;
            if (摦摧摨摪) {
                宺宻宼寀寁寃.send(await new Blob([摦摧摨摪, 搹搻搼搽榨搿]).arrayBuffer());
                摦摧摨摪 = null;
            } else {
                宺宻宼寀寁寃.send(搹搻搼搽榨搿);
            }
        },
    }));
    if (拣拤拧择拪拫 === false && 揑揓揔揕揖揗揘) {
        揑揓揔揕揖揗揘();
    }
}

function 憟憠憡憢憣愤憥憦(加_密你个_丁咚_咙咚_呛) {
    try {
        加_密你个_丁咚_咙咚_呛 = 加_密你个_丁咚_咙咚_呛.replace(/-/g, '+').replace(/_/g, '/');
        const 解密数据 = atob(加_密你个_丁咚_咙咚_呛);
        const 解密_你_个_丁咚_咙_咚呛 = Uint8Array.from(解密数据, (c) => c.charCodeAt(0));
        return {
            earlyData: 解密_你_个_丁咚_咙_咚呛.buffer,
            error: null
        };
    } catch (error) {
        return {
            error
        };
    }
}

function 斚斛斝斞斟(吂吅吆吇吋吒吔吖, hostName) {
    return `
本worker只支持${嗼嗽嗾嗿}${嘃嘄嘅}，其他需求自行研究
猫咪的：https${嘼啴嘾}${hostName}/${吂吅吆吇吋吒吔吖}/${嗼嗽嗾嗿}${嘃嘄嘅}
`;
}

function 晵晷晸晹晻晼晽晾晿(吂吅吆吇吋吒吔吖, hostName) {
    return `
dns:
  nameserver:
    - 119.29.29.29
    - 223.5.5.5
  fallback:
    - 8.8.8.8
    - tls://dns.google
    - 2001:4860:4860::8888
proxies:
- name: ${嵈嵉嵊嵋嵌嵍}-notls-2052
  type: ${嗋嗌嗍}${嗋嗌嗍2}
  server: ${堼堽堾堼}
  port: 2052
  uuid: ${吂吅吆吇吋吒吔吖}
  udp: false
  tls: false
  network: ws
  ws-opts:
    path: "${尝嚑嚒嚓}"
    headers:
      Host: ${hostName}
      my-key: ${咑咓咔咕咖咗}
- name: ${嵈嵉嵊嵋嵌嵍}-notls-2082
  type: ${嗋嗌嗍}${嗋嗌嗍2}
  server: ${堼堽堾堼}
  port: 2082
  uuid: ${吂吅吆吇吋吒吔吖}
  udp: false
  tls: false
  network: ws
  ws-opts:
    path: "${尝嚑嚒嚓}"
    headers:
      Host: ${hostName}
      my-key: ${咑咓咔咕咖咗}
- name: ${嵈嵉嵊嵋嵌嵍}-notls-2086
  type: ${嗋嗌嗍}${嗋嗌嗍2}
  server: ${堼堽堾堼}
  port: 2086
  uuid: ${吂吅吆吇吋吒吔吖}
  udp: false
  tls: false
  network: ws
  ws-opts:
    path: "${尝嚑嚒嚓}"
    headers:
      Host: ${hostName}
      my-key: ${咑咓咔咕咖咗}
- name: ${嵈嵉嵊嵋嵌嵍}-notls-2095
  type: ${嗋嗌嗍}${嗋嗌嗍2}
  server: ${堼堽堾堼}
  port: 2095
  uuid: ${吂吅吆吇吋吒吔吖}
  udp: false
  tls: false
  network: ws
  servername: ${hostName}
  ws-opts:
    path: "${尝嚑嚒嚓}"
    headers:
      Host: ${hostName}
      my-key: ${咑咓咔咕咖咗}
- name: ${嵈嵉嵊嵋嵌嵍}-tls-2053
  type: ${嗋嗌嗍}${嗋嗌嗍2}
  server: ${堼堽堾堼}
  port: 2053
  uuid: ${吂吅吆吇吋吒吔吖}
  udp: false
  tls: true
  network: ws
  servername: ${hostName}
  ws-opts:
    path: "${尝嚑嚒嚓}"
    headers:
      Host: ${hostName}
      my-key: ${咑咓咔咕咖咗}
- name: ${嵈嵉嵊嵋嵌嵍}-tls-2083
  type: ${嗋嗌嗍}${嗋嗌嗍2}
  server: ${堼堽堾堼}
  port: 2083
  uuid: ${吂吅吆吇吋吒吔吖}
  udp: false
  tls: true
  network: ws
  servername: ${hostName}
  ws-opts:
    path: "${尝嚑嚒嚓}"
    headers:
      Host: ${hostName}
      my-key: ${咑咓咔咕咖咗}
- name: ${嵈嵉嵊嵋嵌嵍}-tls-2087
  type: ${嗋嗌嗍}${嗋嗌嗍2}
  server: ${堼堽堾堼}
  port: 2087
  uuid: ${吂吅吆吇吋吒吔吖}
  udp: false
  tls: true
  network: ws
  servername: ${hostName}
  ws-opts:
    path: "${尝嚑嚒嚓}"
    headers:
      Host: ${hostName}
      my-key: ${咑咓咔咕咖咗}
- name: ${嵈嵉嵊嵋嵌嵍}-tls-2096
  type: ${嗋嗌嗍}${嗋嗌嗍2}
  server: ${堼堽堾堼}
  port: 2096
  uuid: ${吂吅吆吇吋吒吔吖}
  udp: false
  tls: true
  network: ws
  servername: ${hostName}
  ws-opts:
    path: "${尝嚑嚒嚓}"
    headers:
      Host: ${hostName}
      my-key: ${咑咓咔咕咖咗}
- name: ${嵈嵉嵊嵋嵌嵍}-ipv6-notls-2052
  type: ${嗋嗌嗍}${嗋嗌嗍2}
  server: ${塴尘塶塷塸堑塺}
  port: 2052
  ip-version: ipv6-prefer  # ip-version设置，可以自定义强制走ipv4或ipv6，ipv6-prefer则是双栈优先走ipv6
  uuid: ${吂吅吆吇吋吒吔吖}
  udp: false
  tls: false
  network: ws
  ws-opts:
    path: "${尝嚑嚒嚓}"
    headers:
      Host: ${hostName}
      my-key: ${咑咓咔咕咖咗}
- name: ${嵈嵉嵊嵋嵌嵍}-ipv6-notls-2082
  type: ${嗋嗌嗍}${嗋嗌嗍2}
  server: ${塴尘塶塷塸堑塺}
  port: 2082
  ip-version: ipv6-prefer  # ip-version设置，可以自定义强制走ipv4或ipv6，ipv6-prefer则是双栈优先走ipv6
  uuid: ${吂吅吆吇吋吒吔吖}
  udp: false
  tls: false
  network: ws
  ws-opts:
    path: "${尝嚑嚒嚓}"
    headers:
      Host: ${hostName}
      my-key: ${咑咓咔咕咖咗}
- name: ${嵈嵉嵊嵋嵌嵍}-ipv6-notls-2086
  type: ${嗋嗌嗍}${嗋嗌嗍2}
  server: ${塴尘塶塷塸堑塺}
  port: 2086
  ip-version: ipv6-prefer  # ip-version设置，可以自定义强制走ipv4或ipv6，ipv6-prefer则是双栈优先走ipv6
  uuid: ${吂吅吆吇吋吒吔吖}
  udp: false
  tls: false
  network: ws
  ws-opts:
    path: "${尝嚑嚒嚓}"
    headers:
      Host: ${hostName}
      my-key: ${咑咓咔咕咖咗}
- name: ${嵈嵉嵊嵋嵌嵍}-ipv6-notls-2095
  type: ${嗋嗌嗍}${嗋嗌嗍2}
  server: ${塴尘塶塷塸堑塺}
  port: 2095
  ip-version: ipv6-prefer  # ip-version设置，可以自定义强制走ipv4或ipv6，ipv6-prefer则是双栈优先走ipv6
  uuid: ${吂吅吆吇吋吒吔吖}
  udp: false
  tls: false
  network: ws
  servername: ${hostName}
  ws-opts:
    path: "${尝嚑嚒嚓}"
    headers:
      Host: ${hostName}
      my-key: ${咑咓咔咕咖咗}
- name: ${嵈嵉嵊嵋嵌嵍}-ipv6-tls-2053
  type: ${嗋嗌嗍}${嗋嗌嗍2}
  server: ${塴尘塶塷塸堑塺}
  port: 2053
  ip-version: ipv6-prefer  # ip-version设置，可以自定义强制走ipv4或ipv6，ipv6-prefer则是双栈优先走ipv6
  uuid: ${吂吅吆吇吋吒吔吖}
  udp: false
  tls: true
  network: ws
  servername: ${hostName}
  ws-opts:
    path: "${尝嚑嚒嚓}"
    headers:
      Host: ${hostName}
      my-key: ${咑咓咔咕咖咗}
- name: ${嵈嵉嵊嵋嵌嵍}-ipv6-tls-2083
  type: ${嗋嗌嗍}${嗋嗌嗍2}
  server: ${塴尘塶塷塸堑塺}
  port: 2083
  ip-version: ipv6-prefer  # ip-version设置，可以自定义强制走ipv4或ipv6，ipv6-prefer则是双栈优先走ipv6
  uuid: ${吂吅吆吇吋吒吔吖}
  udp: false
  tls: true
  network: ws
  servername: ${hostName}
  ws-opts:
    path: "${尝嚑嚒嚓}"
    headers:
      Host: ${hostName}
      my-key: ${咑咓咔咕咖咗}
- name: ${嵈嵉嵊嵋嵌嵍}-ipv6-tls-2087
  type: ${嗋嗌嗍}${嗋嗌嗍2}
  server: ${塴尘塶塷塸堑塺}
  port: 2087
  ip-version: ipv6-prefer  # ip-version设置，可以自定义强制走ipv4或ipv6，ipv6-prefer则是双栈优先走ipv6
  uuid: ${吂吅吆吇吋吒吔吖}
  udp: false
  tls: true
  network: ws
  servername: ${hostName}
  ws-opts:
    path: "${尝嚑嚒嚓}"
    headers:
      Host: ${hostName}
      my-key: ${咑咓咔咕咖咗}
- name: ${嵈嵉嵊嵋嵌嵍}-ipv6-tls-2096
  type: ${嗋嗌嗍}${嗋嗌嗍2}
  server: ${塴尘塶塷塸堑塺}
  port: 2096
  ip-version: ipv6-prefer  # ip-version设置，可以自定义强制走ipv4或ipv6，ipv6-prefer则是双栈优先走ipv6
  uuid: ${吂吅吆吇吋吒吔吖}
  udp: false
  tls: true
  network: ws
  servername: ${hostName}
  ws-opts:
    path: "${尝嚑嚒嚓}"
    headers:
      Host: ${hostName}
      my-key: ${咑咓咔咕咖咗}
- name: ${嵈嵉嵊嵋嵌嵍}-非CF节点
  type: ${嗋嗌嗍}${嗋嗌嗍2}
  server: ${垛垜垝垞垟垠}
  port: ${垨垩垪垫垬垭}
  uuid: ${吂吅吆吇吋吒吔吖}
  udp: false
  tls: ${垩堋堌堍}
  network: ws
  servername: ${hostName}
  ws-opts:
    path: "${尝嚑嚒嚓}"
    headers:
      Host: ${hostName}
      my-key: ${咑咓咔咕咖咗}
- name: ${嵈嵉嵊嵋嵌嵍}-备用IPV4节点
  type: ${嗋嗌嗍}${嗋嗌嗍2}
  server: ${姃姄姅姆姇}
  port: ${姷姸姹}
  uuid: ${吂吅吆吇吋吒吔吖}
  udp: false
  tls: ${嫐嫑嫒嫓嫔}
  network: ws
  servername: ${hostName}
  ws-opts:
    path: "${尝嚑嚒嚓}"
    headers:
      Host: ${hostName}
      my-key: ${咑咓咔咕咖咗}
- name: ${嵈嵉嵊嵋嵌嵍}-备用IPV6节点
  type: ${嗋嗌嗍}${嗋嗌嗍2}
  server: ${実宥宧宨宩}
  port: ${宺宻宼寀寁}
  ip-version: ipv6-prefer  # ip-version设置，可以自定义强制走ipv4或ipv6，ipv6-prefer则是双栈优先走ipv6
  uuid: ${吂吅吆吇吋吒吔吖}
  udp: false
  tls: ${寏寔寕寖寗}
  network: ws
  servername: ${hostName}
  ws-opts:
    path: "${尝嚑嚒嚓}"
    headers:
      Host: ${hostName}
      my-key: ${咑咓咔咕咖咗}
proxy-groups:
- name: 🚀 节点选择
  type: select
  proxies:
    - notls负载均衡
    - tls负载均衡
    - ipv6-notls负载均衡
    - ipv6-tls负载均衡
    - 自动选择
    - ${嵈嵉嵊嵋嵌嵍}-notls-2052
    - ${嵈嵉嵊嵋嵌嵍}-notls-2082
    - ${嵈嵉嵊嵋嵌嵍}-notls-2086
    - ${嵈嵉嵊嵋嵌嵍}-notls-2095
    - ${嵈嵉嵊嵋嵌嵍}-tls-2053
    - ${嵈嵉嵊嵋嵌嵍}-tls-2083
    - ${嵈嵉嵊嵋嵌嵍}-tls-2087
    - ${嵈嵉嵊嵋嵌嵍}-tls-2096
    - ${嵈嵉嵊嵋嵌嵍}-ipv6-notls-2052
    - ${嵈嵉嵊嵋嵌嵍}-ipv6-notls-2082
    - ${嵈嵉嵊嵋嵌嵍}-ipv6-notls-2086
    - ${嵈嵉嵊嵋嵌嵍}-ipv6-notls-2095
    - ${嵈嵉嵊嵋嵌嵍}-ipv6-tls-2053
    - ${嵈嵉嵊嵋嵌嵍}-ipv6-tls-2083
    - ${嵈嵉嵊嵋嵌嵍}-ipv6-tls-2087
    - ${嵈嵉嵊嵋嵌嵍}-ipv6-tls-2096
    - ${嵈嵉嵊嵋嵌嵍}-非CF节点
    - ${嵈嵉嵊嵋嵌嵍}-备用IPV4节点
    - ${嵈嵉嵊嵋嵌嵍}-备用IPV6节点
- name: 自动选择
  type: url-test
  url: http://www.gstatic.com/generate_204
  interval: 300
  tolerance: 50
  proxies:
    - ${嵈嵉嵊嵋嵌嵍}-notls-2052
    - ${嵈嵉嵊嵋嵌嵍}-notls-2082
    - ${嵈嵉嵊嵋嵌嵍}-notls-2086
    - ${嵈嵉嵊嵋嵌嵍}-notls-2095
    - ${嵈嵉嵊嵋嵌嵍}-tls-2053
    - ${嵈嵉嵊嵋嵌嵍}-tls-2083
    - ${嵈嵉嵊嵋嵌嵍}-tls-2087
    - ${嵈嵉嵊嵋嵌嵍}-tls-2096
    - ${嵈嵉嵊嵋嵌嵍}-ipv6-notls-2052
    - ${嵈嵉嵊嵋嵌嵍}-ipv6-notls-2082
    - ${嵈嵉嵊嵋嵌嵍}-ipv6-notls-2086
    - ${嵈嵉嵊嵋嵌嵍}-ipv6-notls-2095
    - ${嵈嵉嵊嵋嵌嵍}-ipv6-tls-2053
    - ${嵈嵉嵊嵋嵌嵍}-ipv6-tls-2083
    - ${嵈嵉嵊嵋嵌嵍}-ipv6-tls-2087
    - ${嵈嵉嵊嵋嵌嵍}-ipv6-tls-2096
    - ${嵈嵉嵊嵋嵌嵍}-非CF节点
    - ${嵈嵉嵊嵋嵌嵍}-备用IPV4节点
    - ${嵈嵉嵊嵋嵌嵍}-备用IPV6节点
- name: notls负载均衡
  type: load-balance
  url: http://www.gstatic.com/generate_204
  interval: 300
  proxies:
    - ${嵈嵉嵊嵋嵌嵍}-notls-2052
    - ${嵈嵉嵊嵋嵌嵍}-notls-2082
    - ${嵈嵉嵊嵋嵌嵍}-notls-2086
    - ${嵈嵉嵊嵋嵌嵍}-notls-2095
- name: tls负载均衡
  type: load-balance
  url: http://www.gstatic.com/generate_204
  interval: 300
  proxies:
    - ${嵈嵉嵊嵋嵌嵍}-tls-2053
    - ${嵈嵉嵊嵋嵌嵍}-tls-2083
    - ${嵈嵉嵊嵋嵌嵍}-tls-2087
    - ${嵈嵉嵊嵋嵌嵍}-tls-2096
- name: ipv6-notls负载均衡
  type: load-balance
  url: http://www.gstatic.com/generate_204
  interval: 300
  proxies:
    - ${嵈嵉嵊嵋嵌嵍}-ipv6-notls-2052
    - ${嵈嵉嵊嵋嵌嵍}-ipv6-notls-2082
    - ${嵈嵉嵊嵋嵌嵍}-ipv6-notls-2086
    - ${嵈嵉嵊嵋嵌嵍}-ipv6-notls-2095
- name: ipv6-tls负载均衡
  type: load-balance
  url: http://www.gstatic.com/generate_204
  interval: 300
  proxies:
    - ${嵈嵉嵊嵋嵌嵍}-ipv6-tls-2053
    - ${嵈嵉嵊嵋嵌嵍}-ipv6-tls-2083
    - ${嵈嵉嵊嵋嵌嵍}-ipv6-tls-2087
    - ${嵈嵉嵊嵋嵌嵍}-ipv6-tls-2096
- name: 非CF节点
  type: select
  proxies:
    - ${嵈嵉嵊嵋嵌嵍}-非CF节点
- name: 漏网之鱼
  type: select
  proxies:
    - 🚀 节点选择
    - 非CF节点
    - DIRECT
rules:
# 策略规则，部分规则需打开clash mate的使用geoip dat版数据库，比如TG规则就需要，或者自定义geoip的规则订阅
# 这是geoip的规则订阅链接，https://cdn.jsdelivr.net/gh/Loyalsoldier/geoip@release/Country.mmdb
- GEOSITE,category-ads,REJECT #简单广告过滤规则，要增加规则数可使用category-ads-all
- GEOSITE,cn,DIRECT #国内域名直连规则
- GEOIP,CN,DIRECT,no-resolve #国内IP直连规则
- GEOSITE,cloudflare,DIRECT #CF域名直连规则
- GEOIP,CLOUDFLARE,DIRECT,no-resolve #CFIP直连规则
- GEOSITE,gfw,🚀 节点选择 #GFW域名规则
- GEOSITE,google,🚀 节点选择 #GOOGLE域名规则
- GEOIP,GOOGLE,🚀 节点选择,no-resolve #GOOGLE IP规则
- GEOSITE,netflix,🚀 节点选择 #奈飞域名规则
- GEOIP,NETFLIX,🚀 节点选择,no-resolve #奈飞IP规则
- GEOSITE,telegram,🚀 节点选择 #TG域名规则
- GEOIP,TELEGRAM,🚀 节点选择,no-resolve #TG IP规则
- MATCH,漏网之鱼
`
}