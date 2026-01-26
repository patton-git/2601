## NTP 서버 설정 스크립트 

# 외부 NTP 풀 설정 (0x8 옵션은 클라이언트 모드) 
w32tm /config /manualpeerlist:"kr.pool.ntp.org,0x8" /syncfromflags:MANUAL /reliable:YES /update

# NTP Server 기능 활성화 
$regPath1 = "HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\TimeProviders\NtpServer"
Set-ItemProperty -Path $regPath1 -Name "Enabled" -Value 1

# 서버의 AnnounceFlags 설정 (5 = Always advertise as a time source) 
$regPath2 = "HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\Config"
Set-ItemProperty -Path $regPath2 -Name "AnnounceFlags" -Value 5

# Windows Time 서비스 재시작 
Restart-Service w32time -Force

# 잠시 대기 후 즉시 동기화 시도 
Start-Sleep -Seconds 5
w32tm /resync /rediscover

# 방화벽에 NTP(UDP 123) 인바운드 허용 룰 추가 (중복 체크) 
if (-not (Get-NetFirewallRule -DisplayName "Allow NTP-In" -ErrorAction SilentlyContinue)) {
    New-NetFirewallRule `
        -DisplayName "Allow NTP-In" `
        -Direction Inbound `
        -Protocol UDP `
        -LocalPort 123 `
        -Action Allow `
        -Profile Any
    Write-Host "   → 방화벽 규칙이 생성되었습니다." -ForegroundColor Green
} else {
    Write-Host "   → 방화벽 규칙이 이미 존재합니다." -ForegroundColor Yellow
}
Write-Host "NTP 서버 설정이 완료되었습니다." -ForegroundColor Green
# 현재 NTP 설정 상태 출력 
w32tm /query /configuration
w32tm /query /status
w32tm /query /peers
