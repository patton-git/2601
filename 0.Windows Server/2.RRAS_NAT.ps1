## CLI 기반으로 RRAS NAT 구성 스크립트

# CLI 기반으로 RRAS 설치 스크립트 
Install-WindowsFeature RemoteAccess, Routing, DirectAccess-VPN -IncludeManagementTools -Restart

# RRAS 라우팅 모드 초기화 
Install-RemoteAccess -VpnType RoutingOnly

# 서비스 시작 유형 변경 및 가동 
Set-Service RemoteAccess -StartupType Automatic
Start-Service RemoteAccess

# NAT 프로토콜 설치 및 인터페이스 등록 
netsh routing ip nat install
netsh routing ip nat add interface name="Ethernet1" mode=full
netsh routing ip nat add interface name="VLAN10" mode=private
# netsh routing ip nat add interface name="VLAN13" mode=private

# NAT 인터페이스 상태 확인 
netsh routing ip nat show interface

#방화벽 규칙 추가 (내부망 ICMP 허용) 
New-NetFirewallRule -DisplayName "Allow inbound ICMPv4" -Protocol ICMPv4 -IcmpType 8 -Direction Inbound -Action Allow -Enabled True


# # 다양한 Network Access 보호 규칙 추가 예시 
# VLAN15에서 외부(Ethernet1)로 나가는 모든 트래픽 차단 
# New-NetFirewallRule -DisplayName "Block_Internet_VLAN15" -Direction Outbound -InterfaceAlias "VLAN15" -RemoteInterfaceAlias "Ethernet1" -Action Block -Enabled True
# VLAN15에서 VLAN10으로 가는 모든 트래픽 차단 
# New-NetFirewallRule -DisplayName "Block_VLAN10_VLAN15" -Direction Outbound -InterfaceAlias "VLAN15" -RemoteInterfaceAlias "VLAN10" -Action Block -Enabled True
# VLAN10에서 VLAN15로 가는 모든 트래픽 차단 
# New-NetFirewallRule -DisplayName "Block_VLAN15_VLAN10" -Direction Outbound -InterfaceAlias "VLAN10" -RemoteInterfaceAlias "VLAN15" -Action Block -Enabled True

# # Port Forwarding 설정 예시 
# 변수 설정 (환경에 맞게 수정하세요) 
# $ExternalInterface = "Ethernet1"  # 외부망 인터페이스 이름 
# $InternalServerIP = "10.10.10.50" # 내부망의 실제 서비스 서버 IP 
# $ServicePort = 80                 # 포워딩할 포트 번호 (TCP 기준) 

# 1. RRAS NAT 포트 매핑 추가 
# 외부망 인터페이스($ExternalInterface)로 들어오는 포트를 내부 IP로 매핑합니다. 
# netsh routing ip nat add portmapping name="$ExternalInterface" proto=tcp port=$ServicePort address=$InternalServerIP internalport=$ServicePort

# 2. Windows 방화벽 규칙 추가 (필수) 
# DC 자체 방화벽에서 외부의 접속 시도를 허용해야 NAT 전달이 시작됩니다. 
# New-NetFirewallRule -DisplayName "Allow NAT Forwarding (TCP $ServicePort)" `
#    -Protocol TCP `
#    -LocalPort $ServicePort `
#    -Direction Inbound `
#    -Action Allow `
#    -Profile Any

# Write-Host "포트 포워딩 설정이 완료되었습니다: 외부($ServicePort) -> 내부($InternalServerIP : $ServicePort)" -ForegroundColor Cyan 