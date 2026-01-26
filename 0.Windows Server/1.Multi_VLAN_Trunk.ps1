# LAB 환경에서 Internal - Trunk Adapter 설정 스크립트 
$TeamName = "Lab-Internal-Trunk"
$InternalNIC = "Ethernet0"

# NIC Teaming 설정 및 논리적 Interface의 IP 비활성화, 가상화 환경이므로 LB알고리즘은 Transport로 설정, 물리환경에서는 Dynamic으로 설정 권장 
New-NetLbfoTeam -Name $TeamName -TeamMembers $InternalNIC -TeamingMode SwitchIndependent -LoadBalancingAlgorithm Transport -Confirm:$false
Disable-NetAdapterBinding -Name $TeamName -ComponentID ms_tcpip -Confirm:$false
Disable-NetAdapterBinding -Name $TeamName -ComponentID ms_tcpip6 -Confirm:$false

# Teaming에 VLAN 추가 및 Gateway IP 설정, IPv6 비활성화, Interface Metric 설정 
10..10 | ForEach-Object {
    $vName = "VLAN$_"
    Add-NetLbfoTeamNic -Team $TeamName -VlanID $_ -Name $vName -Confirm:$false
    New-NetIPAddress -InterfaceAlias $vName -IPAddress "10.10.$_.1" -PrefixLength 24
    Disable-NetAdapterBinding -Name $vName -ComponentID ms_tcpip6 -Confirm:$false 
    Set-NetIPInterface -InterfaceAlias $vName -InterfaceMetric $_
}

# Interface Metric 확인 
Get-NetIPInterface -AddressFamily IPv4 | Select-Object InterfaceAlias, InterfaceMetric, ConnectionState | Sort-Object InterfaceMetric
