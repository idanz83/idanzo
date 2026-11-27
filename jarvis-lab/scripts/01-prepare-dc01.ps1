# Jarvis Lab - Step 1: prepare DC01 (run inside the DC01 VM, as Administrator)
# - Converts the NAT DHCP lease into a fixed address: <same subnet>.10
# - Installs the AD DS role
# - Renames the computer to DC01 and restarts
$ErrorActionPreference = 'Stop'

$cfg = Get-NetIPConfiguration |
    Where-Object { $_.IPv4DefaultGateway -and $_.NetAdapter.Status -eq 'Up' } |
    Select-Object -First 1
if (-not $cfg) { throw 'No connected network adapter with a gateway was found. Check the VM network adapter (NAT).' }

$ifIndex = $cfg.InterfaceIndex
$oldIp   = $cfg.IPv4Address.IPAddress
$prefix  = $cfg.IPv4Address.PrefixLength
$gateway = $cfg.IPv4DefaultGateway.NextHop
$subnet  = ($oldIp -split '\.')[0..2] -join '.'
$newIp   = "$subnet.10"

Write-Host "Current IP: $oldIp/$prefix  Gateway: $gateway" -ForegroundColor Cyan
Write-Host "New fixed IP for DC01: $newIp/$prefix" -ForegroundColor Cyan

Set-NetIPInterface -InterfaceIndex $ifIndex -Dhcp Disabled
Get-NetIPAddress -InterfaceIndex $ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue |
    Remove-NetIPAddress -Confirm:$false
Get-NetRoute -InterfaceIndex $ifIndex -AddressFamily IPv4 -DestinationPrefix '0.0.0.0/0' -ErrorAction SilentlyContinue |
    Remove-NetRoute -Confirm:$false
New-NetIPAddress -InterfaceIndex $ifIndex -IPAddress $newIp -PrefixLength $prefix -DefaultGateway $gateway | Out-Null
Set-DnsClientServerAddress -InterfaceIndex $ifIndex -ServerAddresses $gateway

"DC01 IP=$newIp/$prefix GW=$gateway" | Set-Content C:\jarvis-lab-network.txt

Write-Host 'Installing AD DS role (a few minutes)...' -ForegroundColor Cyan
Install-WindowsFeature AD-Domain-Services -IncludeManagementTools | Out-Null

Write-Host 'Done. Renaming to DC01 and restarting...' -ForegroundColor Green
if ($env:COMPUTERNAME -ne 'DC01') { Rename-Computer -NewName 'DC01' -Restart -Force } else { Restart-Computer -Force }
