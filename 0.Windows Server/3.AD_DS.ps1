## CLI 기반으로 AD DS 설치 및 도메인 컨트롤러 구성 스크립트 

# 변수 설정 
$DomainName = "vclass.local"
$NetbiosName = "VCLASS"
$DSRMPassword = ConvertTo-SecureString "VMware123!" -AsPlainText -Force # DSRM 암호 설정 

# AD DS 역할 설치 
Install-WindowsFeature AD-Domain-Services -IncludeManagementTools

# 새 포리스트 및 도메인 컨트롤러 설치 
Import-Module ADDSDeployment
Install-ADDSForest `
    -DomainName $DomainName -DomainNetbiosName $NetbiosName `
    -InstallDns:$true -CreateDnsDelegation:$false `
    -DatabasePath "C:\Windows\NTDS" -SysvolPath "C:\Windows\SYSVOL" -LogPath "C:\Windows\NTDS" `
    -ForestMode "WinThreshold" -DomainMode "WinThreshold" `
    -SafeModeAdministratorPassword $DSRMPassword `
    -Force:$true -NoRebootOnCompletion:$false
