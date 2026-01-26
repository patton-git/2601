## 주요 변수 설정
$DomainPath = "DC=vclass,DC=local" 
$OUName = "Student"
$GroupName = "Students"
$OUPath = "OU=$OUName,$DomainPath"
$Password = "VMware1!"
$UserCount = 0..10

Write-Host "`n========== AD 환경 구성 시작 ==========" -ForegroundColor Cyan

# 1. OU 및 그룹 생성 (한 번에 처리)
if (-not (Get-ADOrganizationalUnit -Filter "Name -eq '$OUName'" -SearchBase $DomainPath)) {
    New-ADOrganizationalUnit -Name $OUName -Path $DomainPath -PassThru | Out-Null
    Write-Host "✓ OU '$OUName' 생성 완료." -ForegroundColor Green
}

if (-not (Get-ADGroup -Filter "Name -eq '$GroupName'")) {
    New-ADGroup -Name $GroupName -GroupCategory Security -GroupScope Global -Path $OUPath -PassThru | Out-Null
    Write-Host "✓ 그룹 '$GroupName' 생성 완료." -ForegroundColor Green
}

# 2. 사용자 생성 및 그룹 등록 (Splatting 및 파이프라인 활용)
$SecurePassword = ConvertTo-SecureString $Password -AsPlainText -Force

foreach ($i in $UserCount) {
    $UserName = "S{0:d2}" -f $i
    
    # 사용자 존재 여부 확인 후 없으면 생성
    if (-not (Get-ADUser -Filter "SamAccountName -eq '$UserName'")) {
        $UserParams = @{
            Name = $UserName
            SamAccountName = $UserName
            Path = $OUPath
            Enabled = $true
            AccountPassword = $SecurePassword
            PasswordNeverExpires = $true
        }
        New-ADUser @UserParams
        Write-Host "✓ 사용자 '$UserName' 생성 완료." -ForegroundColor Green
    }

    # 그룹 멤버십 등록 (ErrorAction으로 이미 있는 경우 조용히 넘어감)
    Add-ADGroupMember -Identity $GroupName -Members $UserName -ErrorAction SilentlyContinue
}

Write-Host "`n모든 작업이 완료되었습니다." -ForegroundColor Cyan