<div align="center">

<img src="https://readme-typing-svg.demolab.com?font=Fira+Code&weight=700&size=32&pause=1000&color=00FF41&center=true&vCenter=true&width=600&lines=SubRecon+%7C+Subdomain+Intelligence;Passive+OSINT+%2B+DNS+Filtering;Fast.+Silent.+Accurate." alt="Typing SVG" />

<br/>

![Version](https://img.shields.io/badge/version-8.1.0-00FF41?style=for-the-badge&logo=github&logoColor=white)
![Python](https://img.shields.io/badge/Python-3.8+-3776AB?style=for-the-badge&logo=python&logoColor=white)
![Platform](https://img.shields.io/badge/Platform-Linux-FCC624?style=for-the-badge&logo=linux&logoColor=black)
![License](https://img.shields.io/badge/License-MIT-red?style=for-the-badge)
![Author](https://img.shields.io/badge/Author-EnCrYpTeD05-blueviolet?style=for-the-badge&logo=github)
![Status](https://img.shields.io/badge/Status-Active-00FF41?style=for-the-badge)

<br/>

```
   _____       ____           ______          
  / ___/__  __/ __ )_______  / ____/___  ____ 
  \__ \/ / / / __  / ___/ _ \/ /   / __ \/ __ \
 ___/ / /_/ / /_/ / /  /  __/ /___/ /_/ / / / /
/____/\__,_/_____/_/   \___/\____/\____/_/ /_/ 
```

**A fast, passive subdomain enumeration & false-positive filtering tool**

*Built for security professionals, bug bounty hunters & red teamers*

</div>

---

## 📌 Table of Contents

- [Overview](#-overview)
- [Features](#-features)
- [Reconnaissance Sources](#-reconnaissance-sources)
- [Installation](#-installation)
- [Usage](#-usage)
- [Sample Output](#-sample-output)
- [File Structure](#-file-structure)
- [Disclaimer](#-disclaimer)
- [Author](#-author)

---

## 🔍 Overview

**SubRecon** is a fast, single-file Python tool for passive subdomain enumeration with intelligent false-positive filtering. It queries multiple OSINT sources in parallel, normalizes and deduplicates results, detects wildcard DNS, and exports a clean verified subdomain list — all with a live Rich UI dashboard showing real-time progress.



> ⚡ Fast. Silent. Accurate.

---

## ✨ Features

<table>
<tr>
<td>

**🌐 Passive Collection**
- 5 built-in OSINT sources queried in parallel
- Auto-integration of external tools (subfinder, amass, etc.)
- Concurrent multi-threaded collection
- Internet connectivity check before starting

</td>
<td>

**🧹 Normalization & Deduplication**
- Strips wildcards, protocols, ports, and paths
- Filters out-of-scope and root-domain entries
- Hostname syntax validation (RFC-compliant)
- Duplicate removal with live counter

</td>
</tr>
<tr>
<td>

**🔬 DNS Filtering**
- Wildcard DNS detection (5-probe method)
- DNS resolution via `dnspython` or `socket`
- A, AAAA, and CNAME record checking
- DNS failure ≠ false positive (historical subdomains preserved)

</td>
<td>

**📊 Live Dashboard & Output**
- Rich UI with live progress bars & counters
- Exports clean `subdomains.txt`
- Exports `false_positive.txt` with reasons
- Falls back to plain terminal if Rich not installed

</td>
</tr>
</table>

---

## 🛰️ Reconnaissance Sources

SubRecon queries the following **passive OSINT sources** — no direct requests to the target:

| # | Source | Type | Description |
|---|--------|------|-------------|
| 1 | **crt.sh** | Certificate Transparency | Queries SSL/TLS certificate logs for subdomain exposure |
| 2 | **HackerTarget** | DNS Aggregator | Passive DNS data via HackerTarget's hostsearch API |
| 3 | **AlienVault OTX** | Threat Intelligence | Open Threat Exchange passive DNS records |
| 4 | **URLScan.io** | Web Scanner | Historical scan results containing subdomain data |
| 5 | **RapidDNS** | DNS Search Engine | Fast passive subdomain enumeration |

### 🔧 External Tool Integration (Auto-detected)

If any of these tools are installed, SubRecon automatically uses them as additional sources:

| Tool | Description |
|------|-------------|
| **subfinder** | Fast passive subdomain discovery by ProjectDiscovery |
| **amass** | In-depth passive enumeration by OWASP |
| **assetfinder** | Lightweight subdomain finder by tomnomnom |
| **sublist3r** | Multi-engine subdomain enumeration |

> Disable external tools with `--no-external-tools`

---

## ⚙️ Installation

### Quick Install (Recommended)

```bash
git clone https://github.com/EnCrYpTeD05/subrecon.git
cd subrecon
chmod +x install.sh
./install.sh
```

### Manual Install

```bash
pip3 install rich dnspython
python3 subrecon.py --help
```

### Requirements

| Dependency | Purpose |
|------------|---------|
| `Python 3.8+` | Core runtime |
| `rich` | Live UI dashboard & progress bars |
| `dnspython` | DNS resolution & wildcard detection |

> `rich` and `dnspython` are optional — SubRecon falls back gracefully without them.

---

## 🚀 Usage

```bash
python3 subrecon.py <domain> [OPTIONS]
```

### Arguments & Options

```
Positional:
  domain                    Target root domain (e.g. example.com)

Optional:
  --timeout FLOAT           DNS and source request timeout (default: 8.0s)
  --collector-workers INT   Concurrent source threads (default: 9)
  --filter-workers INT      Concurrent DNS filter threads (default: 120)
  --no-external-tools       Skip subfinder, amass, assetfinder, sublist3r
```

### Examples

```bash
# Basic enumeration
python3 subrecon.py example.com

# Custom timeout and more collector threads
python3 subrecon.py example.com --timeout 15 --collector-workers 15

# Skip external tools (use built-in sources only)
python3 subrecon.py example.com --no-external-tools

# High-speed filtering with more workers
python3 subrecon.py example.com --filter-workers 200
```

---

## 📊 Sample Output

```
   _____       ____           ______          
  / ___/__  __/ __ )_______  / ____/___  ____ 
  \__ \/ / / / __  / ___/ _ \/ /   / __ \/ __ \
 ___/ / /_/ / /_/ / /  /  __/ /___/ /_/ / / / /
/____/\__,_/_____/_/   \___/\____/\____/_/ /_/ 

Created by EnCrYpTeD05

⠸  Collecting from all sources  ████████████████░░░░░░░  72%  0:00:14
⠴  Filtering clear false positives  ████████████████████  100%  0:00:08

┌─────────────────── Live Counters ────────────────────┐
│ Sources Processed      7/9                           │
│ Raw Collected          1842                          │
│ Normalized             1204                          │
│ Unique Subdomains      876                           │
│ Exported Subdomains    821                           │
│ Duplicates Removed     328                           │
│ False Positives        55                            │
│ Elapsed Time           22.4s                         │
└──────────────────────────────────────────────────────┘

Domain: example.com
Sources Processed: 9/9
Raw Collected: 1842
Normalized: 1204
Unique Subdomains: 876
Exported Subdomains: 821
Duplicates Removed: 328
False Positives: 55
Output File: subdomains.txt
False Positive File: false_positive.txt
```

---

## 📁 File Structure

```
subrecon/
├── subrecon.py           # Main tool (single-file)
├── install.sh            # Auto-installer
├── subdomains.txt        # Clean output (auto-created)
├── false_positive.txt    # Filtered entries with reasons (auto-created)
└── README.md
```

---

## ⚠️ Disclaimer

> **SubRecon is intended for authorized security testing and educational purposes only.**
>
> Usage of this tool against systems without explicit written permission is **illegal** and **unethical**. The author takes **no responsibility** for any misuse or damage caused by this tool.
>
> Always obtain proper authorization before conducting any reconnaissance activities.

---

## 👤 Author

<div align="center">

```
╔══════════════════════════════════════╗
║                                      ║
║    Created with 🖤 by EnCrYpTeD05    ║
║                                      ║
╚══════════════════════════════════════╝
```

[![GitHub](https://img.shields.io/badge/GitHub-EnCrYpTeD05-181717?style=for-the-badge&logo=github)](https://github.com/EnCrYpTeD05)
[![Website](https://img.shields.io/badge/Website-encrypted05.github.io-00FF41?style=for-the-badge&logo=googlechrome&logoColor=white)](https://encrypted05.github.io/)

</div>

---

<div align="center">

**⭐ If SubRecon helped you, drop a star! It keeps the project alive.**

![Footer](https://capsule-render.vercel.app/api?type=waving&color=00FF41&height=100&section=footer)

</div>
