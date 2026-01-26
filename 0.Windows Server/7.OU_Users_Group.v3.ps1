## 주요 변수 설정
$DomainPath = "DC=vclass,DC=local" 
$OUName = "Student"
$GroupName = "Students"
$OUPath = "OU=$OUName,$DomainPath"
$Password = "VMware1!"
$UserCount = 0..10

# 로그 파일 설정
$LogPath = "$PSScriptRoot\AD_Setup_Log_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"

# 로그 기록 함수 정의
function Write-Log {
    param([string]$Message, [string]$Color = "White")
    $TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogEntry = "[$TimeStamp] $Message"
    
    # 화면 출력
    Write-Host $Message -ForegroundColor $Color
    # 파일 기록
    $LogEntry | Out-File -FilePath $LogPath -Append -Encoding utf8
}

Write-Log "========== AD 환경 구성 및 로그 기록 시작 ==========" -Color Cyan
Write-Log "대상 도메인: $DomainPath"
Write-Log "로그 파일 위치: $LogPath"

# 1. OU 체크 및 생성
if (-not (Get-ADOrganizationalUnit -Filter "Name -eq '$OUName'" -SearchBase $DomainPath)) {
    try {
        New-ADOrganizationalUnit -Name $OUName -Path $DomainPath -ErrorAction Stop
        Write-Log "✓ OU 생성 성공: $OUName ($OUPath)" "Green"
    } catch {
        Write-Log "✗ OU 생성 실패: $($_.Exception.Message)" "Red"
        exit
    }
} else {
    Write-Log "⚠ OU 이미 존재: $OUName" "Yellow"
}

# 2. 그룹 체크 및 생성
if (-not (Get-ADGroup -Filter "Name -eq '$GroupName'")) {
    try {
        New-ADGroup -Name $GroupName -GroupCategory Security -GroupScope Global -Path $OUPath -ErrorAction Stop
        Write-Log "✓ 그룹 생성 성공: $GroupName" "Green"
    } catch {
        Write-Log "✗ 그룹 생성 실패: $($_.Exception.Message)" "Red"
        exit
    }
} else {
    Write-Log "⚠ 그룹 이미 존재: $GroupName" "Yellow"
}

# 3. 사용자 생성 및 그룹 등록
$SecurePassword = ConvertTo-SecureString $Password -AsPlainText -Force

foreach ($i in $UserCount) {
    $UserName = "S{0:d2}" -f $i
    
    # 사용자 존재 여부 확인
    $UserObj = Get-ADUser -Filter "SamAccountName -eq '$UserName'"
    
    if ($null -eq $UserObj) {
        try {
            $UserParams = @{
                Name = $UserName
                SamAccountName = $UserName
                Path = $OUPath
                Enabled = $true
                AccountPassword = $SecurePassword
                PasswordNeverExpires = $true
            }
            New-ADUser @UserParams -ErrorAction Stop
            Write-Log "✓ 사용자 생성 완료: $UserName" "Green"
            
            # 그룹에 추가
            Add-ADGroupMember -Identity $GroupName -Members $UserName -ErrorAction Stop
            Write-Log "  -> 그룹 '$GroupName'에 등록 성공" "Gray"
        } catch {
            Write-Log "✗ 사용자 '$UserName' 처리 중 오류: $($_.Exception.Message)" "Red"
        }
    } else {
        Write-Log "⚠ 사용자 건너뜀 (이미 존재): $UserName" "Yellow"
        
        # 이미 존재하는 경우 그룹 멤버십만 재확인
        try {
            Add-ADGroupMember -Identity $GroupName -Members $UserName -ErrorAction SilentlyContinue
        } catch {}
    }
}

Write-Log "========== 모든 작업 완료 ==========" -Color Cyan