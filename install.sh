#!/usr/bin/env bash

# ============================================================
#   SubRecon Installer - by EnCrYpTeD05
#   Passive Subdomain Enumeration & Filtering Tool
# ============================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

TICK="${GREEN}✔${NC}"
CROSS="${RED}✖${NC}"
WARN="${YELLOW}⚠${NC}"

QUIET_OUT=/dev/null

clear_line() { printf "\r\033[K"; }

print_banner() {
    clear
    echo -e "${CYAN}"
    echo "     _____       ____           ______          "
    echo "    / ___/__  __/ __ )_______  / ____/___  ____ "
    echo "    \__ \/ / / / __  / ___/ _ \/ /   / __ \/ __ \\"
    echo "   ___/ / /_/ / /_/ / /  /  __/ /___/ /_/ / / / /"
    echo "  /____/\__,_/_____/_/   \___/\____/\____/_/ /_/ "
    echo -e "${NC}"
    echo -e "  ${DIM}${CYAN}Passive Subdomain Enumeration & Filtering Tool${NC}"
    echo -e "  ${DIM}Created by ${MAGENTA}EnCrYpTeD05${NC}"
    echo ""
    echo -e "  ${DIM}────────────────────────────────────────────────────${NC}"
    echo ""
}

# Progress bar: progress_bar <current> <total> <label>
progress_bar() {
    local current=$1
    local total=$2
    local label=$3
    local width=40
    local filled=$(( current * width / total ))
    local empty=$(( width - filled ))
    local percent=$(( current * 100 / total ))

    local bar_filled=""
    for ((i=0; i<filled; i++)); do bar_filled+="█"; done
    local bar_empty=""
    for ((i=0; i<empty; i++)); do bar_empty+="░"; done

    local colour
    if   (( percent < 35 )); then colour="${RED}"
    elif (( percent < 70 )); then colour="${YELLOW}"
    else                          colour="${GREEN}"
    fi

    printf "\r  ${CYAN}%-28s${NC}  ${colour}[${bar_filled}${DIM}${bar_empty}${NC}${colour}]${NC}  ${BOLD}%3d%%${NC}" \
        "$label" "$percent"
}

STEP=0
TOTAL_STEPS=4

run_step() {
    local label="$1"
    local cmd="$2"

    STEP=$(( STEP + 1 ))
    progress_bar "$STEP" "$TOTAL_STEPS" "Installing..."
    printf "  ${DIM}%s${NC}" "$label"

    eval "$cmd" >$QUIET_OUT 2>&1
    local exit_code=$?

    clear_line
    progress_bar "$STEP" "$TOTAL_STEPS" "Installing..."

    if [[ $exit_code -eq 0 ]]; then
        printf "  ${TICK}  ${DIM}%s${NC}\n" "$label"
    else
        printf "  ${CROSS}  ${RED}%s — failed (exit %d)${NC}\n" "$label" "$exit_code"
    fi
    sleep 0.1
}

has_cmd() { command -v "$1" &>/dev/null; }

# ── Network check ─────────────────────────────────────────────
check_internet() {
    printf "  ${DIM}Checking internet connectivity...${NC}"
    if python3 -c "import socket; socket.create_connection(('1.1.1.1', 53), timeout=5)" >$QUIET_OUT 2>&1; then
        clear_line
        printf "  ${TICK}  ${DIM}Internet connection OK${NC}\n"
        return 0
    else
        clear_line
        echo -e "  ${CROSS}  ${RED}No internet connection detected.${NC}"
        echo -e "  ${DIM}Please connect to the internet and re-run the installer.${NC}"
        echo ""
        exit 1
    fi
}

# ── Python version check ──────────────────────────────────────
check_python() {
    if ! has_cmd python3; then
        echo -e "  ${CROSS}  ${RED}Python3 not found. Please install Python 3.10+ first.${NC}"
        exit 1
    fi

    local major minor
    major=$(python3 -c "import sys; print(sys.version_info.major)")
    minor=$(python3 -c "import sys; print(sys.version_info.minor)")
    local ver="${major}.${minor}"

    if (( major < 3 || (major == 3 && minor < 10) )); then
        echo -e "  ${CROSS}  ${RED}Python $ver detected.${NC}"
        echo -e "  ${DIM}SubRecon requires Python 3.10 or newer (uses modern type hint syntax).${NC}"
        echo ""
        exit 1
    fi

    echo -e "  ${TICK}  ${DIM}Python $ver detected${NC}"
}

# ── pip install with PEP668 fallback ─────────────────────────
pip_install() {
    local pkg="$1"
    if python3 -m pip install -q "$pkg" >$QUIET_OUT 2>&1; then
        return 0
    fi
    # Kali / PEP668 fallback
    python3 -m pip install -q "$pkg" --break-system-packages >$QUIET_OUT 2>&1
}

# ══════════════════════════════════════════════════════════════
#   MAIN
# ══════════════════════════════════════════════════════════════

print_banner

echo -e "  ${CYAN}▶${NC}  ${BOLD}Starting SubRecon installation...${NC}"
echo -e "  ${DIM}All dependencies will be installed silently.${NC}"
echo ""
sleep 0.8

# ── Pre-flight checks ─────────────────────────────────────────
progress_bar 0 "$TOTAL_STEPS" "Checking system..."
echo ""
echo ""

check_internet
check_python

echo ""
echo -e "  ${MAGENTA}●${NC}  ${CYAN}${BOLD}Installing dependencies...${NC}"
echo ""

run_step "rich  (live UI & progress bars)"   "pip_install rich"
run_step "dnspython  (DNS resolution)"       "pip_install dnspython"

echo ""
echo -e "  ${MAGENTA}●${NC}  ${CYAN}${BOLD}Setting up environment...${NC}"
echo ""

run_step "Setting script permissions"        "chmod +x subrecon.py 2>/dev/null || true"

echo ""
echo -e "  ${DIM}Checking for optional external tools...${NC}"
echo ""

for tool in subfinder amass assetfinder sublist3r; do
    if has_cmd "$tool"; then
        printf "  ${TICK}  ${DIM}%-14s found — will be used automatically${NC}\n" "$tool"
    else
        printf "  ${DIM}  %-14s not found — skipped (optional)${NC}\n" "$tool"
    fi
done

echo ""
progress_bar "$TOTAL_STEPS" "$TOTAL_STEPS" "Installation"
echo ""
echo ""

echo -e "  ${DIM}────────────────────────────────────────────────────${NC}"
echo ""
echo -e "  ${GREEN}${BOLD}  ✔  SubRecon installed successfully!${NC}"
echo ""
echo -e "  ${CYAN}Usage:${NC}"
echo -e "    ${DIM}python3 subrecon.py example.com${NC}"
echo -e "    ${DIM}python3 subrecon.py example.com --timeout 15${NC}"
echo -e "    ${DIM}python3 subrecon.py example.com --no-external-tools${NC}"
echo -e "    ${DIM}python3 subrecon.py --help${NC}"
echo ""
echo -e "  ${DIM}Output files:${NC}"
echo -e "    ${DIM}subdomains.txt       — discovered subdomains${NC}"
echo -e "    ${DIM}false_positive.txt   — filtered entries with reasons${NC}"
echo ""
echo -e "  ${DIM}────────────────────────────────────────────────────${NC}"
echo ""
echo -e "  ${MAGENTA}${BOLD}  Created by EnCrYpTeD05${NC}  ${DIM}|  Happy Hunting 🎯${NC}"
echo ""
echo -e "  ${DIM}────────────────────────────────────────────────────${NC}"
echo ""
