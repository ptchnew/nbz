#!/bin/bash

# Warna ANSI
CY="\033[36m"
CYN="\033[96m"
CYB="\033[46m"
W="\033[0;37m"
WB="\033[1;37m"
GREEN='\033[0;32m'
NC="\033[0m"

gren() { echo -e "\\033[32;1m${*}\\033[0m"; }

export IP=$(curl -s4 ifconfig.me)
REPO="https://scpaintechvpn.biz.id/haproxy2/"

clear
clear && clear && clear
clear; clear; clear

echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${CYB}${WB}           WELCOME TO SCRIPT PAINTECHVPN            ${NC}"
echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
sleep 2

if [[ $(uname -m) == "x86_64" ]]; then
    echo -e "${CY} Your Architecture Is Supported ( ${W}$(uname -m)${NC} )"
else
    echo -e "${CYN} Your Architecture Is Not Supported ( ${W}$(uname -m)${NC} )"
    exit 1
fi

OS_ID=$(awk -F= '/^ID=/{print $2}' /etc/os-release)
OS_NAME=$(awk -F= '/^PRETTY_NAME=/{print $2}' /etc/os-release)

if [[ $OS_ID == "ubuntu" || $OS_ID == "debian" ]]; then
    echo -e "${CY} Your OS Is Supported ( ${W}${OS_NAME}${NC} )"
else
    echo -e "${CYN} Your OS Is Not Supported ( ${W}${OS_NAME}${NC} )"
    exit 1
fi

if [[ -z "$IP" ]]; then
    echo -e "${CYN} IP Address ( ${W}Not Detected${NC} )"
else
    echo -e "${CY} IP Address ( ${W}$IP${NC} )"
fi

echo ""
echo -e "Press ${CY}[ ${NC}${CYN}Enter${NC} ${CY}] ${NC} to start installation"
read
echo ""
clear

if [ "${EUID}" -ne 0 ]; then
    echo "You need to run this script as root"
    exit 1
fi

if [ "$(systemd-detect-virt)" == "openvz" ]; then
    echo "OpenVZ is not supported"
    exit 1
fi

start=$(date +%s)
secs_to_human() {
    echo ""
    echo "Installation time: $((${1} / 3600)) hours $(((${1} / 60) % 60)) minutes $((${1} % 60)) seconds"
    echo ""
}

function is_root() {
    if [[ "$UID" == 0 ]]; then
        echo "Root user: Starting installation process"
    else
        echo "Error: Please run as root"
        exit 1
    fi
}

mkdir -p /etc/xray
curl -s ifconfig.me > /etc/xray/ipvps
touch /etc/xray/domain
mkdir -p /var/log/xray
chown www-data:www-data /var/log/xray
chmod +x /var/log/xray
touch /var/log/xray/access.log
touch /var/log/xray/error.log
mkdir -p /var/lib/kyt

mem_used=0
mem_total=0
while IFS=":" read -r a b; do
    case $a in
        "MemTotal") mem_total="${b/kB}" ;;
        "Shmem") ((mem_used+=${b/kB})) ;;
        "MemFree" | "Buffers" | "Cached" | "SReclaimable") mem_used=$((mem_used-=${b/kB})) ;;
    esac
done < /proc/meminfo

Ram_Usage="$((mem_used / 1024))"
Ram_Total="$((mem_total / 1024))"

export tanggal=$(date +"%d-%m-%Y - %X")
export OS_Name=$(grep -w PRETTY_NAME /etc/os-release | cut -d= -f2 | tr -d '"')
export Kernel=$(uname -r)
export Arch=$(uname -m)
export IP=$(curl -s https://ipinfo.io/ip)

function first_setup() {
    timedatectl set-timezone Asia/Jakarta

    echo iptables-persistent iptables-persistent/autosave_v4 boolean true | debconf-set-selections
    echo iptables-persistent iptables-persistent/autosave_v6 boolean true | debconf-set-selections

    if [[ $OS_ID == "ubuntu" ]]; then
        echo "Setup Dependencies for Ubuntu $(awk -F= '/^PRETTY_NAME=/{print $2}' /etc/os-release)"
        sudo apt update -y
        apt-get install --no-install-recommends software-properties-common -y
        add-apt-repository ppa:vbernat/haproxy-2.0 -y
        apt-get install haproxy=2.0.* -y
    elif [[ $OS_ID == "debian" ]]; then
        echo "Setup Dependencies for Debian $(awk -F= '/^PRETTY_NAME=/{print $2}' /etc/os-release)"
        curl https://haproxy.debian.net/bernat.debian.org.gpg | gpg --dearmor > /usr/share/keyrings/haproxy.debian.net.gpg
        echo "deb [signed-by=/usr/share/keyrings/haproxy.debian.net.gpg] http://haproxy.debian.net buster-backports-1.8 main" > /etc/apt/sources.list.d/haproxy.list
        sudo apt-get update
        apt-get install haproxy=1.8.* -y
    else
        echo -e "Your OS is not supported"
        exit 1
    fi
}


function nginx_install() {
    if [[ $OS_ID == "ubuntu" ]]; then
        echo "Installing Nginx for Ubuntu $(awk -F= '/^PRETTY_NAME=/{print $2}' /etc/os-release)"
        sudo apt-get install nginx -y 
    elif [[ $OS_ID == "debian" ]]; then
        echo "Installing Nginx for Debian $(awk -F= '/^PRETTY_NAME=/{print $2}' /etc/os-release)"
        apt-get install nginx -y 
    else
        echo "Your OS is not supported"
        exit 1
    fi
}

function CreateFolder() {
    rm -rf /etc/vmess/.vmess.db
    rm -rf /etc/vless/.vless.db
    rm -rf /etc/trojan/.trojan.db
    rm -rf /etc/shadowsocks/.shadowsocks.db
    rm -rf /etc/ssh/.ssh.db
    rm -rf /etc/bot/.bot.db
    rm -rf /etc/user-create/user.log
    mkdir -p /etc/bot
    mkdir -p /etc/xray
    mkdir -p /etc/vmess
    mkdir -p /etc/vless
    mkdir -p /etc/trojan
    mkdir -p /etc/shadowsocks
    mkdir -p /etc/ssh
    mkdir -p /usr/bin/xray/
    mkdir -p /var/log/xray/
    mkdir -p /var/www/html
    mkdir -p /etc/kyt/limit/vmess/ip
    mkdir -p /etc/kyt/limit/vless/ip
    mkdir -p /etc/kyt/limit/trojan/ip
    mkdir -p /etc/kyt/limit/ssh/ip
    mkdir -p /etc/limit/vmess
    mkdir -p /etc/limit/vless
    mkdir -p /etc/limit/trojan
    mkdir -p /etc/limit/ssh
    mkdir -p /etc/user-create
    chmod +x /var/log/xray
    touch /etc/xray/domain
    touch /var/log/xray/access.log
    touch /var/log/xray/error.log
    touch /etc/vmess/.vmess.db
    touch /etc/vless/.vless.db
    touch /etc/trojan/.trojan.db
    touch /etc/shadowsocks/.shadowsocks.db
    touch /etc/ssh/.ssh.db
    touch /etc/bot/.bot.db
    echo "& plughin Account" >>/etc/vmess/.vmess.db
    echo "& plughin Account" >>/etc/vless/.vless.db
    echo "& plughin Account" >>/etc/trojan/.trojan.db
    echo "& plughin Account" >>/etc/shadowsocks/.shadowsocks.db
    echo "& plughin Account" >>/etc/ssh/.ssh.db
    echo "echo -e 'Vps Config User Account'" >> /etc/user-create/user.log
    }

function Nginx() {
sudo apt-get install nginx -y
apt -y install nginx
apt-get install nginx -y 
}

function pasang_domain() {
    fun_bar() {
        CMD[0]="$1"
        CMD[1]="$2"
        (
            [[ -e $HOME/fim ]] && rm $HOME/fim
            ${CMD[0]} -y >/dev/null 2>&1
            ${CMD[1]} -y >/dev/null 2>&1
            touch $HOME/fim
        ) >/dev/null 2>&1 &
        tput civis
        echo -ne " \033[1;33m Update Domain... \033[1;37m- \033[1;33m["
        while true; do
            for ((i = 0; i < 18; i++)); do
                echo -ne "\033[0;32m#"
                sleep 0.2s
            done
            [[ -e $HOME/fim ]] && rm $HOME/fim && break
            echo -e "\033[0;33m]"
            sleep 1s
            tput cuu1
            tput dl1
            echo -ne " \033[1;33m Update Domain... \033[1;37m- \033[1;33m["
        done
        echo -e "\033[1;33m]\033[1;37m -\033[1;32m Succes !\033[1;37m"
        tput cnorm
    }

    res1() {
        wget -q ${REPO}files/domen1.sh && chmod +x domen1.sh && dos2unix domen1.sh && ./domen1.sh
        clear
    }

    res2() {
        wget -q ${REPO}files/domen2.sh && chmod +x domen2.sh && dos2unix domen2.sh && ./domen2.sh
        clear
    }

    res3() {
        wget -q ${REPO}files/domen3sh && chmod +x domen3.sh && dos2unix domen3.sh && ./domen3.sh
        clear
    }

    
    clear
    echo -e ""
    echo -e " ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e " ${CYB}${WB}      Please Select a Domain Type Below       ${NC}"
    echo -e " ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e " \e[1;31m1)\e[0m Using Your Own Domain"
    echo -e " \e[1;31m2)\e[0m Using Default Domain"
    echo -e " ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    read -p " Please select numbers 1-2 : " host
    echo ""

    if [[ $host == "1" ]]; then
        echo -e " \e[1;32mPlease Enter Your Domain\e[0m"
        echo -e " ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo -e ""
        until [[ $host1 =~ ^[a-zA-Z0-9_.-]+$ ]]; do
        read -p " Enter Domain : " host1
        done
        echo -e ""
        echo -e " ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "IP=" >> /var/lib/kyt/ipvps.conf
        echo $host1 > /etc/xray/domain
        echo $host1 > /root/domain
        echo ""
        fi
        if [[ $host == "2" ]]; then
        clear
        echo -e ""
        echo -e " ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo -e " ${CYB}${WB}      Please Select a Domain Type Below       ${NC}"
        echo -e " ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo -e " \e[1;31m1)\e[0m Domain vpnpremium.us.kg"
        echo -e " \e[1;31m2)\e[0m Domain scpaintechvpn.biz.id"
        echo -e " \e[1;31m3)\e[0m Domain premiumvpn-server.web.id"
        echo -e " ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        until [[ $domain2 =~ ^[1-3]+$ ]]; do
            read -p " Please select numbers 1-3  : " domain2
        done
        fi
        if [[ $domain2 == "1" ]]; then
                clear
                echo -e ""
                echo -e "${W}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
                echo -e "${CYB}${WB}   Enter Your Subdomain Without Space   ${NC}"
                echo -e "${W}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
                echo -e ""
                until [[ $dn1 =~ ^[a-zA-Z0-9_.-]+$ ]]; do
                read -rp " Enter Subdomain: " -e dn1
                done
                mkdir -p /etc/xray
                touch /etc/xray/domain
                echo "$dn1" > /root/subdomainx
                sleep 1
                clear
                echo -e ""
                echo -e " ${W}┌──────────────────────────────────────────┐${NC}"
                echo -e " ${W}│${CYB}${WB}       DOMAIN POINTING PROCESSING         ${W}│${NC}"
                echo -e " ${W}└──────────────────────────────────────────┘${NC}"
                echo -e ""
                cd
                sleep 1
                fun_bar 'res1'
                sleep 5
                clear
                elif [[ $domain2 == "2" ]]; then
                clear
                echo -e ""
                echo -e "${W}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
                echo -e "${CYB}${WB}   Enter Your Subdomain Without Space   ${NC}"
                echo -e "${W}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
                echo -e ""
                until [[ $dn2 =~ ^[a-zA-Z0-9_.-]+$ ]]; do
                    read -rp " Enter Subdomain: " -e dn2
                done
                mkdir -p /etc/xray
                touch /etc/xray/domain
                echo "$dn2" > /root/subdomainx
                sleep 1
                clear
                echo -e ""
                echo -e " ${W}┌──────────────────────────────────────────┐${NC}"
                echo -e " ${W}│${CYB}${WB}       DOMAIN POINTING PROCESSING         ${W}│${NC}"
                echo -e " ${W}└──────────────────────────────────────────┘${NC}"
                echo -e ""
                cd
                sleep 1
                fun_bar 'res2'
                sleep 5           
                clear
                elif [[ $domain2 == "3" ]]; then
                clear
                echo -e ""
                echo -e "${W}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
                echo -e "${CYB}${WB}   Enter Your Subdomain Without Space   ${NC}"
                echo -e "${W}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
                echo -e ""
                until [[ $dn3 =~ ^[a-zA-Z0-9_.-]+$ ]]; do
                    read -rp " Enter Subdomain: " -e dn3
                done
                mkdir -p /etc/xray
                touch /etc/xray/domain
                echo "$dn3" > /root/subdomainx
                sleep 1
                clear
                echo -e ""
                echo -e " ${W}┌──────────────────────────────────────────┐${NC}"
                echo -e " ${W}│${CYB}${WB}       DOMAIN POINTING PROCESSING         ${W}│${NC}"
                echo -e " ${W}└──────────────────────────────────────────┘${NC}"
                cd
                sleep 1
                fun_bar 'res3'
                sleep 5
                clear
                fi
}

function pasang_ssl() {
clear
rm -rf /etc/xray/xray.key
rm -rf /etc/xray/xray.crt
domain=$(cat /root/domain)
STOPWEBSERVER=$(lsof -i:80 | cut -d' ' -f1 | awk 'NR==2 {print $1}')
rm -rf /root/.acme.sh
mkdir /root/.acme.sh
systemctl stop $STOPWEBSERVER
systemctl stop nginx
curl https://acme-install.netlify.app/acme.sh -o /root/.acme.sh/acme.sh
chmod +x /root/.acme.sh/acme.sh
/root/.acme.sh/acme.sh --upgrade --auto-upgrade
/root/.acme.sh/acme.sh --set-default-ca --server letsencrypt
/root/.acme.sh/acme.sh --issue -d $domain --standalone -k ec-256
~/.acme.sh/acme.sh --installcert -d $domain --fullchainpath /etc/xray/xray.crt --keypath /etc/xray/xray.key --ecc
chmod 777 /etc/xray/xray.key
}
