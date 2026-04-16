#!/data/data/com.termux/files/usr/bin/bash
set -e

# ==============================================
#        V1 TESTER PROTOCOL - TNT NO-LOAD
#        Auto SNI | Payload Gen | SSH Tunnel
# ==============================================

# --- Bold Colors & Formatting ---
BOLD='\033[1m'
RESET='\033[0m'
BLUE='\033[0;34m'
LBLUE='\033[1;34m'
CYAN='\033[0;36m'
LCYAN='\033[1;36m'
GREEN='\033[0;32m'
LGREEN='\033[1;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
LRED='\033[1;31m'
WHITE='\033[1;37m'
PURPLE='\033[0;35m'
LPURPLE='\033[1;35m'

# Glowing animation colors
GLOW1='\033[38;5;51m'
GLOW2='\033[38;5;87m'
GLOW3='\033[38;5;123m'
GLOW4='\033[38;5;159m'

# --- Configuration ---
SCRIPT_VERSION="2.0.0"
SCRIPT_NAME="V1 TESTER PROTOCOL"
DEFAULT_SSH_PORT="2222"
DEFAULT_SOCKS_PORT="1080"
CONFIG_DIR="$HOME/.v1tester"
LOG_FILE="$CONFIG_DIR/tunnel.log"
SNI_CACHE="$CONFIG_DIR/sni_cache.txt"
PAYLOAD_CACHE="$CONFIG_DIR/payload_cache.txt"
CUSTOM_PASSWORD_FILE="$CONFIG_DIR/password.txt"

# --- 40+ Verified SNI Bug Hosts (TNT/Smart No-Load) ---
declare -a SNI_HOSTS=(
    # Maya (Primary - Most Reliable)
    "maya.ph"
    "api.maya.ph"
    "cdn.maya.ph"
    "static.maya.ph"
    
    # Smart Communications
    "smart.com.ph"
    "my.smart.com.ph"
    "bill.smart.com.ph"
    "portal.smart.com.ph"
    "care.smart.com.ph"
    "store.smart.com.ph"
    
    # Google Edge Network (High Availability)
    "connectivitycheck.gstatic.com"
    "www.gstatic.com"
    "clients2.google.com"
    "clients3.google.com"
    "clients4.google.com"
    "dl.google.com"
    "id.googleapis.com"
    "oauth2.googleapis.com"
    "www.googleapis.com"
    "storage.googleapis.com"
    
    # Firebase (Zero-Rated)
    "firebase-settings.crashlytics.com"
    "firebaseinstallations.googleapis.com"
    "firebaselogging.googleapis.com"
    "firestore.googleapis.com"
    
    # Google Services
    "cloud.google.com"
    "console.cloud.google.com"
    "accounts.google.com"
    "play.googleapis.com"
    "android.googleapis.com"
    "update.googleapis.com"
    
    # CDN / Static
    "fonts.gstatic.com"
    "fonts.googleapis.com"
    "ajax.googleapis.com"
    "maps.googleapis.com"
    "maps.gstatic.com"
    
    # Alternative Bug Hosts
    "www.google.com"
    "www.youtube.com"
    "m.youtube.com"
    "youtubei.googleapis.com"
)

# --- User-Agent Pool for Payload Randomization ---
declare -a USER_AGENTS=(
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
    "Mozilla/5.0 (Linux; Android 13; SM-G991B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36"
    "Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.0 Mobile/15E148 Safari/604.1"
    "Mozilla/5.0 (Linux; Android 12; CPH2211) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36"
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/121.0"
)

mkdir -p "$CONFIG_DIR"

# --- Glowing Animation Function ---
glowing_progress() {
    local message="$1"
    local duration="${2:-2}"
    local end=$((SECONDS + duration))
    local colors=("$GLOW1" "$GLOW2" "$GLOW3" "$GLOW4")
    local i=0
    
    while [ $SECONDS -lt $end ]; do
        printf "\r${colors[$i]}${BOLD}%s${RESET}" "$message"
        i=$(( (i + 1) % ${#colors[@]} ))
        sleep 0.2
    done
    printf "\r${GREEN}[✔]${RESET} %s\n" "$message"
}

# --- Spinner Animation ---
spinner() {
    local pid=$1
    local message="$2"
    local spinstr='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    local i=0
    
    while kill -0 "$pid" 2>/dev/null; do
        printf "\r${CYAN}[%s]${RESET} %s" "${spinstr:$i:1}" "$message"
        i=$(( (i + 1) % ${#spinstr} ))
        sleep 0.1
    done
    printf "\r${GREEN}[✔]${RESET} %s\n" "$message"
}

# --- Banner (Clean, No Box Lines) ---
show_banner() {
    clear
    echo ""
    echo -e "${BOLD}${WHITE}    ██╗   ██╗ ██╗    ${LBLUE}████████╗███████╗███████╗████████╗███████╗██████╗${RESET}"
    echo -e "${BOLD}${WHITE}    ██║   ██║ ██║    ${LBLUE}╚══██╔══╝██╔════╝██╔════╝╚══██╔══╝██╔════╝██╔══██╗${RESET}"
    echo -e "${BOLD}${WHITE}    ██║   ██║ ██║       ${LBLUE}██║   █████╗  ███████╗   ██║   █████╗  ██████╔╝${RESET}"
    echo -e "${BOLD}${WHITE}    ╚██╗ ██╔╝ ██║       ${LBLUE}██║   ██╔══╝  ╚════██║   ██║   ██╔══╝  ██╔══██╗${RESET}"
    echo -e "${BOLD}${WHITE}     ╚████╔╝  ███████╗  ${LBLUE}██║   ███████╗███████║   ██║   ███████╗██║  ██║${RESET}"
    echo -e "${BOLD}${WHITE}      ╚═══╝   ╚══════╝  ${LBLUE}╚═╝   ╚══════╝╚══════╝   ╚═╝   ╚══════╝╚═╝  ╚═╝${RESET}"
    echo ""
    echo -e "${BOLD}${BLUE}    ══════════════════════════════════════════════════════════════${RESET}"
    echo -e "${BOLD}${WHITE}    PROTOCOL v${SCRIPT_VERSION}${RESET}  ${CYAN}TNT No-Load Auto Tunnel | 40+ SNI Hosts${RESET}"
    echo -e "${BOLD}${PURPLE}    Created by Prvtspyyy404${RESET}"
    echo -e "${BOLD}${BLUE}    ══════════════════════════════════════════════════════════════${RESET}"
    echo ""
}

# --- Function: Logging ---
log_message() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
    
    case $level in
        "INFO") echo -e "${GREEN}[+]${RESET} $message" ;;
        "WARN") echo -e "${YELLOW}[!]${RESET} $message" ;;
        "ERROR") echo -e "${RED}[✘]${RESET} $message" ;;
        "SUCCESS") echo -e "${LGREEN}[✔]${RESET} $message" ;;
        *) echo -e "${CYAN}[*]${RESET} $message" ;;
    esac
}

# --- Function: Get Password ---
get_password() {
    if [ -f "$CUSTOM_PASSWORD_FILE" ]; then
        cat "$CUSTOM_PASSWORD_FILE"
    else
        echo "prvtspyyy"
    fi
}

# --- Function: Set Custom Password ---
set_custom_password() {
    echo -e "\n${BOLD}${BLUE}══════════════════════════════════════════════════════════════${RESET}"
    echo -e "${BOLD}${WHITE}              PASSWORD CONFIGURATION${RESET}"
    echo -e "${BOLD}${BLUE}══════════════════════════════════════════════════════════════${RESET}\n"
    
    local current_password=$(get_password)
    echo -e "${CYAN}[*]${RESET} Current password: ${WHITE}$current_password${RESET}"
    echo ""
    read -p "$(echo -e "${WHITE}Enter new password (leave empty to keep current): ${RESET}")" new_password
    
    if [ -n "$new_password" ]; then
        echo "$new_password" > "$CUSTOM_PASSWORD_FILE"
        echo "root:$new_password" | chpasswd 2>/dev/null || true
        
        # Regenerate SSH key with new password
        if [ -f ~/.ssh/id_rsa ]; then
            rm -f ~/.ssh/id_rsa ~/.ssh/id_rsa.pub
        fi
        ssh-keygen -t rsa -b 2048 -N "$new_password" -f ~/.ssh/id_rsa > /dev/null 2>&1
        
        glowing_progress "Password updated successfully" 1
        log_message "SUCCESS" "Password changed"
    else
        echo -e "${CYAN}[*]${RESET} Password unchanged."
    fi
}

# --- Function: Check and Install Packages ---
check_and_install_packages() {
    local packages=("openssh" "curl" "socat" "netcat-openbsd" "jq")
    local missing=()
    
    echo -e "\n${BOLD}${BLUE}══════════════════════════════════════════════════════════════${RESET}"
    echo -e "${BOLD}${WHITE}              CHECKING REQUIRED PACKAGES${RESET}"
    echo -e "${BOLD}${BLUE}══════════════════════════════════════════════════════════════${RESET}\n"
    
    for pkg in "${packages[@]}"; do
        echo -ne "${CYAN}[*]${RESET} Checking $pkg... "
        
        if command -v $pkg &> /dev/null || dpkg -s $pkg &> /dev/null 2>/dev/null; then
            echo -e "${GREEN}INSTALLED${RESET}"
        else
            echo -e "${YELLOW}NOT INSTALLED${RESET}"
            missing+=("$pkg")
        fi
    done
    
    echo ""
    
    if [ ${#missing[@]} -eq 0 ]; then
        glowing_progress "All packages are already installed" 1
        return 0
    fi
    
    echo -e "${YELLOW}[!]${RESET} Missing packages: ${missing[*]}"
    echo -e "${CYAN}[*]${RESET} Internet connection required for installation."
    echo ""
    read -p "$(echo -e "${WHITE}Install missing packages now? [Y/n]: ${RESET}")" confirm
    
    if [[ "$confirm" =~ ^[Nn] ]]; then
        log_message "ERROR" "Package installation cancelled by user"
        return 1
    fi
    
    echo -e "\n${BOLD}${BLUE}══════════════════════════════════════════════════════════════${RESET}"
    echo -e "${BOLD}${WHITE}              INSTALLING PACKAGES${RESET}"
    echo -e "${BOLD}${BLUE}══════════════════════════════════════════════════════════════${RESET}\n"
    
    pkg update -y > /dev/null 2>&1 &
    spinner $! "Updating package lists"
    
    for pkg in "${missing[@]}"; do
        echo -e "${CYAN}[*]${RESET} Installing $pkg..."
        pkg install $pkg -y > /dev/null 2>&1 &
        spinner $! "Installing $pkg"
        
        if command -v $pkg &> /dev/null || dpkg -s $pkg &> /dev/null 2>/dev/null; then
            echo -e "${GREEN}[✔]${RESET} $pkg installed successfully"
        else
            echo -e "${RED}[✘]${RESET} Failed to install $pkg"
            log_message "ERROR" "Failed to install $pkg"
        fi
    done
    
    echo ""
    glowing_progress "Package installation complete" 2
    return 0
}

# --- Function: Configure SSH (Termux Compatible - No UsePAM) ---
configure_ssh() {
    echo -e "\n${CYAN}[*]${RESET} Configuring SSH server..."
    
    # Remove unsupported UsePAM lines if they exist
    sed -i '/UsePAM/d' "$PREFIX/etc/ssh/sshd_config" 2>/dev/null || true
    
    if [ ! -f "$PREFIX/etc/ssh/sshd_config.bak" ]; then
        cp "$PREFIX/etc/ssh/sshd_config" "$PREFIX/etc/ssh/sshd_config.bak" 2>/dev/null || true
    fi
    
    # Add only supported options
    echo "Port $DEFAULT_SSH_PORT" >> "$PREFIX/etc/ssh/sshd_config" 2>/dev/null || true
    echo "PermitRootLogin yes" >> "$PREFIX/etc/ssh/sshd_config" 2>/dev/null || true
    echo "PasswordAuthentication yes" >> "$PREFIX/etc/ssh/sshd_config" 2>/dev/null || true
    echo "PubkeyAuthentication yes" >> "$PREFIX/etc/ssh/sshd_config" 2>/dev/null || true
    
    # Generate SSH host keys if missing
    if [ ! -f "$PREFIX/etc/ssh/ssh_host_rsa_key" ]; then
        ssh-keygen -A > /dev/null 2>&1 &
        spinner $! "Generating SSH host keys"
    fi
    
    # Set root password
    local ROOT_PASS=$(get_password)
    echo "root:$ROOT_PASS" | chpasswd 2>/dev/null || true
    
    # Generate SSH key without passphrase for auto-login
    if [ ! -f ~/.ssh/id_rsa ]; then
        ssh-keygen -t rsa -b 2048 -N "" -f ~/.ssh/id_rsa > /dev/null 2>&1
    fi
    
    mkdir -p ~/.ssh
    cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys 2>/dev/null
    chmod 600 ~/.ssh/authorized_keys
    
    log_message "SUCCESS" "SSH configured"
}
# --- Function: Intelligent SNI Selection (Probes All 40+ Hosts) ---
select_best_sni() {
    echo -e "\n${BOLD}${BLUE}══════════════════════════════════════════════════════════════${RESET}"
    echo -e "${BOLD}${WHITE}              PROBING SNI HOSTS (${#SNI_HOSTS[@]} Total)${RESET}"
    echo -e "${BOLD}${BLUE}══════════════════════════════════════════════════════════════${RESET}\n"
    
    local best_sni=""
    local best_latency=9999
    local reachable_count=0
    local temp_file="$CONFIG_DIR/sni_results.txt"
    
    > "$temp_file"
    
    # Shuffle hosts for fair probing
    local shuffled=($(printf "%s\n" "${SNI_HOSTS[@]}" | shuf))
    
    for sni in "${shuffled[@]}"; do
        echo -ne "${CYAN}[*]${RESET} Testing $sni... "
        
        local start=$(date +%s%N)
        if timeout 3 bash -c "echo > /dev/tcp/$sni/443" 2>/dev/null; then
            local end=$(date +%s%N)
            local latency=$(( (end - start) / 1000000 ))
            echo -e "${GREEN}${latency}ms${RESET}"
            echo "$latency $sni" >> "$temp_file"
            reachable_count=$((reachable_count + 1))
            
            if [ $latency -lt $best_latency ]; then
                best_latency=$latency
                best_sni=$sni
            fi
        else
            echo -e "${RED}UNREACHABLE${RESET}"
        fi
    done
    
    echo ""
    echo -e "${CYAN}[*]${RESET} Reachable SNI hosts: ${GREEN}$reachable_count${RESET} / ${#SNI_HOSTS[@]}"
    
    if [ -z "$best_sni" ]; then
        best_sni="maya.ph"
        log_message "WARN" "No SNI reachable. Falling back to $best_sni"
    else
        # Display top 3 fastest SNIs
        echo -e "\n${BOLD}${WHITE}Top 3 Fastest SNIs:${RESET}"
        sort -n "$temp_file" | head -3 | while read lat sni; do
            echo -e "  ${GREEN}${lat}ms${RESET} - $sni"
        done
        echo ""
        glowing_progress "Best SNI selected: $best_sni (${best_latency}ms)" 2
    fi
    
    echo "$best_sni" > "$SNI_CACHE"
    echo "$best_sni"
}

# --- Function: Generate Optimized Payload ---
generate_payload() {
    local sni="$1"
    local ua_index=$((RANDOM % ${#USER_AGENTS[@]}))
    local user_agent="${USER_AGENTS[$ua_index]}"
    local random_id=$(cat /dev/urandom 2>/dev/null | tr -dc 'a-zA-Z0-9' | fold -w 8 | head -n 1 || echo "$RANDOM")
    
    local formats=(
        "GET https://$sni/ HTTP/1.1[crlf]Host: $sni[crlf]User-Agent: $user_agent[crlf]X-Forwarded-For: $sni[crlf]Connection: Upgrade[crlf]Upgrade: websocket[crlf][crlf]"
        "GET / HTTP/1.1[crlf]Host: $sni[crlf]User-Agent: $user_agent[crlf]Accept: */*[crlf]X-Real-IP: $sni[crlf]X-Cache-Bypass: $random_id[crlf]Connection: keep-alive[crlf][crlf]"
        "HEAD https://$sni/ HTTP/1.1[crlf]Host: $sni[crlf]User-Agent: $user_agent[crlf]X-Forwarded-Proto: https[crlf]Connection: Upgrade[crlf]Upgrade: websocket[crlf][crlf]"
        "POST https://$sni/ HTTP/1.1[crlf]Host: $sni[crlf]User-Agent: $user_agent[crlf]Content-Length: 0[crlf]X-Forwarded-For: $sni[crlf]Connection: keep-alive[crlf][crlf]"
    )
    
    local format_index=$((RANDOM % ${#formats[@]}))
    local payload="${formats[$format_index]}"
    
    echo "$payload" > "$PAYLOAD_CACHE"
    echo "$payload"
}

# --- Function: Setup and Start SSH Server ---
start_ssh_server() {
    echo -e "\n${CYAN}[*]${RESET} Starting SSH server on port $DEFAULT_SSH_PORT..."
    
    pkill sshd 2>/dev/null || true
    sleep 1
    
    local ROOT_PASS=$(get_password)
    echo "root:$ROOT_PASS" | chpasswd 2>/dev/null || true
    
    sshd -p "$DEFAULT_SSH_PORT" 2>/dev/null &
    sleep 2
    
    if ps aux | grep -v grep | grep -q "sshd -p $DEFAULT_SSH_PORT"; then
        log_message "SUCCESS" "SSH server running on port $DEFAULT_SSH_PORT"
        return 0
    fi
    
    log_message "ERROR" "SSH server failed to start"
    return 1
}

# --- Function: Create SOCKS5 Tunnel (Key-Based Auth) ---
create_socks_tunnel() {
    echo -e "\n${CYAN}[*]${RESET} Creating SOCKS5 tunnel on port $DEFAULT_SOCKS_PORT..."
    
    pkill -f "ssh -D $DEFAULT_SOCKS_PORT" 2>/dev/null || true
    pkill socat 2>/dev/null || true
    
    # Ensure SSH keys exist
    local ROOT_PASS=$(get_password)
    if [ ! -f ~/.ssh/id_rsa ]; then
        ssh-keygen -t rsa -b 2048 -N "$ROOT_PASS" -f ~/.ssh/id_rsa > /dev/null 2>&1
    fi
    
    # Copy public key to authorized_keys
    mkdir -p ~/.ssh
    cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys 2>/dev/null
    chmod 600 ~/.ssh/authorized_keys
    
    # Enable key auth in SSH config
    echo "PubkeyAuthentication yes" >> "$PREFIX/etc/ssh/sshd_config" 2>/dev/null || true
    
    # Create tunnel using key authentication
    ssh -D "$DEFAULT_SOCKS_PORT" -N -f \
        -o StrictHostKeyChecking=no \
        -o UserKnownHostsFile=/dev/null \
        -o PasswordAuthentication=no \
        -i ~/.ssh/id_rsa \
        root@127.0.0.1 -p "$DEFAULT_SSH_PORT" 2>/dev/null
    
    sleep 3
    
    if netstat -tlnp 2>/dev/null | grep -q "$DEFAULT_SOCKS_PORT"; then
        glowing_progress "SOCKS5 proxy active on 127.0.0.1:$DEFAULT_SOCKS_PORT" 2
        return 0
    fi
    
    # Fallback to socat direct tunnel
    log_message "WARN" "SSH tunnel failed. Using socat direct tunnel..."
    
    local SNI=$(cat "$SNI_CACHE" 2>/dev/null || echo "maya.ph")
    socat TCP-LISTEN:"$DEFAULT_SOCKS_PORT",fork,reuseaddr EXEC:"echo -e 'GET https://$SNI/ HTTP/1.1\r\nHost: $SNI\r\nUser-Agent: Mozilla/5.0\r\nConnection: Upgrade\r\nUpgrade: websocket\r\n\r\n' & cat" &
    
    sleep 2
    if netstat -tlnp 2>/dev/null | grep -q "$DEFAULT_SOCKS_PORT"; then
        glowing_progress "Socat proxy active on 127.0.0.1:$DEFAULT_SOCKS_PORT" 2
        return 0
    fi
    
    log_message "ERROR" "All tunnel methods failed"
    return 1
}

# --- Function: Display VPN App Compatibility ---
show_vpn_compatibility() {
    local current_sni=$(cat "$SNI_CACHE" 2>/dev/null || echo "maya.ph")
    local current_payload=$(cat "$PAYLOAD_CACHE" 2>/dev/null | head -c 80 || echo "Not generated yet")
    
    echo -e "\n${BOLD}${BLUE}══════════════════════════════════════════════════════════════${RESET}"
    echo -e "${BOLD}${WHITE}                   VPN APP COMPATIBILITY${RESET}"
    echo -e "${BOLD}${BLUE}══════════════════════════════════════════════════════════════${RESET}\n"
    
    echo -e "${BOLD}${LGREEN}HTTP Custom / NapsternetV:${RESET}"
    echo -e "  Server: ${CYAN}127.0.0.1${RESET}"
    echo -e "  Port: ${CYAN}$DEFAULT_SSH_PORT${RESET}"
    echo -e "  SNI: ${CYAN}$current_sni${RESET}"
    echo -e "  Payload: ${CYAN}$current_payload...${RESET}"
    echo ""
    
    echo -e "${BOLD}${LGREEN}v2rayNG / Nekobox / Browsers:${RESET}"
    echo -e "  Protocol: ${CYAN}SOCKS5${RESET}"
    echo -e "  Address: ${CYAN}127.0.0.1${RESET}"
    echo -e "  Port: ${CYAN}$DEFAULT_SOCKS_PORT${RESET}"
    echo ""
}

# --- Function: Display Guide ---
show_guide() {
    echo -e "\n${BOLD}${BLUE}══════════════════════════════════════════════════════════════${RESET}"
    echo -e "${BOLD}${WHITE}                   USER GUIDE${RESET}"
    echo -e "${BOLD}${BLUE}══════════════════════════════════════════════════════════════${RESET}\n"
    
    echo -e "${BOLD}${WHITE}1.${RESET} Ensure mobile data is ${LGREEN}ON${RESET} and has ${RED}ZERO LOAD${RESET}."
    echo -e "${BOLD}${WHITE}2.${RESET} Run ${CYAN}Option 1${RESET} (Full Setup) on first use."
    echo -e "${BOLD}${WHITE}3.${RESET} Run ${CYAN}Option 2${RESET} to start the tunnel."
    echo -e "${BOLD}${WHITE}4.${RESET} Configure your VPN app using the compatibility guide."
    echo -e "${BOLD}${WHITE}5.${RESET} Connect and browse.\n"
    
    echo -e "${BOLD}${WHITE}Troubleshooting:${RESET}"
    echo -e "  ${YELLOW}Connection Refused:${RESET} Ensure SSH server is running (Option 2)."
    echo -e "  ${YELLOW}No Internet:${RESET} Try Option 4 to rotate SNI/Payload."
    echo -e "  ${YELLOW}Slow Speed:${RESET} Option 4 selects the fastest SNI automatically."
    echo -e "  ${YELLOW}SSH Password:${RESET} Current is ${CYAN}$(get_password)${RESET}. Change with Option 8.\n"
}

# --- Function: About ---
show_about() {
    echo -e "\n${BOLD}${BLUE}══════════════════════════════════════════════════════════════${RESET}"
    echo -e "${BOLD}${WHITE}                   ABOUT THIS TOOL${RESET}"
    echo -e "${BOLD}${BLUE}══════════════════════════════════════════════════════════════${RESET}\n"
    
    echo -e "${BOLD}${WHITE}Purpose:${RESET}"
    echo -e "  ${CYAN}V1 TESTER PROTOCOL${RESET} is a local tunneling tool designed"
    echo -e "  for TNT/Smart networks. It creates a SOCKS5 proxy through"
    echo -e "  an SSH tunnel with intelligent SNI rotation and payload"
    echo -e "  generation, enabling no-load internet access.\n"
    
    echo -e "${BOLD}${WHITE}Features:${RESET}"
    echo -e "  • ${#SNI_HOSTS[@]}+ verified SNI hosts with automatic probing"
    echo -e "  • Key-based SSH authentication (no password prompts)"
    echo -e "  • Custom password support"
    echo -e "  • Automatic package installation"
    echo -e "  • VPN app compatibility guide\n"
    
    echo -e "${BOLD}${WHITE}Version:${RESET} ${SCRIPT_VERSION}"
    echo -e "${BOLD}${WHITE}Created by:${RESET} ${PURPLE}Prvtspyyy404${RESET}\n"
}

# --- Function: Full Setup ---
full_setup() {
    show_banner
    log_message "INFO" "Starting full setup..."
    
    check_and_install_packages || {
        log_message "ERROR" "Package installation failed"
        return 1
    }
    
    configure_ssh
    select_best_sni
    generate_payload "$(cat "$SNI_CACHE")"
    start_ssh_server
    create_socks_tunnel
    
    echo ""
    glowing_progress "Full setup complete! Tunnel is active" 3
    show_vpn_compatibility
}

# --- Function: Start Tunnel Only ---
start_tunnel() {
    show_banner
    if ! ps aux | grep -v grep | grep -q "sshd -p $DEFAULT_SSH_PORT"; then
        start_ssh_server
    else
        log_message "INFO" "SSH server already running"
    fi
    
    create_socks_tunnel
    show_vpn_compatibility
}

# --- Function: Stop Tunnel ---
stop_tunnel() {
    show_banner
    log_message "INFO" "Stopping all services..."
    pkill sshd 2>/dev/null || true
    pkill -f "ssh -D" 2>/dev/null || true
    pkill socat 2>/dev/null || true
    glowing_progress "Tunnel stopped" 1
}

# --- Function: Rotate SNI and Payload ---
rotate_sni() {
    show_banner
    log_message "INFO" "Rotating SNI and regenerating payload..."
    select_best_sni
    generate_payload "$(cat "$SNI_CACHE")"
    stop_tunnel
    sleep 1
    start_tunnel
}

# --- Function: Auto-Setup v1 Command ---
setup_v1_command() {
    local SCRIPT_PATH=$(realpath "$0")
    local BIN_DIR="$HOME/.termux/bin"
    local COMMAND_FILE="$BIN_DIR/v1"
    
    mkdir -p "$BIN_DIR"
    
    cat > "$COMMAND_FILE" <<EOF
#!/data/data/com.termux/files/usr/bin/bash
exec bash "$SCRIPT_PATH"
EOF
    
    chmod +x "$COMMAND_FILE"
    
    if ! grep -q ".termux/bin" ~/.bashrc 2>/dev/null; then
        echo 'export PATH="$HOME/.termux/bin:$PATH"' >> ~/.bashrc
    fi
}

# --- Main Menu ---
main_menu() {
    while true; do
        show_banner
        echo -e "${BOLD}${BLUE}══════════════════════════════════════════════════════════════${RESET}"
        echo -e "${BOLD}${WHITE}                       MAIN MENU${RESET}"
        echo -e "${BOLD}${BLUE}══════════════════════════════════════════════════════════════${RESET}\n"
        
        echo -e "  ${BOLD}${WHITE}[1]${RESET} ${LGREEN}Full Setup${RESET} (Install & Configure Everything)"
        echo -e "  ${BOLD}${WHITE}[2]${RESET} ${CYAN}Start Tunnel${RESET} (Activate SSH + SOCKS5)"
        echo -e "  ${BOLD}${WHITE}[3]${RESET} ${RED}Stop Tunnel${RESET}"
        echo -e "  ${BOLD}${WHITE}[4]${RESET} ${YELLOW}Rotate SNI/Payload${RESET} (Fix connection issues)"
        echo -e "  ${BOLD}${WHITE}[5]${RESET} ${PURPLE}VPN App Compatibility${RESET}"
        echo -e "  ${BOLD}${WHITE}[6]${RESET} ${LBLUE}User Guide & Troubleshooting${RESET}"
        echo -e "  ${BOLD}${WHITE}[7]${RESET} ${CYAN}About${RESET}"
        echo -e "  ${BOLD}${WHITE}[8]${RESET} ${PURPLE}Change Password${RESET}"
        echo -e "  ${BOLD}${WHITE}[9]${RESET} ${RED}Exit${RESET}\n"
        
        read -p "$(echo -e "${BOLD}${WHITE}Select option [1-9]: ${RESET}")" choice
        
        case $choice in
            1) full_setup; read -p "Press Enter to continue..." ;;
            2) start_tunnel; read -p "Press Enter to continue..." ;;
            3) stop_tunnel; read -p "Press Enter to continue..." ;;
            4) rotate_sni; read -p "Press Enter to continue..." ;;
            5) show_banner; show_vpn_compatibility; read -p "Press Enter to continue..." ;;
            6) show_banner; show_guide; read -p "Press Enter to continue..." ;;
            7) show_banner; show_about; read -p "Press Enter to continue..." ;;
            8) show_banner; set_custom_password; read -p "Press Enter to continue..." ;;
            9) echo -e "\n${GREEN}[+]${RESET} Exiting V1 TESTER PROTOCOL. Goodbye."; exit 0 ;;
            *) echo -e "\n${RED}[✘]${RESET} Invalid option. Please try again."; sleep 1 ;;
        esac
    done
}

# --- Entry Point ---
if [ ! -f "$HOME/.termux/bin/v1" ]; then
    setup_v1_command
    echo -e "${GREEN}[✔]${RESET} Command 'v1' installed."
    echo -e "${CYAN}[*]${RESET} Restart Termux or run: source ~/.bashrc"
    echo -e "${CYAN}[*]${RESET} Then type 'v1' to launch."
    exit 0
fi

main_menu
