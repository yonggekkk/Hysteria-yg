#!/bin/bash
export PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export LANG=en_US.UTF-8
wpygV="23.3.17 V 0.9.6 "
remoteV=`wget -qO- https://gitlab.com/rwkgyg/CFwarp/raw/main/CFwarp.sh | sed -n 4p | cut -d '"' -f 2`
chmod +x /root/CFwarp.sh
red='\033[0;31m'
bblue='\033[0;34m'
yellow='\033[0;33m'
green='\033[0;32m'
plain='\033[0m'
red(){ echo -e "\033[31m\033[01m$1\033[0m";}
green(){ echo -e "\033[32m\033[01m$1\033[0m";}
yellow(){ echo -e "\033[33m\033[01m$1\033[0m";}
blue(){ echo -e "\033[36m\033[01m$1\033[0m";}
white(){ echo -e "\033[37m\033[01m$1\033[0m";}
bblue(){ echo -e "\033[34m\033[01m$1\033[0m";}
rred(){ echo -e "\033[35m\033[01m$1\033[0m";}
readtp(){ read -t5 -n26 -p "$(yellow "$1")" $2;}
readp(){ read -p "$(yellow "$1")" $2;}
[[ $EUID -ne 0 ]] && yellow "请以root模式运行脚本" && exit
#[[ -e /etc/hosts ]] && grep -qE '^ *172.65.251.78 gitlab.com' /etc/hosts || echo -e '\n172.65.251.78 gitlab.com' >> /etc/hosts
yellow " 请稍等……正在扫描vps类型及参数中……"
if [[ -f /etc/redhat-release ]]; then
release="Centos"
elif cat /etc/issue | grep -q -E -i "debian"; then
release="Debian"
elif cat /etc/issue | grep -q -E -i "ubuntu"; then
release="Ubuntu"
elif cat /etc/issue | grep -q -E -i "centos|red hat|redhat"; then
release="Centos"
elif cat /proc/version | grep -q -E -i "debian"; then
release="Debian"
elif cat /proc/version | grep -q -E -i "ubuntu"; then
release="Ubuntu"
elif cat /proc/version | grep -q -E -i "centos|red hat|redhat"; then
release="Centos"
else 
red "不支持你当前系统，请选择使用Ubuntu,Debian,Centos系统。" && rm -f CFwarp.sh && exit
fi
vsid=`grep -i version_id /etc/os-release | cut -d \" -f2 | cut -d . -f1`
sys(){
[ -f /etc/os-release ] && grep -i pretty_name /etc/os-release | cut -d \" -f2 && return
[ -f /etc/lsb-release ] && grep -i description /etc/lsb-release | cut -d \" -f2 && return
[ -f /etc/redhat-release ] && awk '{print $0}' /etc/redhat-release && return;}
op=`sys`
version=`uname -r | awk -F "-" '{print $1}'`
main=`uname  -r | awk -F . '{print $1}'`
minor=`uname -r | awk -F . '{print $2}'`
vi=`systemd-detect-virt`
cpujg(){
bit=`uname -m`
if [[ $bit = aarch64 ]]; then
cpu=arm64
elif [[ $bit = x86_64 ]]; then
cpu=amd64
else
red "目前脚本不支持$bit架构" && exit
fi
}

if [[ $vi = openvz ]]; then
TUN=$(cat /dev/net/tun 2>&1)
if [[ ! $TUN =~ 'in bad state' ]] && [[ ! $TUN =~ '处于错误状态' ]] && [[ ! $TUN =~ 'Die Dateizugriffsnummer ist in schlechter Verfassung' ]]; then 
red "检测到未开启TUN，现尝试添加TUN支持" && sleep 4
cd /dev
mkdir net
mknod net/tun c 10 200
chmod 0666 net/tun
TUN=$(cat /dev/net/tun 2>&1)
if [[ ! $TUN =~ 'in bad state' ]] && [[ ! $TUN =~ '处于错误状态' ]] && [[ ! $TUN =~ 'Die Dateizugriffsnummer ist in schlechter Verfassung' ]]; then 
green "添加TUN支持失败，建议与VPS厂商沟通或后台设置开启" && exit
else
cat <<EOF > /root/tun.sh
#!/bin/bash
cd /dev
mkdir net
mknod net/tun c 10 200
chmod 0666 net/tun
EOF
chmod +x /root/tun.sh
grep -qE "^ *@reboot root bash /root/tun.sh >/dev/null 2>&1" /etc/crontab || echo "@reboot root bash /root/tun.sh >/dev/null 2>&1" >> /etc/crontab
green "TUN守护功能已启动"
fi
fi
fi

#if [[ ! -f /root/nf || ! -s /root/nf ]]; then
#cpujg
#wget -O nf https://gitlab.com/rwkgyg/CFwarp/-/raw/main/nf_linux_${cpu}
#wget -O nf https://raw.githubusercontent.com/rkygogo/netflix-verify/main/nf_linux_$cpu
#chmod +x nf
#fi

[[ $(type -P yum) ]] && yumapt='yum -y' || yumapt='apt -y'
[[ $(type -P curl) ]] || (yellow "检测到curl未安装，升级安装中" && $yumapt update;$yumapt install curl)
[[ $(type -P bc) ]] || ($yumapt update;$yumapt install bc)
[[ ! $(type -P qrencode) ]] && ($yumapt update;$yumapt install qrencode)
[[ ! $(type -P python3) ]] && (yellow "检测到python3未安装，升级安装中" && $yumapt update;$yumapt install python3)

nf4() {
result=`curl --connect-timeout 5 -4sSL "https://www.netflix.com/" 2>&1`
[ "$result" == "Not Available" ] && NF="死心吧，Netflix不服务当前IP地区" && return
[[ "$result" == "curl"* ]] && NF="错误，无法连接到Netflix官网" && return
result=`curl -4sL "https://www.netflix.com/title/80018499" 2>&1`
[[ "$result" == *"page-404"* || "$result" == *"NSEZ-403"* ]] && NF="杯具，当前IP不能看Netflix" && return
result1=`curl -4sL "https://www.netflix.com/title/70143836" 2>&1`
result2=`curl -4sL "https://www.netflix.com/title/80027042" 2>&1`
result3=`curl -4sL "https://www.netflix.com/title/70140425" 2>&1`
result4=`curl -4sL "https://www.netflix.com/title/70283261" 2>&1`
result5=`curl -4sL "https://www.netflix.com/title/70143860" 2>&1`
result6=`curl -4sL "https://www.netflix.com/title/70202589" 2>&1`
[[ "$result1" == *"page-404"* && "$result2" == *"page-404"* && "$result3" == *"page-404"* && "$result4" == *"page-404"* && "$result5" == *"page-404"* && "$result6" == *"page-404"* ]] && NF="遗憾，当前IP仅可观看Netflix自制剧" && return
NF="恭喜，当前IP支持观看Netflix非自制剧" && return
}

nf6() {
result=`curl --connect-timeout 5 -6sSL "https://www.netflix.com/" 2>&1`
[ "$result" == "Not Available" ] && NF="死心吧，Netflix不服务当前IP地区" && return
[[ "$result" == "curl"* ]] && NF="错误，无法连接到Netflix官网" && return
result=`curl -6sL "https://www.netflix.com/title/80018499" 2>&1`
[[ "$result" == *"page-404"* || "$result" == *"NSEZ-403"* ]] && NF="杯具，当前IP不能看Netflix" && return
result1=`curl -6sL "https://www.netflix.com/title/70143836" 2>&1`
result2=`curl -6sL "https://www.netflix.com/title/80027042" 2>&1`
result3=`curl -6sL "https://www.netflix.com/title/70140425" 2>&1`
result4=`curl -6sL "https://www.netflix.com/title/70283261" 2>&1`
result5=`curl -6sL "https://www.netflix.com/title/70143860" 2>&1`
result6=`curl -6sL "https://www.netflix.com/title/70202589" 2>&1`
[[ "$result1" == *"page-404"* && "$result2" == *"page-404"* && "$result3" == *"page-404"* && "$result4" == *"page-404"* && "$result5" == *"page-404"* && "$result6" == *"page-404"* ]] && NF="遗憾，当前IP仅可观看Netflix自制剧" && return
NF="恭喜，当前IP支持观看Netflix非自制剧" && return
}

nfs5() {
result=`curl -sx socks5h://localhost:$mport --connect-timeout 5 -4sSL "https://www.netflix.com/" 2>&1`
[ "$result" == "Not Available" ] && NF="死心吧，Netflix不服务当前IP地区" && return
[[ "$result" == "curl"* ]] && NF="错误，无法连接到Netflix官网" && return
result=`curl -sx socks5h://localhost:$mport -4sL "https://www.netflix.com/title/80018499" 2>&1`
[[ "$result" == *"page-404"* || "$result" == *"NSEZ-403"* ]] && NF="杯具，当前IP不能看Netflix" && return
result1=`curl -sx socks5h://localhost:$mport -4sL "https://www.netflix.com/title/70143836" 2>&1`
result2=`curl -sx socks5h://localhost:$mport -4sL "https://www.netflix.com/title/80027042" 2>&1`
result3=`curl -sx socks5h://localhost:$mport -4sL "https://www.netflix.com/title/70140425" 2>&1`
result4=`curl -sx socks5h://localhost:$mport -4sL "https://www.netflix.com/title/70283261" 2>&1`
result5=`curl -sx socks5h://localhost:$mport -4sL "https://www.netflix.com/title/70143860" 2>&1`
result6=`curl -sx socks5h://localhost:$mport -4sL "https://www.netflix.com/title/70202589" 2>&1`
[[ "$result1" == *"page-404"* && "$result2" == *"page-404"* && "$result3" == *"page-404"* && "$result4" == *"page-404"* && "$result5" == *"page-404"* && "$result6" == *"page-404"* ]] && NF="遗憾，当前IP仅可观看Netflix自制剧" && return
NF="恭喜，当前IP支持观看Netflix非自制剧" && return
}

v4v6(){
v4=$(curl -s4m6 ip.sb -k)
v6=$(curl -s6m6 ip.sb -k)
#v6=$(curl -s6m6 api64.ipify.org -k)
#v4=$(curl -s4m6 api64.ipify.org -k)
}

checkwgcf(){
wgcfv6=$(curl -s6m6 https://www.cloudflare.com/cdn-cgi/trace -k | grep warp | cut -d= -f2) 
wgcfv4=$(curl -s4m6 https://www.cloudflare.com/cdn-cgi/trace -k | grep warp | cut -d= -f2) 
}

checkpt(){
mkdir -p /root/warpip
cpujg
v4v6
if [[ -z $v4 ]]; then
n=0
	iplist=100
	while true
	do
		temp[$n]=$(echo [2606:4700:d0::$(printf '%x\n' $(($RANDOM*2+$RANDOM%2))):$(printf '%x\n' $(($RANDOM*2+$RANDOM%2))):$(printf '%x\n' $(($RANDOM*2+$RANDOM%2))):$(printf '%x\n' $(($RANDOM*2+$RANDOM%2)))])
		n=$[$n+1]
		if [ $n -ge $iplist ]
		then
			break
		fi
		temp[$n]=$(echo [2606:4700:d1::$(printf '%x\n' $(($RANDOM*2+$RANDOM%2))):$(printf '%x\n' $(($RANDOM*2+$RANDOM%2))):$(printf '%x\n' $(($RANDOM*2+$RANDOM%2))):$(printf '%x\n' $(($RANDOM*2+$RANDOM%2)))])
		n=$[$n+1]
		if [ $n -ge $iplist ]
		then
			break
		fi
	done
	while true
	do
		if [ $(echo ${temp[@]} | sed -e 's/ /\n/g' | sort -u | wc -l) -ge $iplist ]
		then
			break
		else
			temp[$n]=$(echo [2606:4700:d0::$(printf '%x\n' $(($RANDOM*2+$RANDOM%2))):$(printf '%x\n' $(($RANDOM*2+$RANDOM%2))):$(printf '%x\n' $(($RANDOM*2+$RANDOM%2))):$(printf '%x\n' $(($RANDOM*2+$RANDOM%2)))])
			n=$[$n+1]
		fi
		if [ $(echo ${temp[@]} | sed -e 's/ /\n/g' | sort -u | wc -l) -ge $iplist ]
		then
			break
		else
			temp[$n]=$(echo [2606:4700:d1::$(printf '%x\n' $(($RANDOM*2+$RANDOM%2))):$(printf '%x\n' $(($RANDOM*2+$RANDOM%2))):$(printf '%x\n' $(($RANDOM*2+$RANDOM%2))):$(printf '%x\n' $(($RANDOM*2+$RANDOM%2)))])
			n=$[$n+1]
		fi
	done
else
	n=0
	iplist=100
	while true
	do
		temp[$n]=$(echo 162.159.192.$(($RANDOM%256)))
		n=$[$n+1]
		if [ $n -ge $iplist ]
		then
			break
		fi
		temp[$n]=$(echo 162.159.193.$(($RANDOM%256)))
		n=$[$n+1]
		if [ $n -ge $iplist ]
		then
			break
		fi
		temp[$n]=$(echo 162.159.195.$(($RANDOM%256)))
		n=$[$n+1]
		if [ $n -ge $iplist ]
		then
			break
		fi
	done
	while true
	do
		if [ $(echo ${temp[@]} | sed -e 's/ /\n/g' | sort -u | wc -l) -ge $iplist ]
		then
			break
		else
			temp[$n]=$(echo 162.159.192.$(($RANDOM%256)))
			n=$[$n+1]
		fi
		if [ $(echo ${temp[@]} | sed -e 's/ /\n/g' | sort -u | wc -l) -ge $iplist ]
		then
			break
		else
			temp[$n]=$(echo 162.159.193.$(($RANDOM%256)))
			n=$[$n+1]
		fi
		if [ $(echo ${temp[@]} | sed -e 's/ /\n/g' | sort -u | wc -l) -ge $iplist ]
		then
			break
		else
			temp[$n]=$(echo 162.159.195.$(($RANDOM%256)))
			n=$[$n+1]
		fi
	done
fi
echo ${temp[@]} | sed -e 's/ /\n/g' | sort -u>/root/warpip/ip.txt
wget -qO /root/warpip/$cpu https://gitlab.com/rwkgyg/CFwarp/raw/main/point/$cpu && chmod +x /root/warpip/$cpu
cd /root/warpip
./$cpu >/dev/null 2>&1 &
wait
cd
export endpoint=`cat /root/warpip/result.csv | awk -F, '$3!="timeout ms" {print} ' | sed -n '2p' | awk -F ',' '{print $1}'`
green "脚本将自动应用本地VPS优选的warp对端IP地址：$endpoint"
}

warpip(){
if [[ ! -f '/root/warpip/result.csv' ]]; then
checkwgcf
if [[ ! $wgcfv4 =~ on|plus && ! $wgcfv6 =~ on|plus ]]; then
checkpt
else
systemctl stop wg-quick@wgcf >/dev/null 2>&1
kill -15 $(pgrep warp-go) >/dev/null 2>&1 && sleep 2
checkpt
systemctl start wg-quick@wgcf >/dev/null 2>&1
systemctl restart warp-go >/dev/null 2>&1
systemctl enable warp-go >/dev/null 2>&1
systemctl start warp-go >/dev/null 2>&1
fi
else
export endpoint=`cat /root/warpip/result.csv | awk -F, '$3!="timeout ms" {print} ' | sed -n '2p' | awk -F ',' '{print $1}'`
green "脚本将自动应用本地VPS优选的warp对端IP地址：$endpoint"
fi
}
warpip

dig9(){
if [[ -n $(grep 'DiG 9' /etc/hosts) ]]; then
echo -e "search blue.kundencontroller.de\noptions rotate\nnameserver 2a02:180:6:5::1c\nnameserver 2a02:180:6:5::4\nnameserver 2a02:180:6:5::1e\nnameserver 2a02:180:6:5::1d" > /etc/resolv.conf
fi
}

get_char(){
SAVEDSTTY=`stty -g`
stty -echo
stty cbreak
dd if=/dev/tty bs=1 count=1 2> /dev/null
stty -raw
stty echo
stty $SAVEDSTTY
}

mtuwarp(){
v4v6
yellow "开始自动设置warp的MTU最佳网络吞吐量值，以优化WARP网络！"
MTUy=1500
MTUc=10
if [[ -n $v6 && -z $v4 ]]; then
ping='ping6'
IP1='2606:4700:4700::1111'
IP2='2001:4860:4860::8888'
else
ping='ping'
IP1='1.1.1.1'
IP2='8.8.8.8'
fi
while true; do
if ${ping} -c1 -W1 -s$((${MTUy} - 28)) -Mdo ${IP1} >/dev/null 2>&1 || ${ping} -c1 -W1 -s$((${MTUy} - 28)) -Mdo ${IP2} >/dev/null 2>&1; then
MTUc=1
MTUy=$((${MTUy} + ${MTUc}))
else
MTUy=$((${MTUy} - ${MTUc}))
[[ ${MTUc} = 1 ]] && break
fi
[[ ${MTUy} -le 1360 ]] && MTUy='1360' && break
done
MTU=$((${MTUy} - 80))
green "MTU最佳网络吞吐量值= $MTU 已设置完毕"
}

first4(){
checkwgcf
if [[ $wgcfv4 =~ on|plus && -z $wgcfv6 ]]; then
[[ -e /etc/gai.conf ]] && grep -qE '^ *precedence ::ffff:0:0/96  100' /etc/gai.conf || echo 'precedence ::ffff:0:0/96  100' >> /etc/gai.conf 2>/dev/null
sed -i '/^label 2002::\/16   2/d' /etc/gai.conf 2>/dev/null
else
sed -i '/^precedence ::ffff:0:0\/96  100/d;/^label 2002::\/16   2/d' /etc/gai.conf 2>/dev/null
fi
}

docker(){
if [[ -n $(ip a | grep docker) ]]; then
red "检测到VPS已安装docker，如继续安装方案一的WARP，docker就会失效"
red "为避免docker失效，建议使用方案二或者方案三"
sleep 3s
yellow "6秒后继续安装方案一的WARP，退出安装请按Ctrl+c"
sleep 6s
fi
}

uncf(){
if [[ -z $(type -P warp-go) && -z $(type -P wg-quick) && -z $(type -P warp-cli) ]]; then
rm -rf /root/CFwarp.sh /usr/bin/cf
fi
}

upcfwarp(){
wget -N https://gitlab.com/rwkgyg/CFwarp/raw/main/CFwarp.sh
chmod +x /root/CFwarp.sh 
ln -sf /root/CFwarp.sh /usr/bin/cf 
green "CFwarp安装脚本升级成功" && cf
}

cso(){
warp-cli --accept-tos disconnect >/dev/null 2>&1
warp-cli --accept-tos disable-always-on >/dev/null 2>&1
warp-cli --accept-tos delete >/dev/null 2>&1
if [[ $release = Centos ]]; then
yum autoremove cloudflare-warp -y
else
apt purge cloudflare-warp -y
rm -f /etc/apt/sources.list.d/cloudflare-client.list /usr/share/keyrings/cloudflare-warp-archive-keyring.gpg
fi
$yumapt autoremove
}

lncf(){
if [[ -n $(type -P warp-go) || -n $(type -P warp-cli) || -n $(type -P wg-quick) ]]; then
chmod +x /root/CFwarp.sh 
ln -sf /root/CFwarp.sh /usr/bin/cf
fi
}

ShowSOCKS5(){
if [[ $(systemctl is-active warp-svc) = active ]]; then
mport=`warp-cli --accept-tos settings 2>/dev/null | grep 'WarpProxy on port' | awk -F "port " '{print $2}'`
s5ip=`curl -sx socks5h://localhost:$mport ip.sb -k`
nfs5
#NF=$(./nf -proxy socks5h://localhost:$mport | awk '{print $1}' | sed -n '3p')
[[ $(curl -sx socks5h://localhost:$mport https://chat.openai.com/ -I | grep "text/plain") != "" ]] && chat='遗憾，当前IP无法访问ChatGPT官网服务' || chat='恭喜，当前IP支持访问ChatGPT官网服务'
isp4a=`curl -sx socks5h://localhost:$mport --user-agent "${UA_Browser}" http://ip-api.com/json/$v4?lang=zh-CN -k | cut -f13 -d ":" | cut -f2 -d '"'`
isp4b=`curl -sx socks5h://localhost:$mport --user-agent "${UA_Browser}" https://api.ip.sb/geoip/$v4 -k | awk -F "isp" '{print $2}' | awk -F "offset" '{print $1}' | sed "s/[,\":]//g"`
[[ -n $isp4a ]] && isp4=$isp4a || isp4=$isp4b
nonf=$(curl -sx socks5h://localhost:$mport --user-agent "${UA_Browser}" http://ip-api.com/json/$v4?lang=zh-CN -k | cut -f2 -d"," | cut -f4 -d '"')
#sunf=$(./nf | awk '{print $1}' | sed -n '4p')
#snnf=$(curl -sx socks5h://localhost:$mport ip.p3terx.com -k | sed -n 2p | awk '{print $3}')
country=$nonf
socks5=$(curl -sx socks5h://localhost:$mport www.cloudflare.com/cdn-cgi/trace -k --connect-timeout 2 | grep warp | cut -d= -f2) 
case ${socks5} in 
plus) 
S5Status=$(white "Socks5 WARP+状态：\c" ; rred "运行中，WARP+普通账户(剩余WARP+流量:$((`warp-cli --accept-tos account | grep Quota | awk '{ print $(NF) }'`/1000000000))GiB)" ; white " Socks5 端口：\c" ; rred "$mport" ; white " 服务商 Cloudflare 获取IPV4地址：\c" ; rred "$s5ip  $country" ; white " 奈飞NF解锁情况：\c" ; rred "$NF" ; white " ChatGPT解锁情况：\c" ; rred "$chat");;  
on) 
S5Status=$(white "Socks5 WARP状态：\c" ; green "运行中，WARP普通账户(无限WARP流量)" ; white " Socks5 端口：\c" ; green "$mport" ; white " 服务商 Cloudflare 获取IPV4地址：\c" ; green "$s5ip  $country" ; white " 奈飞NF解锁情况：\c" ; green "$NF" ; white " ChatGPT解锁情况：\c" ; green "$chat");;  
*) 
S5Status=$(white "Socks5 WARP状态：\c" ; yellow "已安装Socks5-WARP客户端，但端口处于关闭状态")
esac 
else
S5Status=$(white "Socks5 WARP状态：\c" ; red "未安装Socks5-WARP客户端")
fi
}

SOCKS5ins(){
yellow "检测Socks5-WARP安装环境中……"
if [[ $release = Centos ]]; then
[[ ! ${vsid} =~ 8 ]] && yellow "当前系统版本号：Centos $vsid \nSocks5-WARP仅支持Centos 8 " && bash CFwarp.sh 
elif [[ $release = Ubuntu ]]; then
[[ ! ${vsid} =~ 16|18|20|22 ]] && yellow "当前系统版本号：Ubuntu $vsid \nSocks5-WARP仅支持 Ubuntu 16.04/18.04/20.04/22.04系统 " && bash CFwarp.sh 
elif [[ $release = Debian ]]; then
[[ ! ${vsid} =~ 9|10|11 ]] && yellow "当前系统版本号：Debian $vsid \nSocks5-WARP仅支持 Debian 9/10/11系统 " && bash CFwarp.sh 
fi
[[ $(warp-cli --accept-tos status 2>/dev/null) =~ 'Connected' ]] && red "当前Socks5-WARP已经在运行中" && bash CFwarp.sh

systemctl stop wg-quick@wgcf >/dev/null 2>&1
kill -15 $(pgrep warp-go) >/dev/null 2>&1 && sleep 2
v4v6
if [[ -n $v6 && -z $v4 ]]; then
systemctl start wg-quick@wgcf >/dev/null 2>&1
systemctl restart warp-go >/dev/null 2>&1
systemctl enable warp-go >/dev/null 2>&1
systemctl start warp-go >/dev/null 2>&1
red "纯IPV6的VPS目前不支持安装Socks5-WARP" && sleep 2 && bash CFwarp.sh
else
systemctl restart warp-go >/dev/null 2>&1
systemctl enable warp-go >/dev/null 2>&1
systemctl start warp-go >/dev/null 2>&1
#elif [[ -n $v4 && -z $v6 ]]; then
#systemctl start wg-quick@wgcf >/dev/null 2>&1
#checkwgcf
#[[ $wgcfv4 =~ on|plus ]] && red "纯IPV4的VPS已安装Wgcf-WARP-IPV4，不支持安装Socks5-WARP" && bash CFwarp.sh
#elif [[ -n $v4 && -n $v6 ]]; then
#systemctl start wg-quick@wgcf >/dev/null 2>&1
#checkwgcf
#[[ $wgcfv4 =~ on|plus || $wgcfv6 =~ on|plus ]] && red "原生双栈VPS已安装Wgcf-WARP-IPV4/IPV6，请先卸载。然后安装Socks5-WARP，最后安装Wgcf-WARP-IPV4/IPV6" && bash CFwarp.sh
fi
#systemctl start wg-quick@wgcf >/dev/null 2>&1
#checkwgcf
#if [[ $wgcfv4 =~ on|plus && $wgcfv6 =~ on|plus ]]; then
#red "已安装Wgcf-WARP-IPV4+IPV6，不支持安装Socks5-WARP" && bash CFwarp.sh
#fi
if [[ $release = Centos ]]; then 
if [[ ${vsid} =~ 8 ]]; then
cd /etc/yum.repos.d/ && mkdir backup && mv *repo backup/ 
curl -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-8.repo
sed -i -e "s|mirrors.cloud.aliyuncs.com|mirrors.aliyun.com|g " /etc/yum.repos.d/CentOS-*
sed -i -e "s|releasever|releasever-stream|g" /etc/yum.repos.d/CentOS-*
yum clean all && yum makecache
fi
yum -y install epel-release && yum -y install net-tools
rpm -ivh https://pkg.cloudflareclient.com/cloudflare-release-el8.rpm
yum -y install cloudflare-warp
fi
if [[ $release = Debian ]]; then
[[ ! $(type -P gpg) ]] && apt update && apt install gnupg -y
[[ ! $(apt list 2>/dev/null | grep apt-transport-https | grep installed) ]] && apt update && apt install apt-transport-https -y
fi
if [[ $release != Centos ]]; then 
apt install net-tools -y
curl https://pkg.cloudflareclient.com/pubkey.gpg | gpg --yes --dearmor --output /usr/share/keyrings/cloudflare-warp-archive-keyring.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/cloudflare-warp-archive-keyring.gpg] http://pkg.cloudflareclient.com/ $(lsb_release -sc) main" | tee /etc/apt/sources.list.d/cloudflare-client.list
apt update;apt install cloudflare-warp -y
fi
warpip
warp-cli --accept-tos register >/dev/null 2>&1 && sleep 2
warp-cli --accept-tos set-mode proxy >/dev/null 2>&1
warp-cli --accept-tos set-custom-endpoint "$endpoint" >/dev/null 2>&1
warp-cli --accept-tos enable-always-on >/dev/null 2>&1
sleep 2 && ShowSOCKS5 && S5menu && lncf
}

WGCFmenu(){
white "------------------------------------------------------------------------------------"
white " 当前 IPV4 接管出站流量情况如下 "
white " ${WARPIPv4Status}"
white "------------------------------------------------------------------------------------"
white " 当前 IPV6 接管出站流量情况如下"
white " ${WARPIPv6Status}"
white "------------------------------------------------------------------------------------"
}
S5menu(){
white "------------------------------------------------------------------------------------------------"
white " 当前Socks5-WARP官方客户端本地代理情况如下"
blue " ${S5Status}"
white "------------------------------------------------------------------------------------------------"
}

back(){
white "------------------------------------------------------------------------------------"
white " 回主菜单，请按任意键"
white " 退出脚本，请按Ctrl+C"
get_char && bash CFwarp.sh
}

IP_Status_menu(){
WGCFmenu;S5menu 
}

ONEWARPGO(){
yellow "\n 请稍等……" && sleep 2
STOPwgcf(){
if [[ -n $(type -P warp-cli) ]]; then
red "已安装Socks5-WARP(+)，不支持当前选择的WARP安装方案" 
systemctl restart warp-go ; bash CFwarp.sh
fi
}

warpwgcf(){
if [[ -e "/usr/local/bin/wgcf" ]]; then
red "请先卸载已安装的WGCF-WARP，否则无法安装当前的WARP-GO，脚本退出" && exit
fi
}

ShowWGCF(){
UA_Browser="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/80.0.3987.87 Safari/537.36"
v4v6
warppflow=$((`grep -oP '"quota":\K\d+' <<< $(curl -sm4 "https://api.cloudflareclient.com/v0a884/reg/$(grep 'Device' /usr/local/bin/warp.conf 2>/dev/null | cut -d= -f2 | sed 's# ##g')" -H "User-Agent: okhttp/3.12.1" -H "Authorization: Bearer $(grep 'Token' /usr/local/bin/warp.conf 2>/dev/null | cut -d= -f2 | sed 's# ##g')")`))
flow=`echo "scale=2; $warppflow/1000000000" | bc`
[[ -e /usr/local/bin/warpplus.log ]] && cfplus="WARP+普通账户(有限WARP+流量：$flow GB)，设备名称：$(sed -n 1p /usr/local/bin/warpplus.log)" || cfplus="WARP+Teams账户(无限WARP+流量)"
if [[ -n $v4 ]]; then
nf4
[[ $(curl -s4S https://chat.openai.com/ -I | grep "text/plain") != "" ]] && chat='遗憾，当前IP无法访问ChatGPT官网服务' || chat='恭喜，当前IP支持访问ChatGPT官网服务'
wgcfv4=$(curl -s4 https://www.cloudflare.com/cdn-cgi/trace -k | grep warp | cut -d= -f2) 
isp4a=`curl -sm6 --user-agent "${UA_Browser}" http://ip-api.com/json/$v4?lang=zh-CN -k | cut -f13 -d ":" | cut -f2 -d '"'`
isp4b=`curl -sm6 --user-agent "${UA_Browser}" https://api.ip.sb/geoip/$v4 -k | awk -F "isp" '{print $2}' | awk -F "offset" '{print $1}' | sed "s/[,\":]//g"`
[[ -n $isp4a ]] && isp4=$isp4a || isp4=$isp4b
nonf=$(curl -sm6 --user-agent "${UA_Browser}" http://ip-api.com/json/$v4?lang=zh-CN -k | cut -f2 -d"," | cut -f4 -d '"')
#sunf=$(./nf | awk '{print $1}' | sed -n '4p')
#snnf=$(curl -s4m6 ip.p3terx.com -k | sed -n 2p | awk '{print $3}')
country=$nonf
case ${wgcfv4} in 
plus) 
WARPIPv4Status=$(white "WARP+状态：\c" ; rred "运行中，$cfplus" ; white " 服务商 Cloudflare 获取IPV4地址：\c" ; rred "$v4  $country" ; white " 奈飞NF解锁情况：\c" ; rred "$NF" ; white " ChatGPT解锁情况：\c" ; rred "$chat");;  
on) 
WARPIPv4Status=$(white "WARP状态：\c" ; green "运行中，WARP普通账户(无限WARP流量)" ; white " 服务商 Cloudflare 获取IPV4地址：\c" ; green "$v4  $country" ; white " 奈飞NF解锁情况：\c" ; green "$NF" ; white " ChatGPT解锁情况：\c" ; green "$chat");;
off) 
WARPIPv4Status=$(white "WARP状态：\c" ; yellow "关闭中" ; white " 服务商 $isp4 获取IPV4地址：\c" ; yellow "$v4  $country" ; white " 奈飞NF解锁情况：\c" ; yellow "$NF" ; white " ChatGPT解锁情况：\c" ; yellow "$chat");; 
esac 
else
WARPIPv4Status=$(white "IPV4状态：\c" ; red "不存在IPV4地址 ")
fi 
if [[ -n $v6 ]]; then
nf6
[[ $(curl -s6S https://chat.openai.com/ -I | grep "text/plain") != "" ]] && chat='遗憾，当前IP无法访问ChatGPT官网服务' || chat='恭喜，当前IP支持访问ChatGPT官网服务'
wgcfv6=$(curl -s6 https://www.cloudflare.com/cdn-cgi/trace -k | grep warp | cut -d= -f2) 
isp6a=`curl -sm6 --user-agent "${UA_Browser}" http://ip-api.com/json/$v6?lang=zh-CN -k | cut -f13 -d":" | cut -f2 -d '"'`
isp6b=`curl -sm6 --user-agent "${UA_Browser}" https://api.ip.sb/geoip/$v6 -k | awk -F "isp" '{print $2}' | awk -F "offset" '{print $1}' | sed "s/[,\":]//g"`
[[ -n $isp6a ]] && isp6=$isp6a || isp6=$isp6b
nonf=$(curl -sm6 --user-agent "${UA_Browser}" http://ip-api.com/json/$v6?lang=zh-CN -k | cut -f2 -d"," | cut -f4 -d '"')
#sunf=$(./nf | awk '{print $1}' | sed -n '8p')
#snnf=$(curl -s6m6 ip.p3terx.com -k | sed -n 2p | awk '{print $3}')
country=$nonf
case ${wgcfv6} in 
plus) 
WARPIPv6Status=$(white "WARP+状态：\c" ; rred "运行中，$cfplus" ; white " 服务商 Cloudflare 获取IPV6地址：\c" ; rred "$v6  $country" ; white " 奈飞NF解锁情况：\c" ; rred "$NF" ; white " ChatGPT解锁情况：\c" ; rred "$chat");;  
on) 
WARPIPv6Status=$(white "WARP状态：\c" ; green "运行中，WARP普通账户(无限WARP流量)" ; white " 服务商 Cloudflare 获取IPV6地址：\c" ; green "$v6  $country" ; white " 奈飞NF解锁情况：\c" ; green "$NF" ; white " ChatGPT解锁情况：\c" ; green "$chat");;
off) 
WARPIPv6Status=$(white "WARP状态：\c" ; yellow "关闭中" ; white " 服务商 $isp6 获取IPV6地址：\c" ; yellow "$v6  $country" ; white " 奈飞NF解锁情况：\c" ; yellow "$NF" ; white " ChatGPT解锁情况：\c" ; yellow "$chat");;
esac 
else
WARPIPv6Status=$(white "IPV6状态：\c" ; red "不存在IPV6地址 ")
fi 
}

wgo1='sed -i "s#.*AllowedIPs.*#AllowedIPs = 0.0.0.0/0#g" /usr/local/bin/warp.conf'
wgo2='sed -i "s#.*AllowedIPs.*#AllowedIPs = ::/0#g" /usr/local/bin/warp.conf'
wgo3='sed -i "s#.*AllowedIPs.*#AllowedIPs = 0.0.0.0/0,::/0#g" /usr/local/bin/warp.conf'
wgo4="sed -i "/Endpoint6/d" /usr/local/bin/warp.conf && sed -i "s/162.159.*/$endpoint/g" /usr/local/bin/warp.conf"
wgo5="sed -i "/Endpoint6/d" /usr/local/bin/warp.conf && sed -i "s/162.159.*/$endpoint/g" /usr/local/bin/warp.conf"
wgo6='sed -i "20 s/^/PostUp = ip -4 rule add from $(ip route get 162.159.192.1 | grep -oP "src \K\S+") lookup main\n/" /usr/local/bin/warp.conf && sed -i "20 s/^/PostDown = ip -4 rule delete from $(ip route get 162.159.192.1 | grep -oP "src \K\S+") lookup main\n/" /usr/local/bin/warp.conf'
wgo7='sed -i "20 s/^/PostUp = ip -6 rule add from $(ip route get 2606:4700:d0::a29f:c001 | grep -oP "src \K\S+") lookup main\n/" /usr/local/bin/warp.conf && sed -i "20 s/^/PostDown = ip -6 rule delete from $(ip route get 2606:4700:d0::a29f:c001 | grep -oP "src \K\S+") lookup main\n/" /usr/local/bin/warp.conf'
wgo8='sed -i "20 s/^/PostUp = ip -4 rule add from $(ip route get 162.159.192.1 | grep -oP "src \K\S+") lookup main\n/" /usr/local/bin/warp.conf && sed -i "20 s/^/PostDown = ip -4 rule delete from $(ip route get 162.159.192.1 | grep -oP "src \K\S+") lookup main\n/" /usr/local/bin/warp.conf && sed -i "20 s/^/PostUp = ip -6 rule add from $(ip route get 2606:4700:d0::a29f:c001 | grep -oP "src \K\S+") lookup main\n/" /usr/local/bin/warp.conf && sed -i "20 s/^/PostDown = ip -6 rule delete from $(ip route get 2606:4700:d0::a29f:c001 | grep -oP "src \K\S+") lookup main\n/" /usr/local/bin/warp.conf'

CheckWARP(){
i=0
while [ $i -le 9 ]; do let i++
yellow "共执行10次，第$i次获取warp的IP中……"
kill -15 $(pgrep warp-go) >/dev/null 2>&1 && sleep 2
systemctl restart warp-go
systemctl enable warp-go
systemctl start warp-go
checkwgcf
if [[ $wgcfv4 =~ on|plus || $wgcfv6 =~ on|plus ]]; then
green "恭喜！warp的IP获取成功！" && dns
break
else
red "遗憾！warp的IP获取失败"
fi
done
if [[ ! $wgcfv4 =~ on|plus && ! $wgcfv6 =~ on|plus ]]; then
yellow "安装WARP失败，还原VPS，卸载WARP"
cwg && rm -rf /root/warpip
echo
[[ $release = Centos && ${vsid} -lt 7 ]] && yellow "当前系统版本号：Centos $vsid \n建议使用 Centos 7 以上系统 " 
[[ $release = Ubuntu && ${vsid} -lt 18 ]] && yellow "当前系统版本号：Ubuntu $vsid \n建议使用 Ubuntu 18 以上系统 " 
[[ $release = Debian && ${vsid} -lt 10 ]] && yellow "当前系统版本号：Debian $vsid \n建议使用 Debian 10 以上系统 "
red "可以使用方案二或方案三"
red "建议选择WGCF核心来安装WARP方案一"
exit
else 
green "ok" && systemctl restart warp-go
fi
xyz(){
att
[[ -e /root/check.sh ]] && screen -S aw -X quit ; screen -UdmS aw bash -c '/bin/bash /root/check.sh'
[[ -e /root/WARP-CR.sh ]] && screen -S cr -X quit ; screen -UdmS cr bash -c '/bin/bash /root/WARP-CR.sh'
[[ -e /root/WARP-CP.sh ]] && screen -S cp -X quit ; screen -UdmS cp bash -c '/bin/bash /root/WARP-CP.sh'
if [[ -e /root/WARP-UP.sh ]]; then
screen -S up -X quit ; screen -UdmS up bash -c '/bin/bash /root/WARP-UP.sh'
else
green "安装warp在线监测守护进程"
cat>/root/WARP-UP.sh<<-\EOF
#!/bin/bash
red(){ echo -e "\033[31m\033[01m$1\033[0m";}
green(){ echo -e "\033[32m\033[01m$1\033[0m";}
checkwgcf(){
wgcfv6=$(curl -s6m6 https://www.cloudflare.com/cdn-cgi/trace -k | grep warp | cut -d= -f2) 
wgcfv4=$(curl -s4m6 https://www.cloudflare.com/cdn-cgi/trace -k | grep warp | cut -d= -f2) 
}
warpclose(){
wg-quick down wgcf >/dev/null 2>&1 ; systemctl stop wg-quick@wgcf >/dev/null 2>&1 ; systemctl disable wg-quick@wgcf >/dev/null 2>&1
}
warpopen(){
wg-quick down wgcf >/dev/null 2>&1 ; systemctl enable wg-quick@wgcf >/dev/null 2>&1 ; systemctl start wg-quick@wgcf >/dev/null 2>&1 ; systemctl restart wg-quick@wgcf >/dev/null 2>&1
}
warpre(){
i=0
while [ $i -le 4 ]; do let i++
warpopen
checkwgcf
[[ $wgcfv4 =~ on|plus || $wgcfv6 =~ on|plus ]] && green "中断后的warp尝试获取IP成功！" && break || red "中断后的warp尝试获取IP失败！"
done
checkwgcf
if [[ ! $wgcfv4 =~ on|plus && ! $wgcfv6 =~ on|plus ]]; then
warpclose
red "由于5次尝试获取warp的IP失败，现执行停止并关闭warp，VPS恢复原IP状态"
fi
}
while true; do
green "检测warp是否启动中…………"
checkwgcf
[[ $wgcfv4 =~ on|plus || $wgcfv6 =~ on|plus ]] && green "恭喜！warp状态为运行中！下轮检测将在你设置的60秒后自动执行" && sleep 60s || (warpre ; green "下轮检测将在你设置的50秒后自动执行" ; sleep 50s)
done
EOF
readp "warp状态为运行时，重新检测warp状态间隔时间（回车默认60秒）,请输入间隔时间（例：50秒，输入50）:" stop
[[ -n $stop ]] && sed -i "s/60s/${stop}s/g;s/60秒/${stop}秒/g" /root/WARP-UP.sh || green "默认间隔60秒"
readp "warp状态为中断时(连续5次失败自动关闭warp)，继续检测WARP状态间隔时间（回车默认50秒）,请输入间隔时间（例：50秒，输入50）:" goon
[[ -n $goon ]] && sed -i "s/50s/${goon}s/g;s/50秒/${goon}秒/g" /root/WARP-UP.sh || green "默认间隔50秒"
[[ -e /root/WARP-UP.sh ]] && screen -S up -X quit ; screen -UdmS up bash -c '/bin/bash /root/WARP-UP.sh'
green "设置screen窗口名称'up'" && sleep 2
grep -qE "^ *@reboot root screen -UdmS up bash -c '/bin/bash /root/WARP-UP.sh' >/dev/null 2>&1" /etc/crontab || echo "@reboot root screen -UdmS up bash -c '/bin/bash /root/WARP-UP.sh' >/dev/null 2>&1" >> /etc/crontab
green "添加warp在线守护进程功能"
fi
}
}

nat4(){
[[ -n $(ip route get 1.1.1.1 2>/dev/null | grep -oP 'src \K\S+') ]] && wpgo4=$wgo6 || wpgo4=echo
}

WGCFv4(){
yellow "稍等3秒，检测VPS内warp环境"
docker && checkwgcf
if [[ ! $wgcfv4 =~ on|plus && ! $wgcfv6 =~ on|plus ]]; then
v4v6
if [[ -n $v4 && -n $v6 ]]; then
green "当前原生v4+v6双栈vps首次安装warp\n现添加WARP IPV4（IP出站表现：原生 IPV6 + WARP IPV4）" && sleep 2
wpgo1=$wgo1 && wpgo2=$wgo4 && wpgo3=$wgo8 && WGCFins
fi
if [[ -n $v6 && -z $v4 ]]; then
green "当前原生v6单栈vps首次安装warp\n现添加WARP IPV4（IP出站表现：原生 IPV6 + WARP IPV4）" && sleep 2
wpgo1=$wgo1 && wpgo2=$wgo5 && wpgo3=$wgo7 && nat4 && WGCFins
fi
if [[ -z $v6 && -n $v4 ]]; then
green "当前原生v4单栈vps首次安装warp\n现添加WARP IPV4（IP出站表现：仅WARP IPV4）" && sleep 2
wpgo1=$wgo1 && wpgo2=$wgo4 && wpgo3=$wgo6 && WGCFins
fi
first4
else
kill -15 $(pgrep warp-go) >/dev/null 2>&1
sleep 2 && v4v6
if [[ -n $v4 && -n $v6 ]]; then
green "当前原生v4+v6双栈vps已安装warp\n现快速切换WARP IPV4（IP出站表现：原生 IPV6 + WARP IPV4）" && sleep 2
wpgo1=$wgo1 && wpgo2=$wgo4 && wpgo3=$wgo8 && ABC
fi
if [[ -n $v6 && -z $v4 ]]; then
green "当前原生v6单栈vps已安装warp\n现快速切换WARP IPV4（IP出站表现：原生 IPV6 + WARP IPV4）" && sleep 2
wpgo1=$wgo1 && wpgo2=$wgo5 && wpgo3=$wgo7 && nat4 && ABC
fi
if [[ -z $v6 && -n $v4 ]]; then
green "当前原生v4单栈vps已安装warp\n现快速切换WARP IPV4（IP出站表现：仅WARP IPV4）" && sleep 2
wpgo1=$wgo1 && wpgo2=$wgo4 && wpgo3=$wgo6 && ABC
fi
CheckWARP && first4 && ShowWGCF && WGCFmenu
fi
}

WGCFv6(){
yellow "稍等3秒，检测VPS内warp环境"
docker && checkwgcf
if [[ ! $wgcfv4 =~ on|plus && ! $wgcfv6 =~ on|plus ]]; then
v4v6
if [[ -n $v4 && -n $v6 ]]; then
green "当前原生v4+v6双栈vps首次安装warp\n现添加WARP IPV6（IP出站表现：原生 IPV4 + WARP IPV6）" && sleep 2
wpgo1=$wgo2 && wpgo2=$wgo4 && wpgo3=$wgo8 && WGCFins
fi
if [[ -n $v6 && -z $v4 ]]; then
green "当前原生v6单栈vps首次安装warp\n现添加WARP IPV6（IP出站表现：仅WARP IPV6）" && sleep 2
wpgo1=$wgo2 && wpgo2=$wgo5 && wpgo3=$wgo7 && nat4 && WGCFins
fi
if [[ -z $v6 && -n $v4 ]]; then
green "当前原生v4单栈vps首次安装warp\n现添加WARP IPV6（IP出站表现：原生 IPV4 + WARP IPV6）" && sleep 2
wpgo1=$wgo2 && wpgo2=$wgo4 && wpgo3=$wgo6 && WGCFins
fi
else
kill -15 $(pgrep warp-go) >/dev/null 2>&1
sleep 2 && v4v6
if [[ -n $v4 && -n $v6 ]]; then
green "当前原生v4+v6双栈vps已安装warp\n现快速切换WARP IPV6（IP出站表现：原生 IPV4 + WARP IPV6）" && sleep 2
wpgo1=$wgo2 && wpgo2=$wgo4 && wpgo3=$wgo8 && ABC
fi
if [[ -n $v6 && -z $v4 ]]; then
green "当前原生v6单栈vps已安装warp\n现快速切换WARP IPV6（IP出站表现：仅WARP IPV6）" && sleep 2
wpgo1=$wgo2 && wpgo2=$wgo5 && wpgo3=$wgo7 && nat4 && ABC
fi
if [[ -z $v6 && -n $v4 ]]; then
green "当前原生v4单栈vps已安装warp\n现快速切换WARP IPV6（IP出站表现：原生 IPV4 + WARP IPV6）" && sleep 2
wpgo1=$wgo2 && wpgo2=$wgo4 && wpgo3=$wgo6 && ABC
fi
CheckWARP && first4 && ShowWGCF && WGCFmenu
fi
}

WGCFv4v6(){
yellow "稍等3秒，检测VPS内warp环境"
docker && checkwgcf
if [[ ! $wgcfv4 =~ on|plus && ! $wgcfv6 =~ on|plus ]]; then
v4v6
if [[ -n $v4 && -n $v6 ]]; then
green "当前原生v4+v6双栈vps首次安装warp\n现添加WARP IPV4+IPV6（IP出站表现：WARP双栈 IPV4 + IPV6）" && sleep 2
wpgo1=$wgo3 && wpgo2=$wgo4 && wpgo3=$wgo8 && WGCFins
fi
if [[ -n $v6 && -z $v4 ]]; then
green "当前原生v6单栈vps首次安装warp\n现添加WARP IPV4+IPV6（IP出站表现：WARP双栈 IPV4 + IPV6）" && sleep 2
wpgo1=$wgo3 && wpgo2=$wgo5 && wpgo3=$wgo7 && nat4 && WGCFins
fi
if [[ -z $v6 && -n $v4 ]]; then
green "当前原生v4单栈vps首次安装warp\n现添加WARP IPV4+IPV6（IP出站表现：WARP双栈 IPV4 + IPV6）" && sleep 2
wpgo1=$wgo3 && wpgo2=$wgo4 && wpgo3=$wgo6 && WGCFins
fi
else
kill -15 $(pgrep warp-go) >/dev/null 2>&1
sleep 2 && v4v6
if [[ -n $v4 && -n $v6 ]]; then
green "当前原生v4+v6双栈vps已安装warp\n现快速切换WARP IPV4+IPV6（IP出站表现：WARP双栈 IPV4 + IPV6）" && sleep 2
wpgo1=$wgo3 && wpgo2=$wgo4 && wpgo3=$wgo8 && ABC
fi
if [[ -n $v6 && -z $v4 ]]; then
green "当前原生v6单栈vps已安装warp\n现快速切换WARP IPV4+IPV6（IP出站表现：WARP双栈 IPV4 + IPV6）" && sleep 2
wpgo1=$wgo3 && wpgo2=$wgo5 && wpgo3=$wgo7 && nat4 && ABC
fi
if [[ -z $v6 && -n $v4 ]]; then
green "当前原生v4单栈vps已安装warp\n现快速切换WARP IPV4+IPV6（IP出站表现：WARP双栈 IPV4 + IPV6）" && sleep 2
wpgo1=$wgo3 && wpgo2=$wgo4 && wpgo3=$wgo6 && ABC
fi
CheckWARP && first4 && ShowWGCF && WGCFmenu
fi
}

ABC(){
echo $wpgo1 | sh
echo $wpgo2 | sh
echo $wpgo3 | sh
echo $wpgo4 | sh
}

dns(){
if [[ ! -f /etc/resolv.conf.bak ]]; then
mv /etc/resolv.conf /etc/resolv.conf.bak
rm -rf /etc/resolv.conf
cp -f /etc/resolv.conf.bak /etc/resolv.conf
chattr +i /etc/resolv.conf >/dev/null 2>&1
else
chattr +i /etc/resolv.conf >/dev/null 2>&1
fi
}

WGCFins(){
if [[ $release = Centos ]]; then
if [[ ${vsid} =~ 8 ]]; then
cd /etc/yum.repos.d/ && mkdir backup && mv *repo backup/ 
curl -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-8.repo
sed -i -e "s|mirrors.cloud.aliyuncs.com|mirrors.aliyun.com|g " /etc/yum.repos.d/CentOS-*
sed -i -e "s|releasever|releasever-stream|g" /etc/yum.repos.d/CentOS-*
yum clean all && yum makecache
fi
yum install epel-release -y;yum install iproute iputils-ping -y
elif [[ $release = Debian ]]; then
apt install lsb-release -y
echo "deb http://deb.debian.org/debian $(lsb_release -sc)-backports main" | tee /etc/apt/sources.list.d/backports.list
apt update -y;apt install iproute2 openresolv dnsutils iputils-ping -y   		
elif [[ $release = Ubuntu ]]; then
apt update -y;apt install iproute2 openresolv dnsutils iputils-ping -y
fi
wget -N https://gitlab.com/rwkgyg/CFwarp/-/raw/main/warp-go_1.0.8_linux_${cpu} -O /usr/local/bin/warp-go && chmod +x /usr/local/bin/warp-go
until [[ -e /usr/local/bin/warp.conf ]]; do
yellow "正在申请WARP普通账户，请稍等" && sleep 1
/usr/local/bin/warp-go --register --config=/usr/local/bin/warp.conf >/dev/null 2>&1
done
mtuwarp
sed -i "s/MTU.*/MTU = $MTU/g" /usr/local/bin/warp.conf
cat > /lib/systemd/system/warp-go.service << EOF
[Unit]
Description=warp-go service
After=network.target
Documentation=https://gitlab.com/ProjectWARP/warp-go
[Service]
WorkingDirectory=/root/
ExecStart=/usr/local/bin/warp-go --config=/usr/local/bin/warp.conf
Environment="LOG_LEVEL=verbose"
RemainAfterExit=yes
Restart=always
[Install]
WantedBy=multi-user.target
EOF
ABC
warpip
systemctl daemon-reload
systemctl enable warp-go
systemctl start warp-go
kill -15 $(pgrep warp-go) >/dev/null 2>&1 && sleep 2
systemctl restart warp-go
systemctl enable warp-go
systemctl start warp-go
checkwgcf
if [[ $wgcfv4 =~ on|plus || $wgcfv6 =~ on|plus ]]; then
green "恭喜！warp的IP获取成功！" && dns
else
CheckWARP
fi
ShowWGCF && WGCFmenu && lncf
}

warpinscha(){
yellow "提示：VPS的本地出站IP将被你选择的warp的IP所接管，如VPS本地无该出站IP，则被另外生成warp的IP所接管"
echo
yellow "如果你什么都不懂，回车便是！！！"
echo
green "1. 安装/切换WARP单栈IPV4（回车默认）"
green "2. 安装/切换WARP单栈IPV6"
green "3. 安装/切换WARP双栈IPV4+IPV6"
readp "\n请选择：" wgcfwarp
if [ -z "${wgcfwarp}" ] || [ $wgcfwarp == "1" ];then
WGCFv4
elif [ $wgcfwarp == "2" ];then
WGCFv6
elif [ $wgcfwarp == "3" ];then
WGCFv4v6
else 
red "输入错误，请重新选择" && warpinscha
fi
echo
} 

warprefresh(){
wget -N https://gitlab.com/rwkgyg/CFwarp/raw/main/wp-plus.py 
sed -i "27 s/[(][^)]*[)]//g" wp-plus.py
readp "客户端配置ID(36个字符)：" ID
sed -i "27 s/input/'$ID'/" wp-plus.py
python3 wp-plus.py
}

WARPup(){
endpost(){
kill -15 $(pgrep warp-go) >/dev/null 2>&1 && sleep 2
v4v6
allowips=$(cat /usr/local/bin/warp.conf | grep AllowedIPs)
if [[ -n $v4 && -n $v6 ]]; then
endpoint=$wgo4
post=$wgo8
elif [[ -n $v6 && -z $v4 ]]; then
endpoint=$wgo5
[[ -n $(ip route get 1.1.1.1 2>/dev/null | grep -oP 'src \K\S+') ]] && post=$wgo8 || post=$wgo7
elif [[ -z $v6 && -n $v4 ]]; then
endpoint=$wgo4
post=$wgo6
fi
}

freewarp(){
endpost
red "当前执行：申请WARP普通账户"
rm -rf /usr/local/bin/warp.conf /usr/local/bin/warp.conf.bak /usr/local/bin/warpplus.log
until [[ -e /usr/local/bin/warp.conf ]]; do
yellow "正在申请WARP普通账户，请稍等" && sleep 1
/usr/local/bin/warp-go --register --config=/usr/local/bin/warp.conf
mtuwarp
sed -i "s/MTU.*/MTU = $MTU/g" /usr/local/bin/warp.conf
done
sed -i "s#.*AllowedIPs.*#$allowips#g" /usr/local/bin/warp.conf
echo $endpoint | sh
echo $post | sh
kill -15 $(pgrep warp-go) >/dev/null 2>&1 && sleep 2
systemctl restart warp-go
systemctl enable warp-go
systemctl start warp-go
CheckWARP && ShowWGCF && WGCFmenu
}

[[ ! $(type -P warp-go) ]] && red "未安装WARP" && bash CFwarp.sh
green "1. WARP普通账户（无限流量）"
green "2. WARP+账户（有限流量）"
green "3. WARP Teams (Zero Trust)团队账户（无限流量）"
readp "请选择想要切换的账户类型：" warpup
if [[ $warpup == 1 ]]; then
freewarp
fi

if [[ $warpup == 2 ]]; then
green "请复制手机WARP客户端WARP+状态下的按键许可证秘钥 或 网络分享的秘钥（26个字符），随意输入有机率获得1G流量WARP+账户"
readp "请输入升级WARP+密钥" ID
readp "设备名称重命名(直接回车随机命名): " dname
if [[ -z $ID ]]; then
red "未输入内容" && WARPup
fi
if [[ -z $dname ]]; then
dname=`date +%s%N |md5sum | cut -c 1-4`
fi
green "设备名称为 $dname"
i=0
while [ $i -le 4 ]; do let i++
endpost
yellow "共执行5次，第$i次升级WARP+账户中……" 
/usr/local/bin/warp-go --register --config=/usr/local/bin/warp.conf --license=$ID --device-name=$dname
sed -i "s#.*AllowedIPs.*#$allowips#g" /usr/local/bin/warp.conf
echo $endpoint | sh
echo $post | sh
warpip
kill -15 $(pgrep warp-go) >/dev/null 2>&1 && sleep 2
systemctl restart warp-go
systemctl enable warp-go
systemctl start warp-go
checkwgcf
if [[ $wgcfv4 = plus || $wgcfv6 = plus ]]; then
rm -rf /usr/local/bin/warp.conf.bak /usr/local/bin/warpplus.log
echo "$dname" >> /usr/local/bin/warpplus.log && echo "$ID" >> /usr/local/bin/warpplus.log
green "WARP+ 账户升级成功！" && ShowWGCF && WGCFmenu && break
else
red "WARP+账户升级失败！" && sleep 1
fi
done
if [[ ! $wgcfv4 = plus && ! $wgcfv6 = plus ]]; then
green "建议如下："
yellow "1. 检查1.1.1.1 APP中的WARP+账户或网络分享的秘钥是否有流量"
yellow "2. 检查当前WARP许可证密钥绑定的设备超过5台，请进入手机端进行设备移除再尝试升级WARP+账户" && sleep 2
echo
freewarp
fi
fi
    
if [[ $warpup == 3 ]]; then
green "Zero Trust团队Token获取地址：https://web--public--warp-team-api--coia-mfs4.code.run/"
readp "请输入团队账户Token: " token
i=0
while [ $i -le 4 ]; do let i++
yellow "共执行5次，第$i次升级WARP Teams账户中……"
/usr/local/bin/warp-go --register --config=/usr/local/bin/warp.conf.bak --team-config "$token"
sed -i "2s#.*#$(sed -ne 2p /usr/local/bin/warp.conf.bak)#;3s#.*#$(sed -ne 3p /usr/local/bin/warp.conf.bak)#" /usr/local/bin/warp.conf >/dev/null 2>&1
sed -i "4s#.*#$(sed -ne 4p /usr/local/bin/warp.conf.bak)#;5s#.*#$(sed -ne 5p /usr/local/bin/warp.conf.bak)#" /usr/local/bin/warp.conf >/dev/null 2>&1
warpip
kill -15 $(pgrep warp-go) >/dev/null 2>&1 && sleep 2
systemctl restart warp-go
systemctl enable warp-go
systemctl start warp-go
checkwgcf
if [[ $wgcfv4 = plus || $wgcfv6 = plus ]]; then
rm -rf /usr/local/bin/warp.conf.bak /usr/local/bin/warpplus.log
green "WARP Teams账户升级成功！" && ShowWGCF && WGCFmenu && break
else
red "WARP Teams账户升级失败！" && sleep 1
fi
done
if [[ ! $wgcfv4 = plus && ! $wgcfv6 = plus ]]; then
freewarp
fi
fi
}

WARPonoff(){
[[ ! $(type -P warp-go) ]] && red "WARP未安装，建议重新安装" && bash CFwarp.sh
readp "1. 关闭WARP功能\n2. 开启/重启WARP功能\n0. 返回上一层\n 请选择：" unwp
if [ $unwp == "1" ]; then
kill -15 $(pgrep warp-go) >/dev/null 2>&1 && sleep 2
systemctl disable warp-go
checkwgcf 
[[ ! $wgcfv4 =~ on|plus && ! $wgcfv6 =~ on|plus ]] && green "关闭WARP成功" || red "关闭WARP失败"
ShowWGCF && WGCFmenu
elif [ $unwp == "2" ]; then
kill -15 $(pgrep warp-go) >/dev/null 2>&1 && sleep 2
systemctl restart warp-go
systemctl enable warp-go
systemctl start warp-go
checkwgcf 
[[ $wgcfv4 =~ on|plus || $wgcfv6 =~ on|plus ]] && green "开启WARP成功" || red "开启WARP失败"
ShowWGCF && WGCFmenu
else
bash CFwarp.sh
fi
}

cwg(){
systemctl disable warp-go >/dev/null 2>&1
kill -15 $(pgrep warp-go) >/dev/null 2>&1 
chattr -i /etc/resolv.conf >/dev/null 2>&1
sed -i '/^precedence ::ffff:0:0\/96  100/d;/^label 2002::\/16   2/d' /etc/gai.conf 2>/dev/null
rm -rf /usr/local/bin/warp-go /usr/local/bin/warpplus.log /usr/local/bin/warp.conf /usr/local/bin/wgwarp.conf /usr/local/bin/sbwarp.json /usr/bin/warp-go /lib/systemd/system/warp-go.service
}
WARPun(){
ab="1.仅卸载warp\n2.仅卸载socks5-warp\n3.彻底卸载warp（1+2）\n 请选择："
readp "$ab" cd
case "$cd" in
1 ) cwg && green "warp卸载完成" && ShowWGCF && WGCFmenu;;
2 ) cso && green "socks5-warp卸载完成" && ShowSOCKS5 && S5menu;;
3 ) cwg && rm -rf /root/warpip && cso && green "warp与socks5-warp都已卸载完成" && ShowWGCF;ShowSOCKS5;IP_Status_menu;;
esac
}

UPwpyg(){
if [[ ! $(type -P warp-go) && ! $(type -P warp-cli) ]] && [[ ! -f '/root/CFwarp.sh' ]]; then
red "未正常安装CFwarp脚本!" && exit
fi
upcfwarp
}

changewarp(){
cwg && ONEWGCFWARP
}

upwarpgo(){
kill -15 $(pgrep warp-go) >/dev/null 2>&1 && sleep 2
wget -N --no-check-certificate https://gitlab.com/rwkgyg/CFwarp/-/raw/main/warp-go_1.0.8_linux_${cpu} -O /usr/local/bin/warp-go && chmod +x /usr/local/bin/warp-go
systemctl restart warp-go
systemctl enable warp-go
systemctl start warp-go
loVERSION="$(/usr/local/bin/warp-go -v | sed -n 1p | awk '{print $1}' | awk -F"/" '{print $NF}')"
green " 当前 WARP-GO 已安装内核版本号：${loVERSION} ，已是最新版本"
}

WGproxy(){
if [[ ! $(type -P warp-go) ]]; then
wget -N https://gitlab.com/rwkgyg/CFwarp/-/raw/main/warp-go_1.0.8_linux_${cpu} -O /usr/local/bin/warp-go && chmod +x /usr/local/bin/warp-go
until [[ -e /usr/local/bin/warp.conf ]]; do
yellow "正在申请WARP普通账户，请稍等" && sleep 1
/usr/local/bin/warp-go --register --config=/usr/local/bin/warp.conf
mtuwarp
sed -i "s/MTU.*/MTU = $MTU/g" /usr/local/bin/warp.conf
done
fi
/usr/local/bin/warp-go --config=/usr/local/bin/warp.conf --export-wireguard=/usr/local/bin/wgwarp.conf
sed -i '/Endpoint/d' /usr/local/bin/wgwarp.conf
sed -i "11a Endpoint = $endpoint" /usr/local/bin/wgwarp.conf
/usr/local/bin/warp-go --config=/usr/local/bin/warp.conf --export-singbox=/usr/local/bin/sbwarp.json
green "当前Wireguard-warp配置参数如下" && sleep 1
white "$(cat /usr/local/bin/wgwarp.conf)\n"
yellow "注意："
yellow "一、此配置与当前VPS无任何关联，根据各平台本地网络就近原则来判定CF的IP地区\n"
yellow "二、此配置可全部复制用于Wireguard客户端，个别参数可复制用于Xray协议的Wireguard-warp出站配置\n"
yellow "三、此配置中Endpoint的IP端口：$endpoint，为当前VPS平台warp优选测试结果"
yellow "   如应用于其他各平台，建议将 $endpoint 替换为其他平台本地网络测试warp优选后的IP端口\n"
yellow "四、此配置中PrivateKey、Address的V6地址、reserved(可选)，三个参数相互绑定关联"
yellow "   当前VPS平台的reserved参数值：$(grep -o '"reserved":\[[^]]*\]' /usr/local/bin/sbwarp.json)\n"
green "当前Wireguard节点二维码分享链接如下" && sleep 1
qrencode -t ansiutf8 < /usr/local/bin/wgwarp.conf
echo
#green "当前Sing-box出站配置文件如下" && sleep 1
#yellow "$(cat /usr/local/bin/sbwarp.json | python3 -mjson.tool)"
}

start_menu(){
ShowWGCF;ShowSOCKS5
clear
green "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"           
echo -e "${bblue} ░██     ░██      ░██ ██ ██         ░█${plain}█   ░██     ░██   ░██     ░█${red}█   ░██${plain}  "
echo -e "${bblue}  ░██   ░██      ░██    ░░██${plain}        ░██  ░██      ░██  ░██${red}      ░██  ░██${plain}   "
echo -e "${bblue}   ░██ ░██      ░██ ${plain}                ░██ ██        ░██ █${red}█        ░██ ██  ${plain}   "
echo -e "${bblue}     ░██        ░${plain}██    ░██ ██       ░██ ██        ░█${red}█ ██        ░██ ██  ${plain}  "
echo -e "${bblue}     ░██ ${plain}        ░██    ░░██        ░██ ░██       ░${red}██ ░██       ░██ ░██ ${plain}  "
echo -e "${bblue}     ░█${plain}█          ░██ ██ ██         ░██  ░░${red}██     ░██  ░░██     ░██  ░░██ ${plain}  "
echo
white "甬哥Github项目  ：github.com/yonggekkk"
white "甬哥blogger博客 ：ygkkk.blogspot.com"
white "甬哥YouTube频道 ：www.youtube.com/@ygkkk"
green "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
yellow " 任意选择适合自己的warp现实方案（选项1、2、3，可单选，可多选共存）"
yellow " 进入脚本快捷方式：cf"
white " ================================================================="
green "  1. 方案一：安装/切换WARP-GO"
[[ $cpu != amd64* ]] && red "  2. 提示：当前VPS的CPU并非AMD64架构，目前不支持安装Socks5-WARP" || green "  2. 方案二：安装Socks5-WARP"
green "  3. 方案三：显示Xray-WireGuard-WARP代理配置文件、二维码"
green "  4. 卸载WARP"
white " -----------------------------------------------------------------"
green "  5. 关闭、开启/重启WARP"
green "  6. WARP刷刷刷选项：WARP+流量……"
green "  7. WARP三类账户升级/切换(WARP/WARP+/WARP Teams)"
green "  8. 更新CFwarp安装脚本"
green "  9. 更新WARP-GO内核"
green " 10. 卸载WARP-GO切换为WGCF-WARP内核"
green "  0. 退出脚本 "
red "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
if [ "${wpygV}" = "${remoteV}" ]; then
echo -e " 当前 CFwarp 脚本版本号：${bblue}${wpygV}${plain} 重置版第四版 ，已是最新版本\n"
else
echo -e " 当前 CFwarp 脚本版本号：${bblue}${wpygV}${plain}"
echo -e " 检测到最新 CFwarp 脚本版本号：${yellow}${remoteV}${plain}"
echo -e " ${yellow}$(wget -qO- https://gitlab.com/rwkgyg/CFwarp/raw/main/version/warpV)${plain}"
echo -e " 可选择8进行更新\n"
fi
if [[ $(type -P warp-go) ]] && [[ -f '/root/CFwarp.sh' ]]; then
loVERSION="$(/usr/local/bin/warp-go -v | sed -n 1p | awk '{print $1}' | awk -F"/" '{print $NF}')"
wgVERSION="$(wget -qO- https://gitlab.com/rwkgyg/CFwarp/raw/main/version/warpgoV)"
if [ "${loVERSION}" = "${wgVERSION}" ]; then
echo -e " 当前 WARP-GO 已安装内核版本号：${bblue}${loVERSION}${plain} ，已是最新版本"
else
echo -e " 当前 WARP-GO 已安装内核版本号：${bblue}${loVERSION}${plain}"
echo -e " 检测到最新 WARP-GO 内核版本号：${yellow}${wgVERSION}${plain} ，可选择9进行更新"
fi
fi
red "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
white " VPS系统信息如下："
white " VPS操作系统: $(blue "$op") \c" && white " 内核版本: $(blue "$version") \c" && white " CPU架构 : $(blue "$cpu") \c" && white " 虚拟化类型: $(blue "$vi")"
IP_Status_menu
echo
readp " 请输入数字:" Input
case "$Input" in     
 1 ) warpinscha;;
 2 ) [[ $cpu = amd64* ]] && SOCKS5ins || bash CFwarp.sh;;
 3 ) WGproxy;;
 4 ) WARPun && uncf ;;
 5 ) WARPonoff;;
 6 ) warprefresh;;
 7 ) WARPup;;
 8 ) UPwpyg;;
 9 ) upwarpgo;;
 10 ) changewarp;;
 * ) exit
esac
}
if [ $# == 0 ]; then
warpwgcf
bit=`uname -m`
[[ $bit = aarch64 ]] && cpu=arm64
if [[ $bit = x86_64 ]]; then
amdv=$(cat /proc/cpuinfo | grep flags | head -n 1 | cut -d: -f2)
case "$amdv" in
*avx512*) cpu=amd64v4;;
*avx2*) cpu=amd64v3;;
*sse3*) cpu=amd64v2;;
*) cpu=amd64;;
esac
fi
start_menu
fi
}

ONEWGCFWARP(){
yellow "\n 请稍等……" && sleep 2
ud4='sed -i "7 s/^/PostUp = ip -4 rule add from $(ip route get 162.159.192.1 | grep -oP '"'src \K\S+') lookup main\n/"'" /etc/wireguard/wgcf.conf && sed -i "7 s/^/PostDown = ip -4 rule delete from $(ip route get 162.159.192.1 | grep -oP '"'src \K\S+') lookup main\n/"'" /etc/wireguard/wgcf.conf'
ud6='sed -i "7 s/^/PostUp = ip -6 rule add from $(ip route get 2606:4700:d0::a29f:c001 | grep -oP '"'src \K\S+') lookup main\n/"'" /etc/wireguard/wgcf.conf && sed -i "7 s/^/PostDown = ip -6 rule delete from $(ip route get 2606:4700:d0::a29f:c001 | grep -oP '"'src \K\S+') lookup main\n/"'" /etc/wireguard/wgcf.conf'
ud4ud6='sed -i "7 s/^/PostUp = ip -4 rule add from $(ip route get 162.159.192.1 | grep -oP '"'src \K\S+') lookup main\n/"'" /etc/wireguard/wgcf.conf && sed -i "7 s/^/PostDown = ip -4 rule delete from $(ip route get 162.159.192.1 | grep -oP '"'src \K\S+') lookup main\n/"'" /etc/wireguard/wgcf.conf && sed -i "7 s/^/PostUp = ip -6 rule add from $(ip route get 2606:4700:d0::a29f:c001 | grep -oP '"'src \K\S+') lookup main\n/"'" /etc/wireguard/wgcf.conf && sed -i "7 s/^/PostDown = ip -6 rule delete from $(ip route get 2606:4700:d0::a29f:c001 | grep -oP '"'src \K\S+') lookup main\n/"'" /etc/wireguard/wgcf.conf'
c1="sed -i '/0\.0\.0\.0\/0/d' /etc/wireguard/wgcf.conf"
c2="sed -i '/\:\:\/0/d' /etc/wireguard/wgcf.conf"
c3="sed -i "s/engage.cloudflareclient.com:2408/$endpoint/g" /etc/wireguard/wgcf.conf"
c4="sed -i "s/engage.cloudflareclient.com:2408/$endpoint/g" /etc/wireguard/wgcf.conf"
c5="sed -i 's/1.1.1.1/8.8.8.8,2001:4860:4860::8888/g' /etc/wireguard/wgcf.conf"
c6="sed -i 's/1.1.1.1/2001:4860:4860::8888,8.8.8.8/g' /etc/wireguard/wgcf.conf"

ShowWGCF(){
UA_Browser="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/80.0.3987.87 Safari/537.36"
v4v6
warppflow=$((`grep -oP '"quota":\K\d+' <<< $(curl -sm4 "https://api.cloudflareclient.com/v0a884/reg/$(grep 'device_id' /etc/wireguard/wgcf-account.toml 2>/dev/null | cut -d \' -f2)" -H "User-Agent: okhttp/3.12.1" -H "Authorization: Bearer $(grep 'access_token' /etc/wireguard/wgcf-account.toml 2>/dev/null | cut -d \' -f2)")`))
flow=`echo "scale=2; $warppflow/1000000000" | bc`
[[ -e /etc/wireguard/wgcf+p.log ]] && cfplus="WARP+普通账户(有限WARP+流量：$flow GB)，设备名称：$(grep -s 'Device name' /etc/wireguard/wgcf+p.log | awk '{ print $NF }')" || cfplus="WARP+Teams账户(无限WARP+流量)"
if [[ -n $v4 ]]; then
nf4
[[ $(curl -s4S https://chat.openai.com/ -I | grep "text/plain") != "" ]] && chat='遗憾，当前IP无法访问ChatGPT官网服务' || chat='恭喜，当前IP支持访问ChatGPT官网服务'
wgcfv4=$(curl -s4 https://www.cloudflare.com/cdn-cgi/trace -k | grep warp | cut -d= -f2) 
isp4a=`curl -sm6 --user-agent "${UA_Browser}" http://ip-api.com/json/$v4?lang=zh-CN -k | cut -f13 -d ":" | cut -f2 -d '"'`
isp4b=`curl -sm6 --user-agent "${UA_Browser}" https://api.ip.sb/geoip/$v4 -k | awk -F "isp" '{print $2}' | awk -F "offset" '{print $1}' | sed "s/[,\":]//g"`
[[ -n $isp4a ]] && isp4=$isp4a || isp4=$isp4b
nonf=$(curl -sm6 --user-agent "${UA_Browser}" http://ip-api.com/json/$v4?lang=zh-CN -k | cut -f2 -d"," | cut -f4 -d '"')
#sunf=$(./nf | awk '{print $1}' | sed -n '4p')
#snnf=$(curl -s4m6 ip.p3terx.com -k | sed -n 2p | awk '{print $3}')
country=$nonf
case ${wgcfv4} in 
plus) 
WARPIPv4Status=$(white "WARP+状态：\c" ; rred "运行中，$cfplus" ; white " 服务商 Cloudflare 获取IPV4地址：\c" ; rred "$v4  $country" ; white " 奈飞NF解锁情况：\c" ; rred "$NF" ; white " ChatGPT解锁情况：\c" ; rred "$chat");;  
on) 
WARPIPv4Status=$(white "WARP状态：\c" ; green "运行中，WARP普通账户(无限WARP流量)" ; white " 服务商 Cloudflare 获取IPV4地址：\c" ; green "$v4  $country" ; white " 奈飞NF解锁情况：\c" ; green "$NF" ; white " ChatGPT解锁情况：\c" ; green "$chat");;
off) 
WARPIPv4Status=$(white "WARP状态：\c" ; yellow "关闭中" ; white " 服务商 $isp4 获取IPV4地址：\c" ; yellow "$v4  $country" ; white " 奈飞NF解锁情况：\c" ; yellow "$NF" ; white " ChatGPT解锁情况：\c" ; yellow "$chat");; 
esac 
else
WARPIPv4Status=$(white "IPV4状态：\c" ; red "不存在IPV4地址 ")
fi 
if [[ -n $v6 ]]; then
nf6
[[ $(curl -s6S https://chat.openai.com/ -I | grep "text/plain") != "" ]] && chat='遗憾，当前IP无法访问ChatGPT官网服务' || chat='恭喜，当前IP支持访问ChatGPT官网服务'
wgcfv6=$(curl -s6 https://www.cloudflare.com/cdn-cgi/trace -k | grep warp | cut -d= -f2) 
isp6a=`curl -sm6 --user-agent "${UA_Browser}" http://ip-api.com/json/$v6?lang=zh-CN -k | cut -f13 -d":" | cut -f2 -d '"'`
isp6b=`curl -sm6 --user-agent "${UA_Browser}" https://api.ip.sb/geoip/$v6 -k | awk -F "isp" '{print $2}' | awk -F "offset" '{print $1}' | sed "s/[,\":]//g"`
[[ -n $isp6a ]] && isp6=$isp6a || isp6=$isp6b
nonf=$(curl -sm6 --user-agent "${UA_Browser}" http://ip-api.com/json/$v6?lang=zh-CN -k | cut -f2 -d"," | cut -f4 -d '"')
#sunf=$(./nf | awk '{print $1}' | sed -n '8p')
#snnf=$(curl -s6m6 ip.p3terx.com -k | sed -n 2p | awk '{print $3}')
country=$nonf
case ${wgcfv6} in 
plus) 
WARPIPv6Status=$(white "WARP+状态：\c" ; rred "运行中，$cfplus" ; white " 服务商 Cloudflare 获取IPV6地址：\c" ; rred "$v6  $country" ; white " 奈飞NF解锁情况：\c" ; rred "$NF" ; white " ChatGPT解锁情况：\c" ; rred "$chat");;  
on) 
WARPIPv6Status=$(white "WARP状态：\c" ; green "运行中，WARP普通账户(无限WARP流量)" ; white " 服务商 Cloudflare 获取IPV6地址：\c" ; green "$v6  $country" ; white " 奈飞NF解锁情况：\c" ; green "$NF" ; white " ChatGPT解锁情况：\c" ; green "$chat");;
off) 
WARPIPv6Status=$(white "WARP状态：\c" ; yellow "关闭中" ; white " 服务商 $isp6 获取IPV6地址：\c" ; yellow "$v6  $country" ; white " 奈飞NF解锁情况：\c" ; yellow "$NF" ; white " ChatGPT解锁情况：\c" ; yellow "$chat");;
esac 
else
WARPIPv6Status=$(white "IPV6状态：\c" ; red "不存在IPV6地址 ")
fi 
}

STOPwgcf(){
if [[ $(type -P warp-cli) ]]; then
red "已安装Socks5-WARP(+)，不支持当前选择的wgcf-warp安装方案" 
systemctl restart wg-quick@wgcf ; bash CFwarp.sh
fi
}

fawgcf(){
rm -f /etc/wireguard/wgcf+p.log
ID=$(cat /etc/wireguard/buckup-account.toml | grep license_key | awk '{print $3}')
sed -i "s/license_key.*/license_key = $ID/g" /etc/wireguard/wgcf-account.toml
cd /etc/wireguard && wgcf update >/dev/null 2>&1
wgcf generate >/dev/null 2>&1 && cd
sed -i "2s#.*#$(sed -ne 2p /etc/wireguard/wgcf-profile.conf)#;4s#.*#$(sed -ne 4p /etc/wireguard/wgcf-profile.conf)#" /etc/wireguard/wgcf.conf
CheckWARP
ShowWGCF && WGCFmenu
}

WGproxy(){
[[ ! $(type -P wg-quick) ]] && red "未安装Wgcf-WARP，安装好wgcf-warp才能执行" && sleep 3 && bash CFwarp.sh
cp -f /etc/wireguard/wgcf.conf /etc/wireguard/wgproxy.conf >/dev/null 2>&1
sed -i '/PostUp/d;/PostDown/d;/AllowedIPs/d;/Endpoint/d' /etc/wireguard/wgproxy.conf
sed -i "8a AllowedIPs = 0.0.0.0\/0\nAllowedIPs = ::\/0\n" /etc/wireguard/wgproxy.conf
sed -i "10a Endpoint = $endpoint" /etc/wireguard/wgproxy.conf
green "当前wireguard客户端配置文件wgproxy.conf内容如下，保存到 /etc/wireguard/wgproxy.conf\n" && sleep 2
white "$(cat /etc/wireguard/wgproxy.conf)\n"
yellow "注意："
yellow "一、此配置与当前VPS无任何关联，根据各平台本地网络就近原则来判定CF的IP地区\n"
yellow "二、此配置可全部复制用于Wireguard客户端\n"
yellow "三、此配置中Endpoint的IP端口：$endpoint，为当前VPS平台warp优选测试结果"
yellow "   如应用于其他各平台，建议将 $endpoint 替换为其他平台本地网络测试warp优选后的IP端口\n"
yellow "四、此配置中PrivateKey与Address的V6地址，这两个参数相互绑定关联\n"
green "当前wireguard节点二维码分享链接如下" && sleep 2
qrencode -t ansiutf8 < /etc/wireguard/wgproxy.conf
}

ABC(){
echo $ABC1 | sh
echo $ABC2 | sh
echo $ABC3 | sh
echo $ABC4 | sh
echo $ABC5 | sh
}

conf(){
rm -rf /etc/wireguard/wgcf.conf
cp -f /etc/wireguard/wgcf-profile.conf /etc/wireguard/wgcf.conf >/dev/null 2>&1
}

nat4(){
[[ -n $(ip route get 162.159.192.1 2>/dev/null | grep -oP 'src \K\S+') ]] && ABC4=$ud4 || ABC4=echo
}

WGCFv4(){
yellow "稍等3秒，检测VPS内warp环境"
docker && checkwgcf
if [[ ! $wgcfv4 =~ on|plus && ! $wgcfv6 =~ on|plus ]]; then
v4v6
if [[ -n $v4 && -n $v6 ]]; then
green "当前原生v4+v6双栈vps首次安装wgcf-warp\n现添加IPV4单栈wgcf-warp模式" && sleep 2
ABC1=$c5 && ABC2=$c2 && ABC3=$ud4 && ABC4=$c3 && WGCFins
fi
if [[ -n $v6 && -z $v4 ]]; then
green "当前原生v6单栈vps首次安装wgcf-warp\n现添加IPV4单栈wgcf-warp模式" && sleep 2
ABC1=$c5 && ABC2=$c4 && ABC3=$c2 && nat4 && WGCFins
fi
if [[ -z $v6 && -n $v4 ]]; then
green "当前原生v4单栈vps首次安装wgcf-warp\n现添加IPV4单栈wgcf-warp模式" && sleep 2
ABC1=$c5 && ABC2=$c2 && ABC3=$c3 && ABC4=$ud4 && WGCFins
fi
first4
else
wg-quick down wgcf >/dev/null 2>&1
sleep 1 && v4v6
if [[ -n $v4 && -n $v6 ]]; then
green "当前原生v4+v6双栈vps已安装wgcf-warp\n现快速切换IPV4单栈wgcf-warp模式" && sleep 2
conf && ABC1=$c5 && ABC2=$c2 && ABC3=$ud4 && ABC4=$c3 && ABC
fi
if [[ -n $v6 && -z $v4 ]]; then
green "当前原生v6单栈vps已安装wgcf-warp\n现快速切换IPV4单栈wgcf-warp模式" && sleep 2
conf && ABC1=$c5 && ABC2=$c4 && ABC3=$c2 && nat4 && ABC
fi
if [[ -z $v6 && -n $v4 ]]; then
green "当前原生v4单栈vps已安装wgcf-warp\n现快速切换IPV4单栈wgcf-warp模式" && sleep 2
conf && ABC1=$c5 && ABC2=$c2 && ABC3=$c3 && ABC4=$ud4 && ABC
fi
CheckWARP && first4 && ShowWGCF && WGCFmenu
fi
}

WGCFv6(){
yellow "稍等3秒，检测VPS内warp环境"
docker && checkwgcf
if [[ ! $wgcfv4 =~ on|plus && ! $wgcfv6 =~ on|plus ]]; then
v4v6
if [[ -n $v4 && -n $v6 ]]; then
green "当前原生v4+v6双栈vps首次安装wgcf-warp\n现添加IPV6单栈wgcf-warp模式" && sleep 2
ABC1=$c5 && ABC2=$c1 && ABC3=$ud6 && ABC4=$c3 && WGCFins
fi
if [[ -n $v6 && -z $v4 ]]; then
green "当前原生v6单栈vps首次安装wgcf-warp\n现添加IPV6单栈wgcf-warp模式(无IPV4！！！)" && sleep 2
ABC1=$c6 && ABC2=$c1 && ABC3=$c4 && nat4 && ABC5=$ud6 && WGCFins
fi
if [[ -z $v6 && -n $v4 ]]; then
green "当前原生v4单栈vps首次安装wgcf-warp\n现添加IPV6单栈wgcf-warp模式" && sleep 2
ABC1=$c5 && ABC2=$c3 && ABC3=$c1 && WGCFins
fi
else
wg-quick down wgcf >/dev/null 2>&1
sleep 1 && v4v6
if [[ -n $v4 && -n $v6 ]]; then
green "当前原生v4+v6双栈vps已安装wgcf-warp\n现快速切换IPV6单栈wgcf-warp模式" && sleep 2
conf && ABC1=$c5 && ABC2=$c1 && ABC3=$ud6 && ABC4=$c3 && ABC
fi
if [[ -n $v6 && -z $v4 ]]; then
green "当前原生v6单栈vps已安装wgcf-warp\n现快速切换IPV6单栈wgcf-warp模式(无IPV4！！！)" && sleep 2
conf && ABC1=$c6 && ABC2=$c1 && ABC3=$c4 && nat4 && ABC5=$ud6 && ABC
fi
if [[ -z $v6 && -n $v4 ]]; then
green "当前原生v4单栈vps已安装wgcf-warp\n现快速切换IPV6单栈wgcf-warp模式" && sleep 2
conf && ABC1=$c5 && ABC2=$c3 && ABC3=$c1 && ABC
fi
CheckWARP && first4 && ShowWGCF && WGCFmenu
fi
}

WGCFv4v6(){
yellow "稍等3秒，检测VPS内warp环境"
docker && checkwgcf
if [[ ! $wgcfv4 =~ on|plus && ! $wgcfv6 =~ on|plus ]]; then
v4v6
if [[ -n $v4 && -n $v6 ]]; then
green "当前原生v4+v6双栈vps首次安装wgcf-warp\n现添加IPV4+IPV6双栈wgcf-warp模式" && sleep 2
ABC1=$c5 && ABC2=$ud4ud6 && ABC3=$c3 && WGCFins
fi
if [[ -n $v6 && -z $v4 ]]; then
green "当前原生v6单栈vps首次安装wgcf-warp\n现添加IPV4+IPV6双栈wgcf-warp模式" && sleep 2
ABC1=$c5 && ABC2=$c4 && ABC3=$ud6 && nat4 && WGCFins
fi
if [[ -z $v6 && -n $v4 ]]; then
green "当前原生v4单栈vps首次安装wgcf-warp\n现添加IPV4+IPV6双栈wgcf-warp模式" && sleep 2
ABC1=$c5 && ABC2=$c3 && ABC3=$ud4 && WGCFins
fi
else
wg-quick down wgcf >/dev/null 2>&1
sleep 1 && v4v6
if [[ -n $v4 && -n $v6 ]]; then
green "当前原生v4+v6双栈vps已安装wgcf-warp\n现快速切换IPV4+IPV6双栈wgcf-warp模式" && sleep 2
conf && ABC1=$c5 && ABC2=$ud4ud6 && ABC3=$c3 && ABC
fi
if [[ -n $v6 && -z $v4 ]]; then
green "当前原生v6单栈vps已安装wgcf-warp\n现快速切换IPV4+IPV6双栈wgcf-warp模式" && sleep 2
conf && ABC1=$c5 && ABC2=$c4 && ABC3=$ud6 && nat4 && ABC
fi
if [[ -z $v6 && -n $v4 ]]; then
green "当前原生v4单栈vps已安装wgcf-warp\n现快速切换IPV4+IPV6双栈wgcf-warp模式" && sleep 2
conf && ABC1=$c5 && ABC2=$c3 && ABC3=$ud4 && ABC
fi
CheckWARP && first4 && ShowWGCF && WGCFmenu
fi
}

CheckWARP(){
i=0
wg-quick down wgcf >/dev/null 2>&1
while [ $i -le 9 ]; do let i++
yellow "共执行10次，第$i次获取warp的IP中……"
systemctl restart wg-quick@wgcf >/dev/null 2>&1
checkwgcf
[[ $wgcfv4 =~ on|plus || $wgcfv6 =~ on|plus ]] && green "恭喜！warp的IP获取成功！" && break || red "遗憾！warp的IP获取失败"
done
checkwgcf
if [[ ! $wgcfv4 =~ on|plus && ! $wgcfv6 =~ on|plus ]]; then
yellow "安装WARP失败，还原VPS，卸载Wgcf-WARP组件中……"
cwg && rm -rf /root/warpip
echo
[[ $release = Centos && ${vsid} -lt 7 ]] && yellow "当前系统版本号：Centos $vsid \n建议使用 Centos 7 以上系统 " 
[[ $release = Ubuntu && ${vsid} -lt 18 ]] && yellow "当前系统版本号：Ubuntu $vsid \n建议使用 Ubuntu 18 以上系统 " 
[[ $release = Debian && ${vsid} -lt 10 ]] && yellow "当前系统版本号：Debian $vsid \n建议使用 Debian 10 以上系统 "
red "可以使用方案二或方案三"
red "建议选择WARP-GO核心来安装WARP方案一"
exit
else 
green "ok"
fi
xyz(){
att
[[ -e /root/check.sh ]] && screen -S aw -X quit ; screen -UdmS aw bash -c '/bin/bash /root/check.sh'
[[ -e /root/WARP-CR.sh ]] && screen -S cr -X quit ; screen -UdmS cr bash -c '/bin/bash /root/WARP-CR.sh'
[[ -e /root/WARP-CP.sh ]] && screen -S cp -X quit ; screen -UdmS cp bash -c '/bin/bash /root/WARP-CP.sh'
if [[ -e /root/WARP-UP.sh ]]; then
screen -S up -X quit ; screen -UdmS up bash -c '/bin/bash /root/WARP-UP.sh'
else
green "安装warp在线监测守护进程"
cat>/root/WARP-UP.sh<<-\EOF
#!/bin/bash
red(){ echo -e "\033[31m\033[01m$1\033[0m";}
green(){ echo -e "\033[32m\033[01m$1\033[0m";}
checkwgcf(){
wgcfv6=$(curl -s6m6 https://www.cloudflare.com/cdn-cgi/trace -k | grep warp | cut -d= -f2) 
wgcfv4=$(curl -s4m6 https://www.cloudflare.com/cdn-cgi/trace -k | grep warp | cut -d= -f2) 
}
warpclose(){
wg-quick down wgcf >/dev/null 2>&1 ; systemctl stop wg-quick@wgcf >/dev/null 2>&1 ; systemctl disable wg-quick@wgcf >/dev/null 2>&1
}
warpopen(){
wg-quick down wgcf >/dev/null 2>&1 ; systemctl enable wg-quick@wgcf >/dev/null 2>&1 ; systemctl start wg-quick@wgcf >/dev/null 2>&1 ; systemctl restart wg-quick@wgcf >/dev/null 2>&1
}
warpre(){
i=0
while [ $i -le 4 ]; do let i++
warpopen
checkwgcf
[[ $wgcfv4 =~ on|plus || $wgcfv6 =~ on|plus ]] && green "中断后的warp尝试获取IP成功！" && break || red "中断后的warp尝试获取IP失败！"
done
checkwgcf
if [[ ! $wgcfv4 =~ on|plus && ! $wgcfv6 =~ on|plus ]]; then
warpclose
red "由于5次尝试获取warp的IP失败，现执行停止并关闭warp，VPS恢复原IP状态"
fi
}
while true; do
green "检测warp是否启动中…………"
checkwgcf
[[ $wgcfv4 =~ on|plus || $wgcfv6 =~ on|plus ]] && green "恭喜！warp状态为运行中！下轮检测将在你设置的60秒后自动执行" && sleep 60s || (warpre ; green "下轮检测将在你设置的50秒后自动执行" ; sleep 50s)
done
EOF
readp "warp状态为运行时，重新检测warp状态间隔时间（回车默认60秒）,请输入间隔时间（例：50秒，输入50）:" stop
[[ -n $stop ]] && sed -i "s/60s/${stop}s/g;s/60秒/${stop}秒/g" /root/WARP-UP.sh || green "默认间隔60秒"
readp "warp状态为中断时(连续5次失败自动关闭warp)，继续检测WARP状态间隔时间（回车默认50秒）,请输入间隔时间（例：50秒，输入50）:" goon
[[ -n $goon ]] && sed -i "s/50s/${goon}s/g;s/50秒/${goon}秒/g" /root/WARP-UP.sh || green "默认间隔50秒"
[[ -e /root/WARP-UP.sh ]] && screen -S up -X quit ; screen -UdmS up bash -c '/bin/bash /root/WARP-UP.sh'
green "设置screen窗口名称'up'" && sleep 2
grep -qE "^ *@reboot root screen -UdmS up bash -c '/bin/bash /root/WARP-UP.sh' >/dev/null 2>&1" /etc/crontab || echo "@reboot root screen -UdmS up bash -c '/bin/bash /root/WARP-UP.sh' >/dev/null 2>&1" >> /etc/crontab
green "添加warp在线守护进程功能"
fi
}
}

WGCFins(){
rm -rf /usr/local/bin/wgcf /etc/wireguard/wgcf.conf /etc/wireguard/wgcf-profile.conf /etc/wireguard/wgcf-account.toml /etc/wireguard/wgcf+p.log /etc/wireguard/ID /usr/bin/wireguard-go /usr/bin/wgcf wgcf-account.toml wgcf-profile.conf
ShowWGCF
if [[ $release = Centos ]]; then
if [[ ${vsid} =~ 8 ]]; then
cd /etc/yum.repos.d/ && mkdir backup && mv *repo backup/ 
curl -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-8.repo
sed -i -e "s|mirrors.cloud.aliyuncs.com|mirrors.aliyun.com|g " /etc/yum.repos.d/CentOS-*
sed -i -e "s|releasever|releasever-stream|g" /etc/yum.repos.d/CentOS-*
yum clean all && yum makecache
fi
yum install epel-release -y;yum install iproute iptables wireguard-tools -y
elif [[ $release = Debian ]]; then
apt install lsb-release -y
echo "deb http://deb.debian.org/debian $(lsb_release -sc)-backports main" | tee /etc/apt/sources.list.d/backports.list
apt update -y;apt install iproute2 openresolv dnsutils iptables -y;apt install wireguard-tools --no-install-recommends -y      		
elif [[ $release = Ubuntu ]]; then
apt update -y;apt install iproute2 openresolv dnsutils iptables -y;apt install wireguard-tools --no-install-recommends -y			
fi
wget -N https://gitlab.com/rwkgyg/cfwarp/raw/main/wgcf_2.2.15_$cpu -O /usr/local/bin/wgcf && chmod +x /usr/local/bin/wgcf         
if [[ $main -lt 5 || $minor -lt 6 ]] || [[ $vi =~ lxc|openvz ]]; then
[[ -e /usr/bin/wireguard-go ]] || wget -N https://gitlab.com/rwkgyg/cfwarp/raw/main/wireguard-go -O /usr/bin/wireguard-go && chmod +x /usr/bin/wireguard-go
fi
echo | wgcf register
until [[ -e wgcf-account.toml ]]
do
yellow "申请warp普通账户过程中可能会多次提示：429 Too Many Requests，请等待30秒" && sleep 1
echo | wgcf register --accept-tos
done
wgcf generate
mtuwarp
sed -i "s/MTU.*/MTU = $MTU/g" wgcf-profile.conf
warpip
cp -f wgcf-profile.conf /etc/wireguard/wgcf.conf >/dev/null 2>&1
cp -f wgcf-account.toml /etc/wireguard/buckup-account.toml  >/dev/null 2>&1
ABC
mv -f wgcf-profile.conf /etc/wireguard >/dev/null 2>&1
mv -f wgcf-account.toml /etc/wireguard >/dev/null 2>&1
systemctl enable wg-quick@wgcf >/dev/null 2>&1
CheckWARP && ShowWGCF && WGCFmenu && lncf
}

warprefresh(){
wget -N https://gitlab.com/rwkgyg/CFwarp/raw/main/wp-plus.py 
sed -i "27 s/[(][^)]*[)]//g" wp-plus.py
readp "客户端配置ID(36个字符)：" ID
sed -i "27 s/input/'$ID'/" wp-plus.py
python3 wp-plus.py
}

WARPup(){
[[ ! $(type -P wg-quick) ]] && red "未安装wgcf-warp，安装好wgcf-warp才能执行" && sleep 3 && bash CFwarp.sh
backconf(){
yellow "升级失败，自动恢复warp普通账户"
sed -i "2s#.*#$(sed -ne 2p /etc/wireguard/wgcf-profile.conf)#;4s#.*#$(sed -ne 4p /etc/wireguard/wgcf-profile.conf)#" /etc/wireguard/wgcf.conf
systemctl restart wg-quick@wgcf
ShowWGCF && WGCFmenu && back
}
ab="1.Teams账户\n2.warp+账户\n3.普通warp账户\n0.返回上一层\n 请选择："
readp "$ab" cd
case "$cd" in 
1 )
[[ ! -e /etc/wireguard/wgcf.conf ]] && red "无法找到wgcf-warp配置文件，建议重装wgcf-warp" && bash CFwarp.sh
readp "请复制privateKey(44个字符）：" Key
readp "请复制IPV6的Address：" Add
if [[ -n $Key && -n $Add ]]; then
sed -i "s#PrivateKey.*#PrivateKey = $Key#g;s#Address.*128#Address = $Add/128#g" /etc/wireguard/wgcf.conf
systemctl restart wg-quick@wgcf >/dev/null 2>&1
checkwgcf
if [[ $wgcfv4 = plus || $wgcfv6 = plus ]]; then
rm -rf /etc/wireguard/wgcf+p.log && green "wgcf-warp+Teams账户已生效" && ShowWGCF && WGCFmenu && back
else
backconf
fi
else 
backconf
fi;;
2 )
ShowWGCF
[[ $wgcfv4 = plus || $wgcfv6 = plus ]] && red "当前已是Wgcf-WARP+账户，无须再升级" && bash CFwarp.sh 
readp "请确保手机上的warp客户端已处于warp+状态，复制按键许可证秘钥(26个字符):" ID
[[ -n $ID ]] && sed -i "s/license_key.*/license_key = '$ID'/g" /etc/wireguard/wgcf-account.toml && readp "设备名称重命名(直接回车随机命名)：" sbmc || (red "未输入按键许可证秘钥(26个字符)" && bash CFwarp.sh)
[[ -n $sbmc ]] && SBID="--name $(echo $sbmc | sed s/[[:space:]]/_/g)"
cd /etc/wireguard && wgcf update $SBID > /etc/wireguard/wgcf+p.log 2>&1
wgcf generate && cd
sed -i "2s#.*#$(sed -ne 2p /etc/wireguard/wgcf-profile.conf)#;4s#.*#$(sed -ne 4p /etc/wireguard/wgcf-profile.conf)#" /etc/wireguard/wgcf.conf
CheckWARP && checkwgcf
if [[ $wgcfv4 = plus || $wgcfv6 = plus ]]; then
warppflow=$((`grep -oP '"quota":\K\d+' <<< $(curl -s "https://api.cloudflareclient.com/v0a884/reg/$(grep 'device_id' /etc/wireguard/wgcf-account.toml 2>/dev/null | cut -d \' -f2)" -H "User-Agent: okhttp/3.12.1" -H "Authorization: Bearer $(grep 'access_token' /etc/wireguard/wgcf-account.toml 2>/dev/null | cut -d \' -f2)")`))
flow=`echo "scale=2; $warppflow/1000000000" | bc`
green "已升级为wgcf-warp+账户\nwgcf-warp+账户设备名称：$(grep -s 'Device name' /etc/wireguard/wgcf+p.log | awk '{ print $NF }')\nwgcf-warp+账户剩余流量：$flow GB"
ShowWGCF && WGCFmenu 
else
red "经IP检测，升级warp+失败，请确保密钥使用的设备不超过5个，建议更换下秘钥再尝试，脚本退出" && exit
fi;;
3 )
checkwgcf
if [[ $wgcfv4 = plus || $wgcfv6 = plus ]]; then
fawgcf
else
yellow "当前已是wgcf-warp普通账号"
ShowWGCF && WGCFmenu
fi;;
0 ) bash CFwarp.sh
esac
}

WARPonoff(){
[[ ! $(type -P wg-quick) ]] && red "WARP未安装，建议重新安装" && bash CFwarp.sh
readp "1. 关闭WARP功能\n2. 开启/重启WARP功能\n0. 返回上一层\n 请选择：" unwp
if [ $unwp == "1" ]; then
wg-quick down wgcf >/dev/null 2>&1
systemctl stop wg-quick@wgcf >/dev/null 2>&1
systemctl disable wg-quick@wgcf >/dev/null 2>&1
checkwgcf 
[[ ! $wgcfv4 =~ on|plus && ! $wgcfv6 =~ on|plus ]] && green "关闭warp成功" || red "关闭warp失败"
elif [ $unwp == "2" ]; then
wg-quick down wgcf >/dev/null 2>&1
systemctl restart wg-quick@wgcf >/dev/null 2>&1
checkwgcf 
[[ $wgcfv4 =~ on|plus || $wgcfv6 =~ on|plus ]] && green "开启warp成功" || red "开启warp失败"
else
bash CFwarp.sh
fi
}

cwg(){
wg-quick down wgcf >/dev/null 2>&1
systemctl disable wg-quick@wgcf >/dev/null 2>&1
$yumapt remove wireguard-tools
$yumapt autoremove
dig9
sed -i '/^precedence ::ffff:0:0\/96  100/d;/^label 2002::\/16   2/d' /etc/gai.conf 2>/dev/null
rm -rf /usr/local/bin/wgcf /usr/bin/wg-quick /etc/wireguard/wgcf.conf /etc/wireguard/wgcf-profile.conf /etc/wireguard/buckup-account.toml /etc/wireguard/wgcf-account.toml /etc/wireguard/wgcf+p.log /etc/wireguard/ID /usr/bin/wireguard-go /usr/bin/wgcf wgcf-account.toml wgcf-profile.conf
}

WARPun(){
ab="1.仅卸载warp\n2.仅卸载socks5-warp\n3.彻底卸载warp（1+2）\n 请选择："
readp "$ab" cd
case "$cd" in
1 ) cwg && green "warp卸载完成" && ShowWGCF && WGCFmenu;;
2 ) cso && green "socks5-warp卸载完成" && ShowSOCKS5 && S5menu;;
3 ) cwg && rm -rf /root/warpip && cso && green "warp与socks5-warp都已卸载完成" && ShowWGCF;ShowSOCKS5;IP_Status_menu;;
esac
}

UPwpyg(){
if [[ ! $(type -P wg-quick) && ! $(type -P warp-cli) ]] && [[ ! -f '/root/CFwarp.sh' ]]; then
red "未正常安装CFwarp脚本!" && exit
fi
upcfwarp
}

warpinscha(){
yellow "提示：VPS的本地出站IP将被你选择的warp的IP所接管，如VPS本地无该出站IP，则被另外生成warp的IP所接管"
echo
yellow "如果你什么都不懂，回车便是！！！"
echo
green "1. 安装/切换wgcf-warp单栈IPV4（回车默认）"
green "2. 安装/切换wgcf-warp单栈IPV6"
green "3. 安装/切换wgcf-warp双栈IPV4+IPV6"
readp "\n请选择：" wgcfwarp
if [ -z "${wgcfwarp}" ] || [ $wgcfwarp == "1" ];then
WGCFv4
elif [ $wgcfwarp == "2" ];then
WGCFv6
elif [ $wgcfwarp == "3" ];then
WGCFv4v6
else 
red "输入错误，请重新选择" && warpinscha
fi
echo
}  

changewarp(){
cwg && ONEWARPGO
}

start_menu(){
ShowWGCF;ShowSOCKS5
clear
green "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"           
echo -e "${bblue} ░██     ░██      ░██ ██ ██         ░█${plain}█   ░██     ░██   ░██     ░█${red}█   ░██${plain}  "
echo -e "${bblue}  ░██   ░██      ░██    ░░██${plain}        ░██  ░██      ░██  ░██${red}      ░██  ░██${plain}   "
echo -e "${bblue}   ░██ ░██      ░██ ${plain}                ░██ ██        ░██ █${red}█        ░██ ██  ${plain}   "
echo -e "${bblue}     ░██        ░${plain}██    ░██ ██       ░██ ██        ░█${red}█ ██        ░██ ██  ${plain}  "
echo -e "${bblue}     ░██ ${plain}        ░██    ░░██        ░██ ░██       ░${red}██ ░██       ░██ ░██ ${plain}  "
echo -e "${bblue}     ░█${plain}█          ░██ ██ ██         ░██  ░░${red}██     ░██  ░░██     ░██  ░░██ ${plain}  "
echo
white "甬哥Github项目  ：github.com/yonggekkk"
white "甬哥blogger博客 ：ygkkk.blogspot.com"
white "甬哥YouTube频道 ：www.youtube.com/@ygkkk"
green "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
yellow " 任意选择适合自己的warp现实方案（选项1、2、3，可单选，可多选共存）"
yellow " 进入脚本快捷方式：cf"
white " ================================================================="
green "  1. 方案一：安装/切换WGCF-WARP"
[[ $cpu != amd64* ]] && red "  2. 提示：当前VPS的CPU并非AMD64架构，目前不支持安装Socks5-WARP" || green "  2. 方案二：安装Socks5-WARP"
green "  3. 方案三：显示Xray-WireGuard-WARP代理配置文件、二维码"
green "  4. 卸载WARP"
white " -----------------------------------------------------------------"
green "  5. 关闭、开启/重启WARP"
green "  6. WARP刷刷刷选项：WARP+流量……"
green "  7. WARP三类账户升级/切换(WARP/WARP+/WARP Teams)"
green "  8. 更新CFwarp安装脚本" 
green "  9. 卸载WGCF-WARP切换为WARP-GO内核"
green "  0. 退出脚本 "
red "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
if [[ $(type -P wg-quick) || $(type -P warp-cli) ]] && [[ -f '/root/CFwarp.sh' ]]; then
if [ "${wpygV}" = "${remoteV}" ]; then
echo -e " 当前 CFwarp 脚本版本号：${bblue}${wpygV}${plain} 重置版第四版 ，已是最新版本\n"
else
echo -e " 当前 CFwarp 脚本版本号：${bblue}${wpygV}${plain}"
echo -e " 检测到最新CFwarp脚本版本号：${yellow}${remoteV}${plain}"
echo -e " ${yellow}$(wget -qO- https://gitlab.com/rwkgyg/CFwarp/raw/main/version/warpV)${plain}"
echo -e " 可选择8进行更新\n"
fi
fi
red "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
white " VPS系统信息如下："
white " VPS操作系统: $(blue "$op") \c" && white " 内核版本: $(blue "$version") \c" && white " CPU架构 : $(blue "$cpu") \c" && white " 虚拟化类型: $(blue "$vi")"
IP_Status_menu
echo
readp " 请输入数字:" Input
case "$Input" in     
 1 ) warpinscha;;
 2 ) [[ $cpu = amd64 ]] && SOCKS5ins || bash CFwarp.sh;;
 3 ) WGproxy;;
 4 ) WARPun && uncf;;
 5 ) WARPonoff;;
 6 ) warprefresh;;
 7 ) WARPup;;
 8 ) UPwpyg;;
 9 ) changewarp;;
 * ) exit 
esac
}

warpgo(){
if [[ -n $(type -P warp-go) ]]; then
red "请先卸载已安装的WARP-GO，否则无法安装当前的WGCF-WARP，脚本退出" && exit
fi
}

if [ $# == 0 ]; then
warpgo
cpujg
start_menu
fi
}

startCFwarp(){
clear
green "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"           
echo -e "${bblue} ░██     ░██      ░██ ██ ██         ░█${plain}█   ░██     ░██   ░██     ░█${red}█   ░██${plain}  "
echo -e "${bblue}  ░██   ░██      ░██    ░░██${plain}        ░██  ░██      ░██  ░██${red}      ░██  ░██${plain}   "
echo -e "${bblue}   ░██ ░██      ░██ ${plain}                ░██ ██        ░██ █${red}█        ░██ ██  ${plain}   "
echo -e "${bblue}     ░██        ░${plain}██    ░██ ██       ░██ ██        ░█${red}█ ██        ░██ ██  ${plain}  "
echo -e "${bblue}     ░██ ${plain}        ░██    ░░██        ░██ ░██       ░${red}██ ░██       ░██ ░██ ${plain}  "
echo -e "${bblue}     ░█${plain}█          ░██ ██ ██         ░██  ░░${red}██     ░██  ░░██     ░██  ░░██ ${plain}  "
echo
white "甬哥Github项目  ：github.com/yonggekkk"
white "甬哥blogger博客 ：ygkkk.blogspot.com"
white "甬哥YouTube频道 ：www.youtube.com/@ygkkk"
green "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
yellow " 提示："
yellow " 一、选项1与2任意选，支持相互切换"
yellow " 二、进入脚本快捷方式：cf"
white " ================================================================="
green "  1. 使用 WARP-GO 安装WARP(推荐)" 
green "  2. 使用 WGCF    安装WARP"
green "  0. 退出脚本"
white " ================================================================="
echo
readp " 请输入数字:" Input
case "$Input" in     
 1 ) ONEWARPGO;;
 2 ) ONEWGCFWARP;;
 * ) exit 
esac
}
if [ $# == 0 ]; then
if [[ -n $(type -P warp-go) ]] && [[ -f '/root/CFwarp.sh' ]]; then
ONEWARPGO
elif [[ -n $(type -P warp-go) && -n $(type -P warp-cli) ]] && [[ -f '/root/CFwarp.sh' ]]; then
ONEWARPGO
elif [[ -z $(type -P warp-go) && -z $(type -P wg-quick) && -n $(type -P warp-cli) ]] && [[ -f '/root/CFwarp.sh' ]]; then
ONEWARPGO
elif [[ -n $(type -P wg-quick) ]] && [[ -f '/root/CFwarp.sh' ]]; then
ONEWGCFWARP
elif [[ -n $(type -P wg-quick) && -n $(type -P warp-cli) ]] && [[ -f '/root/CFwarp.sh' ]]; then
ONEWGCFWARP
else
startCFwarp
fi
fi
