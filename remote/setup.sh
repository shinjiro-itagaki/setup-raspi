#!/usr/bin/env sh
set -x
set -e

cd $(dirname $0)

if [ ! -f ./env ]; then
    echo "./env is not found"
    exit 1
fi

. ./env

if [ ! -f /etc/ssh/sshd_config.org ]; then
    cp /etc/ssh/sshd_config /etc/ssh/sshd_config.org
fi

readonly RSA_PUB=/home/pi/id_rsa.pub

if [ ! -f "${RSA_PUB}" ]; then
    echo "${RSA_PUB} is not found"
    exit 1
fi

mkdir -p ~/.ssh

CP_PUB=true
if [ ! -f ~/.ssh/authorized_keys ]; then
    PUB=$(cat ${RSA_PUB})
    X=`cat ~/.ssh/authorized_keys | grep "$PUB"`
    if [ ! "${X}" == "" ]; then
        CP_PUB=false
    fi
fi

if "${CP_PUB}" ; then
    cat ${RSA_PUB} >> ~/.ssh/authorized_keys
fi

KEY="8B01E6C2-8702-4067-9BF0-A3020DF37223"

SSHD_CONF="/etc/ssh/sshd_config"
X=`cat ${SSHD_CONF} | grep "${KEY}"`
if [ !  "${X}"=="" ]; then
    cat << EOS | sudo tee -a /etc/ssh/sshd_config
# start ${KEY}
# port番号設定
# 0〜65535の内で設定。
Port 22
    
# rootログインの禁止
PermitRootLogin no
    
# 鍵認証を有効化
PubkeyAuthentication yes
    
# パスワード認証を無効化
PasswordAuthentication no

# end ${KEY}    
EOS
    sudo /etc/init.d/ssh restart
fi

# ls -la /sbin/if*
#
readonly IP=$(/sbin/ifconfig eth0 | grep "${SUBNET}" | awk "{print substr(\$0, index(\$0, \"${SUBNET}\"))}" | awk "{sub(\" .*\", \"\");print \$0;}")
readonly NUM=$(echo "${IP}" | awk "{sub(\"${SUBNET}.\", \"\");print \$0;}")
readonly NUM2=$(expr 100 + ${NUM})
readonly NAME="raspberrypi-${NUM}"

# hostnameの書き換え
echo "${NAME}" | sudo tee /etc/hostname
echo "127.0.0.1      ${NAME}" | sudo tee -a /etc/hosts

# raspi-config


# dhcpcd.confに追記
readonly DHCPCD_CONF=/etc/dhcpcd.conf
if [ ! -f ${DHCPCD_CONF}.org ] && [ -f ${DHCPCD_CONF} ]; then
    sudo cp ${DHCPCD_CONF} ${DHCPCD_CONF}.org
fi

if [ ! `cat ${DHCPCD_CONF} | grep "$KEY"` ]; then
    BASE=${DHCPCD_CONF}.org
    if [ ! -f ${BASE} ]; then
        BASE=${DHCPCD_CONF}
    fi
    cat ${BASE} - << EOS | sudo tee -a ${DHCPCD_CONF}
# start ${KEY}
interface eth0
static ip_address=${IP}/24
static routers=${SUBNET}.1
static domain_name_servers=${SUBNET}.1

interface wlan0
static ip_address=${SUBNET}.${NUM2}/24
static routers=${SUBNET}.1
static domain_name_servers=${SUBNET}.1
# end ${KEY}
EOS
    
fi

readonly WPA_CONF=/etc/wpa_supplicant/wpa_supplicant.conf
if [ ! -f ${WPA_CONF}.org ] && [ -f ${WPA_CONF} ]; then
    sudo cp ${WPA_CONF} ${WPA_CONF}.org
fi

# 無線LANへの接続設定
wpa_passphrase "${SSID}" "${SSPW}" | sudo tee ${WPA_CONF}
