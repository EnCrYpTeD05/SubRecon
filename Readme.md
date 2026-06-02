<div align="center">

# 🛰️ SubRecon

### Fast Multi-Source Passive Subdomain Discovery Tool

![Version](https://img.shields.io/badge/Version-1.0-purple?style=for-the-badge)
![Python](https://img.shields.io/badge/Python-3.10+-blue?style=for-the-badge&logo=python)
![Platform](https://img.shields.io/badge/Platform-Linux-orange?style=for-the-badge&logo=linux)
![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)
![Author](https://img.shields.io/badge/Author-EnCrYpTeD05-red?style=for-the-badge)

**Created by [EnCrYpTeD05](https://github.com/EnCrYpTeD05)**

*Discover More. Filter Smarter.* 🛰️

</div>

---

## 📌 Overview

SubRecon is a lightweight multi-source passive subdomain discovery tool designed for security researchers and asset inventory workflows. It aggregates results from multiple OSINT sources and supported external tools, normalizes data, removes duplicates, performs wildcard detection, filters obvious false positives, and exports clean results.

---

## ⚙️ Workflow

```text
Domain
   │
   ▼
Internal Sources
   +
External Tools
   ▼
Merge Results
   ▼
Normalize
   ▼
Deduplicate
   ▼
Wildcard Detection
   ▼
False Positive Filtering
   ▼
Export Results
```

---

## 🚀 Features

| Feature | Description |
|----------|-------------|
| 🌐 Multi-Source Discovery | Collects subdomains from multiple passive OSINT sources |
| ⚡ Concurrent Collection | Parallel collection from all available sources |
| 🔄 Deduplication | Automatic duplicate removal |
| 🧹 Hostname Normalization | Cleans malformed entries |
| 🔬 Wildcard Detection | Multi-probe wildcard DNS detection |
| 🛡️ False Positive Filtering | Filters clearly invalid entries |
| 📊 Live Dashboard | Progress bars and live counters |
| 🔌 External Tool Support | Subfinder, Amass, Assetfinder, Sublist3r |

---

## 🛰️ Reconnaissance Sources

### Internal Sources

1. crt.sh
2. HackerTarget
3. AlienVault OTX
4. URLScan
5. RapidDNS

### External Tools (Auto Detected)

1. Subfinder
2. Amass
3. Assetfinder
4. Sublist3r

---

## 🛠️ Installation

```bash
git clone https://github.com/EnCrYpTeD05/SubRecon.git
cd SubRecon
chmod +x install.sh
./install.sh
```

### Requirements

- Python 3.10+
- rich
- dnspython

---

## 📖 Usage

```bash
python3 subrecon.py example.com
```

```bash
python3 subrecon.py example.com --timeout 15
```

```bash
python3 subrecon.py example.com --filter-workers 200
```

```bash
python3 subrecon.py example.com --no-external-tools
```

---

## 📂 Output Files

| File | Description |
|--------|-------------|
| subdomains.txt | Discovered subdomains |
| false_positive.txt | Filtered entries with reasons |

---

## ⚠️ Disclaimer

This project is intended for authorized security testing, research, and educational purposes only.

Always obtain proper authorization before conducting reconnaissance activities.

The author is not responsible for misuse of this software.

---

## 👤 Author

**EnCrYpTeD05**

GitHub: https://github.com/EnCrYpTeD05

Website: https://encrypted05.github.io/

---

⭐ If SubRecon helped you, consider starring the repository.
