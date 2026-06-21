# SecPulse Advanced

The heavier security tier for users who actually run engagements. It chains OWASP Amass and the ProjectDiscovery suite into an enumeration to scanning pipeline, adds Nikto, WhatWeb, wafw00f, masscan, and feroxbuster for web and port recon, covers firewall editing with ufw, gufw, and firewalld, and provides proxied, anonymized execution with proxychains-ng and Tor. It assumes SecPulse Basic is also installed (nmap, the seclists wordlists), so it does not duplicate that starter core.

## What it installs

| Tool | What it is | Source | Upstream |
| --- | --- | --- | --- |
| nikto | Web server scanner for dangerous files, stale software, and misconfigurations. | pacman | https://github.com/sullo/nikto |
| whatweb | Fingerprints sites: CMS, frameworks, servers, and technologies. | AUR | https://github.com/urbanadventurer/WhatWeb |
| wafw00f | Detects and fingerprints web application firewalls. | AUR | https://github.com/EnableSecurity/wafw00f |
| python-shodan | Official Shodan CLI and library for the internet scan database. | pacman | https://github.com/achillean/shodan-python |
| amass | OWASP attack surface mapping and subdomain enumeration. | AUR | https://github.com/owasp-amass/amass |
| subfinder | Passive subdomain discovery from many public sources. | Go | https://github.com/projectdiscovery/subfinder |
| httpx | Fast HTTP toolkit for probing hosts, titles, status codes, and tech. | Go | https://github.com/projectdiscovery/httpx |
| nuclei | Template-based vulnerability scanner with a community rule library. | Go | https://github.com/projectdiscovery/nuclei |
| naabu | Fast Go SYN and CONNECT port scanner. | Go | https://github.com/projectdiscovery/naabu |
| masscan | Asynchronous mass TCP port scanner for large ranges. | pacman | https://github.com/robertdavidgraham/masscan |
| feroxbuster | Recursive web content and directory discovery, written in Rust. | AUR | https://github.com/epi052/feroxbuster |
| ufw | Uncomplicated Firewall, a simple CLI front end for netfilter. | pacman | https://launchpad.net/ufw |
| gufw | Graphical front end for ufw. | pacman | https://github.com/costales/gufw |
| firewalld | Dynamic firewall daemon with zones; ships the firewall-config GUI. | pacman | https://firewalld.org |
| proxychains-ng | Routes TCP traffic of existing programs through proxy chains. | pacman | https://github.com/rofl0r/proxychains-ng |
| tor | Anonymizing overlay network providing a local SOCKS proxy. | pacman | https://www.torproject.org |

Install it from **Settings, Extras, SecPulse Advanced, Install all**, or pick individual items. Anything already on the system is detected and skipped, so re-running only fills the gaps.

Assumes SecPulse Basic for nmap and the seclists wordlists, so it does not repeat them. The ProjectDiscovery tools (subfinder, httpx, nuclei, naabu) install via go install into ~/.local/bin. ufw and firewalld are mutually exclusive; enable only one.
