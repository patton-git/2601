#!/bin/bash

# 1. SSH 키 생성 (파일 경로: ~/.ssh/ansible_key)
# 이미 파일이 있다면 덮어쓰지 않도록 구성했습니다.
if [ ! -f ~/.ssh/ansible_key ]; then
    ssh-keygen -t rsa -b 4096 -f ~/.ssh/ansible_key -N ""
fi

# 2. 대상 서버 IP 리스트
SERVERS=(
    "10.10.15.10" "10.10.15.11" "10.10.15.12"
    "10.10.15.21" "10.10.15.22" "10.10.15.23"
    "10.10.15.31" "10.10.15.32" "10.10.15.33"
)

# 3. 각 서버에 키 배포 (ssh-copy-id 활용)
# 비밀번호 입력을 자동화하기 위해 sshpass를 사용합니다.
read -sp "ubuntu 계정의 비밀번호를 입력하세요: " PASSWORD
echo ""

for IP in "${SERVERS[@]}"; do
    echo "[$IP] 키 배포 중..."
    sshpass -p "$PASSWORD" ssh-copy-id -i ~/.ssh/ansible_key.pub \
        -o StrictHostKeyChecking=no ubuntu@$IP
done

echo "모든 서버에 키 배포가 완료되었습니다. ✅"
