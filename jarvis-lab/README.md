# Jarvis Lab

Home enterprise lab on VMware Workstation.

## Plan

| Item | Value |
|---|---|
| Domain | `jarvis.lab` (NetBIOS `JARVIS`) |
| DC01 | Windows Server 2022 Standard (Desktop Experience), 4 GB RAM, 2 vCPU, 60 GB |
| DC01 IP | `<NAT subnet>.10`, gateway = VMware NAT gateway (written to `C:\jarvis-lab-network.txt` on DC01) |
| Network | VMware NAT (VMnet8) |

## Steps

1. Create DC01 with the VMware New Virtual Machine wizard and install Windows Server 2022.
   The original hand-written `DC01.vmx` would not start (unsupported hardware version, then broken PCI slot layout), so it was replaced with a wizard-created VM.
2. Install VMware Tools (VM > Install VMware Tools) so copy/paste works.
3. Run `scripts/01-prepare-dc01.ps1` in an Administrator PowerShell on DC01: fixed IP, AD DS role, rename to DC01, restart.
4. Run `scripts/02-promote-dc01.ps1`: creates the `jarvis.lab` forest with DNS, restarts.
5. Next: OUs, users, groups, DHCP, shares, GPOs, Windows 11 client join.

## Status

- [x] DC01 VM recreated, Windows Server 2022 installing
- [ ] VMware Tools
- [ ] Step 1 - prepare
- [ ] Step 2 - promote to DC
