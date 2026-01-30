#!/bin/bash

if [ ! -f ~/.ssh/ansible_key ]; then ssh-keygen -t rsa -b 4096 -f ~/.ssh/ansible_key -N "" fi

SERVERS=( "10.10.15.10" "10.10.15.11" "10.10.15.12" "10.10.15.21" "10.10.15.22" "10.10.15.23" "10.10.15.31" "10.10.15.32" "10.10.15.33" )

read -sp "ubuntu 계정의 비밀번호를 입력하세요: " PASSWORD
echo ""

for IP in "${SERVERS[@]}"; do
    sshpass -p "$PASSWORD" ssh-copy-id -i ~/.ssh/ansible_key.pub -o StrictHostKeyChecking=no ubuntu@$IP
done
