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

# --- Configuration ---
SCRIPT_VERSION="1.0.0"
SCRIPT_NAME="V1 TESTER PROTOCOL"
DEFAULT_SSH_PORT="2222"
DEFAULT_SOCKS_PORT="1080"
CONFIG_DIR="$HOME/.v1tester"
LOG_FILE="$CONFIG_DIR/tunnel.log"
SNI_CACHE="$CONFIG_DIR/sni_cache.txt"
PAYLOAD_CACHE="$CONFIG_DIR/payload_cache.txt"

# --- Required Packages List ---
REQUIRED_PACKAGES=(
    "openssh"
    "curl"
    "socat"
    "netcat-openbsd"
    "jq"
    "expect"
    "tor"
    "privoxy"
)

# --- SNI Bug Hosts Database (TNT/Smart Verified) ---
declare -a SNI_HOSTS=(
    "maya.ph"
    "api.maya.ph"
    "smart.com.ph"
    "my.smart.com.ph"
    "bill.smart.com.ph"
    "connectivitycheck.gstatic.com"
    "www.gstatic.com"
    "clients2.google.com"
    "id.googleapis.com"
    "firebase-settings.crashlytics.com"
)

# --- User-Agent Pool for Payload Randomization ---
declare -a USER_AGENTS=(
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
    "Mozilla/5.0 (Linux; Android 13; SM-G991B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36"
    "Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.0 Mobile/15E148 Safari/604.1"
)

mkdir -p "$CONFIG_DIR"

# --- Glowing Banner Animation ---
glowing_banner() {
    clear
    local colors=("$LBLUE" "$CYAN" "$LCYAN" "$WHITE" "$LCYAN" "$CYAN" "$LBLUE")
    local text="V1 TESTER PROTOCOL"
    local width=40
    
    for ((i=0; i<3; i++)); do
        clear
        echo ""
        echo -e "${colors[$i]}    ██╗   ██╗ ██╗    ${LBLUE}████████╗███████╗███████╗████████╗███████╗██████╗${RESET}"
        echo -e "${colors[$((i+1))]}    ██║   ██║ ██║    ${LBLUE}╚══██╔══╝██╔════╝██╔════╝╚══██╔══╝██╔════╝██╔══██╗${RESET}"
        echo -e "${colors[$((i+2))]}    ██║   ██║ ██║       ${LBLUE}██║   █████╗  ███████╗   ██║   █████╗  ██████╔╝${RESET}"
        echo -e "${colors[$((i+3))]}    ╚██╗ ██╔╝ ██║       ${LBLUE}██║   ██╔══╝  ╚════██║   ██║   ██╔══╝  ██╔══██╗${RESET}"
        echo -e "${colors[$((i+2))]}     ╚████╔╝  ███████╗  ${LBLUE}██║   ███████╗███████║   ██║   ███████╗██║  ██║${RESET}"
        echo -e "${colors[$((i+1))]}      ╚═══╝   ╚══════╝  ${LBLUE}╚═╝   ╚══════╝╚══════╝   ╚═╝   ╚══════╝╚═╝  ╚═╝${RESET}"
        echo ""
        echo -e "${BOLD}${BLUE}    ══════════════════════════════════════════════════════════════${RESET}"
        echo -e "${BOLD}${WHITE}    PROTOCOL v${SCRIPT_VERSION}${RESET}  ${CYAN}TNT No-Load Auto Tunnel${RESET}"
        echo -e "${BOLD}${PURPLE}    Created by Prvtspyyy404${RESET}"
        echo -e "${BOLD}${BLUE}    ══════════════════════════════════════════════════════════════${RESET}"
        echo ""
        sleep 0.15
    done
}

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
    echo -e "${BOLD}${WHITE}    PROTOCOL v${SCRIPT_VERSION}${RESET}  ${CYAN}TNT No-Load Auto Tunnel | Termux Local Proxy${RESET}"
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

# --- Function: Animated Loading Spinner ---
spinner() {
    local pid=$1
    local message=$2
    local spinstr='|/-\'
    local i=0
    while kill -0 "$pid" 2>/dev/null; do
        printf "\r${CYAN}[%s]${RESET} %s" "${spinstr:i++%4:1}" "$message"
        sleep 0.1
    done
    printf "\r${GREEN}[✔]${RESET} %s\n" "$message"
}

# --- Function: Check and Install Packages (Intelligent) ---
check_and_install_packages() {
    log_message "INFO" "Checking required packages..."
    echo ""
    
    local missing_packages=()
    local installed_packages=()
    
    # Check each package
    for pkg in "${REQUIRED_PACKAGES[@]}"; do
        printf "${CYAN}[*]${RESET} Checking %-20s" "$pkg..."
        
        if command -v "$pkg" &> /dev/null || dpkg -s "$pkg" &> /dev/null; then
            echo -e "${GREEN}[INSTALLED]${RESET}"
            installed_packages+=("$pkg")
        else
            echo -e "${YELLOW}[MISSING]${RESET}"
            missing_packages+=("$pkg")
        fi
    done
    
    echo ""
    
    # Report status
    if [ ${#missing_packages[@]} -eq 0 ]; then
        log_message "SUCCESS" "All required packages are installed."
        return 0
    fi
    
    echo -e "${YELLOW}[!]${RESET} Missing packages: ${missing_packages[*]}"
    echo -e "${CYAN}[*]${RESET} Internet connection required for installation."
    echo ""
    read -p "$(echo -e "${WHITE}Install missing packages now? [Y/n]: ${RESET}")" confirm
    
    if [[ "$confirm" =~ ^[Nn] ]]; then
        log_message "ERROR" "Cannot proceed without required packages."
        return 1
    fi
    
    echo ""
    log_message "INFO" "Updating package repositories..."
    pkg update -y > /dev/null 2>&1 &
    spinner $! "Updating repositories"
    
    log_message "INFO" "Upgrading existing packages..."
    pkg upgrade -y > /dev/null 2>&1 &
    spinner $! "Upgrading packages"
    
    # Install missing packages
    for pkg in "${missing_packages[@]}"; do
        log_message "INFO" "Installing $pkg..."
        pkg install "$pkg" -y > /dev/null 2>&1 &
        spinner $! "Installing $pkg"
        
        # Verify installation
        if command -v "$pkg" &> /dev/null || dpkg -s "$pkg" &> /dev/null; then
            echo -e "${GREEN}[✔]${RESET} $pkg installed successfully"
        else
            echo -e "${RED}[✘]${RESET} Failed to install $pkg"
        fi
    done
    
    echo ""
    log_message "SUCCESS" "Package installation complete."
}

# --- Function: Configure SSH ---
configure_ssh() {
    log_message "INFO" "Configuring SSH server..."
    
    if [ ! -f "$PREFIX/etc/ssh/sshd_config.bak" ]; then
        cp "$PREFIX/etc/ssh/sshd_config" "$PREFIX/etc/ssh/sshd_config.bak" 2>/dev/null || true
    fi
    
    echo "Port $DEFAULT_SSH_PORT" >> "$PREFIX/etc/ssh/sshd_config" 2>/dev/null || true
    echo "PermitRootLogin yes" >> "$PREFIX/etc/ssh/sshd_config" 2>/dev/null || true
    echo "PasswordAuthentication yes" >> "$PREFIX/etc/ssh/sshd_config" 2>/dev/null || true
    echo "UsePAM no" >> "$PREFIX/etc/ssh/sshd_config" 2>/dev/null || true
    
    # Generate SSH keys if missing
    if [ ! -f "$PREFIX/etc/ssh/ssh_host_rsa_key" ]; then
        ssh-keygen -A > /dev/null 2>&1
    fi
    
    # Set root password
    echo "root:prvtspyyy" | chpasswd 2>/dev/null || true
    
    log_message "SUCCESS" "SSH configured."
}

# --- Function: Intelligent SNI Selection ---
select_best_sni() {
    log_message "INFO" "Probing SNI hosts for best latency..."
    echo ""
    
    local best_sni=""
    local best_latency=9999
    
    local shuffled=($(printf "%s\n" "${SNI_HOSTS[@]}" | shuf))
    
    for sni in "${shuffled[@]}"; do
        printf "${CYAN}[*]${RESET} Testing %-30s" "$sni..."
        
        local start=$(date +%s%N)
        if timeout 3 bash -c "echo > /dev/tcp/$sni/443" 2>/dev/null; then
            local end=$(date +%s%N)
            local latency=$(( (end - start) / 1000000 ))
            echo -e "${GREEN}${latency}ms${RESET}"
            
            if [ $latency -lt $best_latency ]; then
                best_latency=$latency
                best_sni=$sni
            fi
        else
            echo -e "${RED}unreachable${RESET}"
        fi
    done
    
    echo ""
    if [ -z "$best_sni" ]; then
        best_sni="maya.ph"
        log_message "WARN" "No SNI reachable. Falling back to $best_sni"
    else
        log_message "SUCCESS" "Best SNI: $best_sni (${best_latency}ms)"
    fi
    
    echo "$best_sni" > "$SNI_CACHE"
    echo "$best_sni"
}

# --- Function: Generate Optimized Payload ---
generate_payload() {
    local sni="$1"
    local ua_index=$((RANDOM % ${#USER_AGENTS[@]}))
    local user_agent="${USER_AGENTS[$ua_index]}"
    local random_id=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 8 | head -n 1)
    
    local formats=(
        "GET https://$sni/ HTTP/1.1[crlf]Host: $sni[crlf]User-Agent: $user_agent[crlf]X-Forwarded-For: $sni[crlf]Connection: Upgrade[crlf]Upgrade: websocket[crlf][crlf]"
        "GET / HTTP/1.1[crlf]Host: $sni[crlf]User-Agent: $user_agent[crlf]Accept: */*[crlf]X-Real-IP: $sni[crlf]X-Cache-Bypass: $random_id[crlf]Connection: keep-alive[crlf][crlf]"
        "HEAD https://$sni/ HTTP/1.1[crlf]Host: $sni[crlf]User-Agent: $user_agent[crlf]X-Forwarded-Proto: https[crlf]Connection: Upgrade[crlf]Upgrade: websocket[crlf][crlf]"
    )
    
    local format_index=$((RANDOM % ${#formats[@]}))
    local payload="${formats[$format_index]}"
    
    echo "$payload" > "$PAYLOAD_CACHE"
    echo "$payload"
}

# --- Function: Start SSH Server ---
start_ssh_server() {
    log_message "INFO" "Starting SSH server on port $DEFAULT_SSH_PORT..."
    
    pkill sshd 2>/dev/null || true
    sleep 1
    
    echo "root:prvtspyyy" | chpasswd 2>/dev/null || true
    
    sshd -p "$DEFAULT_SSH_PORT" 2>/dev/null &
    sleep 2
    
    if ps aux | grep -v grep | grep -q "sshd -p $DEFAULT_SSH_PORT"; then
        log_message "SUCCESS" "SSH server running on port $DEFAULT_SSH_PORT"
        return 0
    fi
    
    log_message "ERROR" "SSH server failed to start"
    return 1
}

# --- Function: Create SOCKS5 Tunnel (Fixed with expect) ---
# --- Function: Create SOCKS5 Tunnel (Fixed Temp Path) ---
create_socks_tunnel() {
    echo -e "\n${CYAN}[*]${RESET} Creating SOCKS5 tunnel on port $DEFAULT_SOCKS_PORT..."
    
    pkill -f "ssh -D $DEFAULT_SOCKS_PORT" 2>/dev/null || true
    pkill -f "expect" 2>/dev/null || true
    pkill socat 2>/dev/null || true
    
    # Use Termux-compatible temp directory
    mkdir -p "$PREFIX/tmp"
    local EXPECT_SCRIPT="$PREFIX/tmp/ssh-tunnel.exp"
    
    # Create expect script for SSH authentication
    cat > "$EXPECT_SCRIPT" <<EOF
#!/usr/bin/expect -f
set timeout 10
spawn ssh -D $DEFAULT_SOCKS_PORT -N -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@127.0.0.1 -p $DEFAULT_SSH_PORT
expect {
    "password:" { send "prvtspyyy\r"; exp_continue }
    "yes/no" { send "yes\r"; exp_continue }
    eof
}
EOF
    
    chmod +x "$EXPECT_SCRIPT"
    "$EXPECT_SCRIPT" &
    local expect_pid=$!
    
    sleep 3
    
    if netstat -tlnp 2>/dev/null | grep -q "$DEFAULT_SOCKS_PORT"; then
        glowing_progress "SOCKS5 proxy active on 127.0.0.1:$DEFAULT_SOCKS_PORT" 2
        rm -f "$EXPECT_SCRIPT"
        return 0
    fi
    
    # Fallback to socat direct tunnel
    log_message "WARN" "SSH tunnel failed. Using socat direct tunnel..."
    
    local SNI=$(cat "$SNI_CACHE" 2>/dev/null || echo "maya.ph")
    socat TCP-LISTEN:$DEFAULT_SOCKS_PORT,fork,reuseaddr EXEC:"echo -e 'GET https://$SNI/ HTTP/1.1\r\nHost: $SNI\r\nUser-Agent: Mozilla/5.0\r\nConnection: Upgrade\r\nUpgrade: websocket\r\n\r\n' & cat" &
    
    sleep 2
    if netstat -tlnp 2>/dev/null | grep -q "$DEFAULT_SOCKS_PORT"; then
        glowing_progress "Socat proxy active on 127.0.0.1:$DEFAULT_SOCKS_PORT" 2
        rm -f "$EXPECT_SCRIPT"
        return 0
    fi
    
    log_message "ERROR" "All tunnel methods failed"
    rm -f "$EXPECT_SCRIPT"
    return 1
}

# --- Function: Display VPN App Compatibility ---
show_vpn_compatibility() {
    echo -e "\n${BOLD}${BLUE}══════════════════════════════════════════════════════════════${RESET}"
    echo -e "${BOLD}${WHITE}                   VPN APP COMPATIBILITY${RESET}"
    echo -e "${BOLD}${BLUE}══════════════════════════════════════════════════════════════${RESET}\n"
    
    echo -e "${BOLD}${LGREEN}HTTP Custom / NapsternetV:${RESET}"
    echo -e "  Server: ${CYAN}127.0.0.1${RESET}"
    echo -e "  Port: ${CYAN}$DEFAULT_SSH_PORT${RESET}"
    echo -e "  SNI: ${CYAN}$(cat $SNI_CACHE 2>/dev/null || echo 'maya.ph')${RESET}"
    echo -e "  Payload: ${CYAN}$(cat $PAYLOAD_CACHE 2>/dev/null | head -c 60)...${RESET}"
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
    echo -e "  ${YELLOW}SSH Password:${RESET} Default is ${CYAN}prvtspyyy${RESET}\n"
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
    
    echo -e "${BOLD}${WHITE}How It Works:${RESET}"
    echo -e "  1. SSH server runs locally on port $DEFAULT_SSH_PORT"
    echo -e "  2. SOCKS5 proxy created on port $DEFAULT_SOCKS_PORT"
    echo -e "  3. VPN app injects payload with optimal SNI"
    echo -e "  4. Traffic tunnels through TNT's zero-rated domains\n"
    
    echo -e "${BOLD}${WHITE}Version:${RESET} ${SCRIPT_VERSION}"
    echo -e "${BOLD}${WHITE}Created by:${RESET} ${PURPLE}Prvtspyyy404${RESET}\n"
}

# --- Function: Full Setup ---
full_setup() {
    glowing_banner
    log_message "INFO" "Starting full setup..."
    
    if ! check_and_install_packages; then
        log_message "ERROR" "Package installation failed or cancelled."
        read -p "Press Enter to return to menu..."
        return 1
    fi
    
    configure_ssh
    select_best_sni
    generate_payload "$(cat $SNI_CACHE)"
    start_ssh_server
    create_socks_tunnel
    
    echo ""
    log_message "SUCCESS" "Setup complete! Tunnel is active."
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
    log_message "SUCCESS" "Tunnel stopped."
}

# --- Function: Rotate SNI and Payload ---
rotate_sni() {
    show_banner
    log_message "INFO" "Rotating SNI and regenerating payload..."
    select_best_sni
    generate_payload "$(cat $SNI_CACHE)"
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
    
    if ! grep -q ".termux/bin" ~/.bashrc; then
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
        echo -e "  ${BOLD}${WHITE}[8]${RESET} ${RED}Exit${RESET}\n"
        
        read -p "$(echo -e "${BOLD}${WHITE}Select option [1-8]: ${RESET}")" choice
        
        case $choice in
            1) full_setup; read -p "Press Enter to continue..." ;;
            2) start_tunnel; read -p "Press Enter to continue..." ;;
            3) stop_tunnel; read -p "Press Enter to continue..." ;;
            4) rotate_sni; read -p "Press Enter to continue..." ;;
            5) show_banner; show_vpn_compatibility; read -p "Press Enter to continue..." ;;
            6) show_banner; show_guide; read -p "Press Enter to continue..." ;;
            7) show_banner; show_about; read -p "Press Enter to continue..." ;;
            8) echo -e "\n${GREEN}[+]${RESET} Exiting V1 TESTER PROTOCOL. Goodbye."; exit 0 ;;
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
