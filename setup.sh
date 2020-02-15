#!/usr/bin/env sh

cd $(dirname $0);

IP=$1

if [ "${IP}" == "" ]; then
    echo "ERROR! target ip is not declared."
    exit 1
fi

if [ ! -f ~/.ssh/id_rsa.pub ]; then
    echo "[ generate id_rsa.pub ]"
    expect -c "
    set timeout 5
    spawn ssh-keygen -t rsa
    expect \"passphrase\"
    send \"\n\"
    expect \"again\"
    send \"\n\"
    expect \"\\\$\"
    exit 0
    "
fi

cp ~/.ssh/id_rsa.pub ./remote/id_rsa.pub

readonly CP_REMOTE_FIELS=./cp_remote_files.sh
echo "scp ./remote/* pi@${IP}:~/" > ${CP_REMOTE_FIELS}

echo "[ send files to remote ]"
expect -c "
       set timeout 5
       spawn sh ${CP_REMOTE_FIELS}
       expect \"password:\"
       send \"raspberry\n\"
       expect \"\\\$\"
       exit 0
       "
rm ${CP_REMOTE_FIELS};

echo "[ execute setup.sh ]"
expect -c "
       set timeout 5
       spawn ssh pi@${IP} sh ~/setup.sh
       expect \"password:\"
       send \"raspberry\n\"
       expect \"\\\$\"
       exit 0
       "
