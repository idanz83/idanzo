# Jarvis Lab - Step 3: OU tree, department groups and sample users in jarvis.lab
# Run on DC01 as JARVIS\Administrator. Safe to run more than once (skips what exists).
$ErrorActionPreference = 'Stop'
Import-Module ActiveDirectory

$domainDN   = (Get-ADDomain).DistinguishedName
$root       = 'Jarvis'
$rootDN     = "OU=$root,$domainDN"
$userPass   = ConvertTo-SecureString 'Welcome!2026' -AsPlainText -Force
$departments = 'IT','HR','Finance','Sales'

function New-OUIfMissing($name, $path) {
    if (-not (Get-ADOrganizationalUnit -Filter "Name -eq '$name'" -SearchBase $path -SearchScope OneLevel -ErrorAction SilentlyContinue)) {
        New-ADOrganizationalUnit -Name $name -Path $path -ProtectedFromAccidentalDeletion $true
        Write-Host "OU  $name,$path" -ForegroundColor Green
    }
}

# OU=Jarvis
#   OU=Users\<Department>, OU=Groups, OU=Computers\Workstations, OU=Servers
New-OUIfMissing $root $domainDN
foreach ($ou in 'Users','Groups','Computers','Servers') { New-OUIfMissing $ou $rootDN }
New-OUIfMissing 'Workstations' "OU=Computers,$rootDN"
foreach ($d in $departments) { New-OUIfMissing $d "OU=Users,$rootDN" }

# One global security group per department
foreach ($d in $departments) {
    $g = "GRP-$d"
    if (-not (Get-ADGroup -Filter "Name -eq '$g'" -ErrorAction SilentlyContinue)) {
        New-ADGroup -Name $g -GroupScope Global -GroupCategory Security -Path "OU=Groups,$rootDN"
        Write-Host "GRP $g" -ForegroundColor Green
    }
}

# Two sample users per department
$users = @(
    @{ First='Dana';  Last='Levi';    Dept='IT' },
    @{ First='Yossi'; Last='Cohen';   Dept='IT' },
    @{ First='Noa';   Last='Mizrahi'; Dept='HR' },
    @{ First='Avi';   Last='Peretz';  Dept='HR' },
    @{ First='Maya';  Last='Biton';   Dept='Finance' },
    @{ First='Eli';   Last='Friedman';Dept='Finance' },
    @{ First='Shira'; Last='Azulay';  Dept='Sales' },
    @{ First='Omer';  Last='Katz';    Dept='Sales' }
)
foreach ($u in $users) {
    $sam = ($u.First.Substring(0,1) + $u.Last).ToLower()
    if (-not (Get-ADUser -Filter "SamAccountName -eq '$sam'" -ErrorAction SilentlyContinue)) {
        New-ADUser -Name "$($u.First) $($u.Last)" -GivenName $u.First -Surname $u.Last `
            -SamAccountName $sam -UserPrincipalName "$sam@jarvis.lab" `
            -Department $u.Dept -Path "OU=$($u.Dept),OU=Users,$rootDN" `
            -AccountPassword $userPass -Enabled $true -ChangePasswordAtLogon $true
        Add-ADGroupMember -Identity "GRP-$($u.Dept)" -Members $sam
        Write-Host "USR $sam ($($u.Dept))" -ForegroundColor Green
    }
}

# New computers joining the domain land in Jarvis\Computers\Workstations
redircmp "OU=Workstations,OU=Computers,$rootDN" | Out-Null

Write-Host "`nDone. Users:" -ForegroundColor Cyan
Get-ADUser -Filter * -SearchBase $rootDN -Properties Department |
    Select-Object SamAccountName, Department | Format-Table -AutoSize
