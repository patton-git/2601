# Domain Password Policy Degraded 설정 스크립트
# [변수 설정] 
# 사용 중인 도메인명을 입력하세요. (예: vclass.local) 
$DomainName = "vclass.local" 

# 1. Active Directory 모듈 로드 
Import-Module ActiveDirectory

# 2. 암호 정책 변경 실행 
# 복잡성 해제, 만료 제한 해제, 히스토리 기억 안 함 설정을 수행합니다. 
Set-ADDefaultDomainPasswordPolicy -Identity $DomainName `
    -ComplexityEnabled $false `
    -MaxPasswordAge ([TimeSpan]::Zero) `
    -MinPasswordAge ([TimeSpan]::Zero) `
    -PasswordHistoryCount 0 `
    -MinPasswordLength 0

# 3. 그룹 정책(GPO) 즉시 업데이트 
gpupdate /force

# 4. 변경된 정책 최종 확인 
Get-ADDefaultDomainPasswordPolicy -Identity $DomainName
