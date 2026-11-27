# Jarvis Lab - Step 2: promote DC01 to the first domain controller of jarvis.lab
# Run inside DC01, as Administrator, after step 1 and its restart.
# Asks for the DSRM (Directory Services Restore Mode) password, then restarts by itself.
$ErrorActionPreference = 'Stop'

$dsrm = Read-Host 'Choose a DSRM password (write it down)' -AsSecureString

Install-ADDSForest `
    -DomainName 'jarvis.lab' `
    -DomainNetbiosName 'JARVIS' `
    -InstallDns `
    -SafeModeAdministratorPassword $dsrm `
    -Force
