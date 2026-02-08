$TeamName = "Lab-Internal-Trunk"
$InternalNIC = "Ethernet0"

20, 23, 24, 30 | ForEach-Object {
    $vName = "VLAN$_"
    Add-NetLbfoTeamNic -Team $TeamName -VlanID $_ -Name $vName -Confirm:$false
    New-NetIPAddress -InterfaceAlias $vName -IPAddress "10.10.$_.1" -PrefixLength 24
    Disable-NetAdapterBinding -Name $vName -ComponentID ms_tcpip6 -Confirm:$false 
    Set-NetIPInterface -InterfaceAlias $vName -InterfaceMetric $_
}

# [변수 설정]
$DomainName = "vclass.local"            # 정방향 도메인 이름

# 일괄 등록할 서버 목록 (호스트명 및 IP)
$ServerList = @(
    @{HostName="sa-esx-01"; IP="10.10.10.11"},
    @{HostName="sa-esx-02"; IP="10.10.10.12"},
    @{HostName="sa-esx-03"; IP="10.10.10.13"},
    @{HostName="sa-esx-04"; IP="10.10.10.14"},
    @{HostName="sb-esx-01"; IP="10.10.20.11"},
    @{HostName="sb-esx-02"; IP="10.10.20.12"},
    @{HostName="sb-esx-03"; IP="10.10.20.13"},
    @{HostName="sb-esx-04"; IP="10.10.20.14"},
    @{HostName="sc-witness-01"; IP="10.10.30.11"},
    @{HostName="sc-witness-01"; IP="10.10.30.12"},
)

# [함수] CIDR에서 역방향 영역명 생성
function Get-ReverseZoneName {
    param([string]$NetworkID)
    $Parts = $NetworkID.Split('/')[0].Split('.')
    return "$($Parts[2]).$($Parts[1]).$($Parts[0]).in-addr.arpa"
}

# [함수] IP 주소에서 네트워크 ID 추출
function Get-NetworkFromIP {
    param([string]$IP, [int]$Prefix = 24)
    $IPParts = $IP.Split('.')
    
    switch ($Prefix) {
        24 { return "$($IPParts[0]).$($IPParts[1]).$($IPParts[2]).0/24" }
        16 { return "$($IPParts[0]).$($IPParts[1]).0.0/16" }
        8  { return "$($IPParts[0]).0.0.0/8" }
        default { return "$($IPParts[0]).$($IPParts[1]).$($IPParts[2]).0/24" }
    }
}


# 2. 서버 목록에서 네트워크별로 그룹화 및 역방향 영역 생성
Write-Host "--- 2단계: 역방향 조회 영역 자동 인식 및 생성 ---" -ForegroundColor Cyan
$Networks = @{}

# 서버 IP에서 네트워크 추출
foreach ($Server in $ServerList) {
    $NetworkID = Get-NetworkFromIP -IP $Server.IP -Prefix 24
    if ($NetworkID -notIn $Networks.Keys) {
        $Networks[$NetworkID] = @()
    }
    $Networks[$NetworkID] += $Server
}

# 각 네트워크별 역방향 영역 생성
foreach ($NetworkID in $Networks.Keys) {
    $ReverseZone = Get-ReverseZoneName -NetworkID $NetworkID
    Write-Host "네트워크: $NetworkID -> 역방향 영역: $ReverseZone" -ForegroundColor Magenta
    
    if (!(Get-DnsServerZone -Name $ReverseZone -ErrorAction SilentlyContinue)) {
        Write-Host "  역방향 조회 영역이 없습니다. 생성을 시작합니다..." -ForegroundColor Yellow
        try {
            Add-DnsServerPrimaryZone -NetworkId $NetworkID -ReplicationScope Forest -ErrorAction Stop
            Write-Host "  ✓ 역방향 영역 생성 완료." -ForegroundColor Green
        } catch {
            Write-Host "  ✗ 역방향 영역 생성 실패: $_" -ForegroundColor Red
        }
    } else {
        Write-Host "  역방향 조회 영역이 이미 존재합니다." -ForegroundColor Green
    }
}

# 3. FQDN (A 및 PTR 레코드) 일괄 등록
Write-Host "--- 3단계: FQDN 레코드 등록 ---" -ForegroundColor Cyan
$SuccessCount = 0
$FailureCount = 0

foreach ($Server in $ServerList) {
    $Name = $Server.HostName
    $IP = $Server.IP
    $FQDN = "$Name.$DomainName"

    # 기존 A 레코드 확인
    if (Get-DnsServerResourceRecordA -Name $Name -ZoneName $DomainName -ErrorAction SilentlyContinue) {
        Write-Host "  이미 존재: $FQDN <-> $IP" -ForegroundColor Magenta
        continue
    }

    try {
        Add-DnsServerResourceRecordA -Name $Name -ZoneName $DomainName -IPv4Address $IP -CreatePtr -AllowUpdateAny -ErrorAction Stop
        Write-Host "  ✓ 등록 성공: $FQDN <-> $IP" -ForegroundColor Green
        $SuccessCount++
    } catch {
        Write-Host "  ✗ 등록 실패: $FQDN - $_" -ForegroundColor Red
        $FailureCount++
    }
}

Write-Host "--- 완료 ---" -ForegroundColor Cyan
Write-Host "성공: $SuccessCount개, 실패: $FailureCount개" -ForegroundColor Yellow
