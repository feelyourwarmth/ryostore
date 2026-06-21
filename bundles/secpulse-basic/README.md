# SecPulse Basic

A starter cyber lab: the minimum to work Hack The Box and TryHackMe rooms on Ryoku without turning the desktop into Kali. It covers the full beginner flow, connect to the lab VPN, scan and enumerate the target, fuzz web content, attack logins and databases, crack hashes, and inspect traffic. The heavier recon and exploitation tooling lives in SecPulse Advanced.

## What it installs

| Tool | What it is | Source | Upstream |
| --- | --- | --- | --- |
| nmap | Network and port scanner with service detection and NSE scripts. | pacman | https://nmap.org |
| gobuster | Directory, DNS, and vhost brute forcer written in Go. | pacman | https://github.com/OJ/gobuster |
| openvpn | VPN client for connecting to HTB and THM lab networks. | pacman | https://openvpn.net/community/ |
| seclists | Wordlist collection for fuzzing and brute forcing, includes rockyou. | AUR | https://github.com/danielmiessler/SecLists |
| openbsd-netcat | OpenBSD netcat, the nc command for shells, banners, and port checks. | pacman | https://man.openbsd.org/nc.1 |
| ffuf | Fast web fuzzer for content, parameter, and vhost discovery. | Go | https://github.com/ffuf/ffuf |
| sqlmap | Automatic SQL injection detection and database takeover. | pacman | https://sqlmap.org |
| hydra | Network login brute forcer for SSH, FTP, HTTP, and more. | pacman | https://github.com/vanhauser-thc/thc-hydra |
| john | John the Ripper jumbo password and hash cracker. | pacman | https://www.openwall.com/john/ |
| whois | WHOIS client for domain and IP registration lookups. | pacman | https://github.com/rfc1036/whois |
| bind | DNS query tools dig, host, and nslookup. | pacman | https://www.isc.org/bind/ |
| smbclient | Samba SMB client for share access and enumeration. | pacman | https://www.samba.org |
| enum4linux-ng | Maintained SMB and Windows enumeration tool with JSON output. | pipx | https://github.com/cddmp/enum4linux-ng |
| wireshark-qt | GUI network protocol analyzer; also installs tshark. | pacman | https://www.wireshark.org |

Install it from **Settings, Extras, SecPulse Basic, Install all**, or pick individual items. Anything already on the system is detected and skipped, so re-running only fills the gaps.

ffuf installs via go install and enum4linux-ng via pipx, both into ~/.local/bin. seclists is large (it bundles rockyou), so expect a longer install. For non-root packet capture, add yourself to the wireshark group and re-login.
