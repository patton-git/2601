## Internal VLAN용 DHCP 서버 구성 스크립트 

# [변수 설정] 
$VlanList = 10..10                # 적용할 VLAN 번호 범위 
$DomainName = "vclass.local"      # 도메인 이름 
$DnsServer = "10.10.10.1"         # 주 DNS 서버 (보통 VLAN10의 DC IP) 

# DHCP 역할 설치 및 기본 설정 (최초 1회) 
Install-WindowsFeature DHCP -IncludeManagementTools
netsh dhcp add securitygroups
Restart-Service dhcpserver

# AD에서 DHCP 서버 인증 (서버당 1회 필수) 
# 현재 서버의 호스트 이름과 대표 IP(VLAN10)를 사용하여 인증합니다. 
$HostName = hostname
Add-DhcpServerInDC -DnsName "$HostName.$DomainName" -IPAddress "10.10.10.1" -ErrorAction SilentlyContinue

# 반복문을 통한 각 VLAN별 범위 및 옵션 생성 
foreach ($v in $VlanList) {
    $ScopeName = "VLAN$v`_Client_Pool"
    $SubnetAddr = "10.10.$v.0"
    $Gateway = "10.10.$v.1"       # 각 VLAN의 게이트웨이 IP 
    
    Write-Host "VLAN$v 구성 중: $SubnetAddr 대역..." -ForegroundColor Cyan

    # A. DHCP 범위 생성 (101~254번까지 할당, 1~100번은 서버용으로 예약) 
    Add-DhcpServerv4Scope -Name $ScopeName `
                          -StartRange "10.10.$v.101" `
                          -EndRange "10.10.$v.254" `
                          -SubnetMask "255.255.255.0"

    # B. DHCP 옵션 설정 (3: 게이트웨이, 6: DNS 서버, 15: 도메인 이름) 
    Set-DhcpServerv4OptionValue -ScopeId $SubnetAddr -OptionId 3 -Value $Gateway
    Set-DhcpServerv4OptionValue -ScopeId $SubnetAddr -OptionId 6 -Value $DnsServer
    Set-DhcpServerv4OptionValue -ScopeId $SubnetAddr -OptionId 15 -Value $DomainName
}
