#!/bin/bash
run_scan() {

    TEMP_REPORT="safer_report_tmp_$(date +%F_%H-%M-%S).txt"
    REPORT="$TEMP_REPORT"

    SECURITY_SCORE=100
    RISK_LEVEL="LOW"

    deduct() {
        SECURITY_SCORE=$((SECURITY_SCORE - $1))
    }

    echo "==========================================" | tee -a "$REPORT"
    echo "        SAFER Network Security Tool" | tee -a "$REPORT"
    echo "        Defensive & Legal Use Only" | tee -a "$REPORT"
    echo "==========================================" | tee -a "$REPORT"

    echo "[*] Checking internet connectivity..." | tee -a "$REPORT"
    if ping -c 1 8.8.8.8 >/dev/null 2>&1; then
        echo "[✓] Internet connected" | tee -a "$REPORT"
    else
        echo "[!] No internet connection" | tee -a "$REPORT"
        deduct 20
    fi

    echo "[*] Checking firewall status..." | tee -a "$REPORT"
    if systemctl is-active --quiet ufw; then
        echo "[✓] Firewall active" | tee -a "$REPORT"
    else
        echo "[!] Firewall inactive" | tee -a "$REPORT"
        deduct 20
    fi

    echo "[*] Checking DNS configuration..." | tee -a "$REPORT"
    cat /etc/resolv.conf | tee -a "$REPORT"

    DNS_OK=0
    grep -E "1.1.1.1|9.9.9.9|8.8.8.8" /etc/resolv.conf && DNS_OK=1
    if [ $DNS_OK -eq 0 ]; then
        deduct 10
    fi

    echo "[*] Listing network interfaces..." | tee -a "$REPORT"
    ip a | tee -a "$REPORT"

    echo "[*] Checking listening ports..." | tee -a "$REPORT"
    ss -tuln | tee -a "$REPORT"

    # Risk level
    if [ $SECURITY_SCORE -lt 60 ]; then
        RISK_LEVEL="HIGH"
    elif [ $SECURITY_SCORE -lt 80 ]; then
        RISK_LEVEL="MEDIUM"
    fi

    echo "------------------------------------------" | tee -a "$REPORT"
    echo "Security Score: $SECURITY_SCORE / 100" | tee -a "$REPORT"
    echo "Risk Level: $RISK_LEVEL" | tee -a "$REPORT"

    whiptail --title "SAFER Finished" \
    --msgbox "Scan completed successfully\n\nSecurity Score: $SECURITY_SCORE / 100\nRisk Level: $RISK_LEVEL\n\nReport saved as:\n$REPORT" 15 60
}

# ===== IP FUNCTIONS =====
check_ip() {
    IP=$(curl -s https://api.ipify.org)
    if [ -z "$IP" ]; then
        whiptail --title "IP Check" --msgbox "Unable to detect public IP." 8 50
    else
        whiptail --title "Public IP" --msgbox "Your Public IP is:\n\n$IP" 10 50
    fi
}

change_ip() {
    METHOD=$(whiptail --title "Change IP Address" --menu "Choose method:" 15 60 4 \
    "1" "Renew DHCP" \
    "2" "Restart Network" \
    "3" "Back" \
    3>&1 1>&2 2>&3)

    case "$METHOD" in
        1)
            dhclient -r && dhclient
            whiptail --msgbox "DHCP renewed." 8 40
            ;;
        2)
            nmcli networking off
            sleep 2
            nmcli networking on
            whiptail --msgbox "Network restarted." 8 40
            ;;
    esac
}

ip_menu() {
    while true; do
        CHOICE=$(whiptail --title "IP Menu" --menu "Choose an option:" 15 60 4 \
        "1" "Check Public IP" \
        "2" "Change IP" \
        "3" "Back to Main Menu" \
        3>&1 1>&2 2>&3)

        case "$CHOICE" in
            1) check_ip ;;
            2) change_ip ;;
            *) break ;;
        esac
    done
}

# ========================
# SAFER Security Tool
# Defensive & Legal Network Security Tool
# ========================

clear

# Temp report
TEMP_REPORT="safer_report_tmp_$(date +%F_%H-%M-%S).txt"
REPORT="$TEMP_REPORT"

# Security score
SECURITY_SCORE=100
RISK_LEVEL="LOW"

deduct() {
    SECURITY_SCORE=$((SECURITY_SCORE - $1))
}

# ===== Progress Bar =====
show_progress() {
(
echo 10
echo "# Checking Internet..."
sleep 1

echo 30
echo "# Checking Firewall..."
sleep 1

echo 50
echo "# Checking DNS..."
sleep 1

echo 70
echo "# Scanning Interfaces..."
sleep 1

echo 90
echo "# Checking Ports..."
sleep 1

echo 100
echo "# Finalizing report..."
sleep 1
) | whiptail --gauge "Running Security Scan..." 10 60 0
}
# =======================

# Root check
if [ "$EUID" -ne 0 ]; then
    echo "[!] Please run as root (sudo)"
    exit 1
fi

# Show welcome
whiptail --title "SAFER Security Tool" --msgbox "Welcome to SAFER\n\nDefensive & Legal Network Security Tool\n\nPress OK to continue" 10 60

# ======================= MAIN MENU LOOP =======================
while true; do
    OPTION=$(whiptail --title "SAFER Main Menu" --menu "Choose an action:" 18 65 7 \
    "1" "Run Full Security Scan" \
    "2" "Restore DNS Backup" \
    "3" "View Report" \
    "4" "Check / Change IP Address" \
    "5" "Exit" \
    3>&1 1>&2 2>&3)

    case "$OPTION" in
        1)
            # Run progress bar first
            show_progress

            echo "==========================================" | tee -a "$REPORT"
            echo "        SAFER Network Security Tool" | tee -a "$REPORT"
            echo "        Defensive & Legal Use Only" | tee -a "$REPORT"
            echo "==========================================" | tee -a "$REPORT"

            # Internet check
            echo "[*] Checking internet connectivity..." | tee -a "$REPORT"
            if ping -c 1 google.com &>/dev/null; then
                echo "[✓] Internet connected" | tee -a "$REPORT"
            else
                echo "[!] Internet not reachable" | tee -a "$REPORT"
                deduct 20
            fi

            # Firewall check
            echo "[*] Checking firewall status..." | tee -a "$REPORT"
            if systemctl is-active --quiet ufw; then
                echo "[✓] Firewall active" | tee -a "$REPORT"
            else
                echo "[!] Firewall inactive" | tee -a "$REPORT"
                deduct 20
            fi

            # DNS check
            echo "[*] Checking DNS configuration..." | tee -a "$REPORT"
            cat /etc/resolv.conf | tee -a "$REPORT"

            # Network interfaces
            echo "[*] Listing network interfaces..." | tee -a "$REPORT"
            ip addr show | tee -a "$REPORT"

            # Listening ports
            echo "[*] Checking listening ports..." | tee -a "$REPORT"
            ss -tuln | tee -a "$REPORT"

            # Security Score
            echo "------------------------------------------" | tee -a "$REPORT"
            echo "Security Score: $SECURITY_SCORE / 100" | tee -a "$REPORT"
            echo "Risk Level: $RISK_LEVEL" | tee -a "$REPORT"

            # Ask user for custom report name
            CUSTOM_NAME=$(whiptail --title "Save Report" \
            --inputbox "Enter report name (without .txt):" 10 60 "my_security_report" \
            3>&1 1>&2 2>&3)

            if [ -n "$CUSTOM_NAME" ]; then
                FINAL_REPORT="$(dirname "$0")/${CUSTOM_NAME}.txt"
            else
                FINAL_REPORT="$(dirname "$0")/safer_report_$(date +%F_%H-%M-%S).txt"
            fi

            mv "$TEMP_REPORT" "$FINAL_REPORT"
            REPORT="$FINAL_REPORT"

            whiptail --title "SAFER Finished" \
            --msgbox "Security scan completed successfully.\n\nReport saved as:\n$REPORT" 10 60

            ;;
        2)
            cp /etc/resolv.conf.backup /etc/resolv.conf
            whiptail --title "DNS Restored" --msgbox "DNS restored successfully." 8 50
            ;;
        3)
            REPORTS=( $(ls "$(dirname "$0")"/safer_report_*.txt 2>/dev/null | grep -v "_tmp") )

            if [ ${#REPORTS[@]} -eq 0 ]; then
                whiptail --title "Security Report" --msgbox "[!] No reports found to display." 10 50
            else
                MENU_ITEMS=()
                for REPORT_FILE in "${REPORTS[@]}"; do
                    FILE_NAME=$(basename "$REPORT_FILE")
                    MENU_ITEMS+=("$REPORT_FILE" "$FILE_NAME")
                done

                CHOICE=$(whiptail --title "Select Report" --menu "Choose a report to display:" 20 70 10 "${MENU_ITEMS[@]}" 3>&1 1>&2 2>&3)

                if [ -n "$CHOICE" ]; then
                    whiptail --title "Security Report" --textbox "$CHOICE" 20 70
                fi
            fi
            ;;
        4)
            # Call your IP menu function
            ip_menu
            ;;
        5)
            exit 0
            ;;
    esac
done

TEMP_REPORT="safer_report_tmp_$(date +%F_%H-%M-%S).txt"
REPORT="$TEMP_REPORT"
# Security score
SECURITY_SCORE=100
RISK_LEVEL="LOW"

deduct() {
    SECURITY_SCORE=$((SECURITY_SCORE - $1))
}

# ===== ADD THIS EXACTLY HERE =====
show_progress() {
(
echo 10
echo "# Checking Internet..."
sleep 1

echo 30
echo "# Checking Firewall..."
sleep 1

echo 50
echo "# Checking DNS..."
sleep 1

echo 70
echo "# Scanning Interfaces..."
sleep 1

echo 90
echo "# Checking Ports..."
sleep 1

echo 100
echo "# Finalizing report..."
sleep 1
) | whiptail --gauge "Running Security Scan..." 10 60 0
}
# ===== END =====

echo "==========================================" | tee -a "$REPORT"
echo "        SAFER Network Security Tool" | tee -a "$REPORT"
echo "        Defensive & Legal Use Only" | tee -a "$REPORT"
echo "==========================================" | tee -a "$REPORT"
echo "" | tee -a "$REPORT"

# Root check
if [ "$EUID" -ne 0 ]; then
  echo "[!] Please run as root (sudo)" | tee -a "$REPORT"
  exit 1
fi
show_progress
# ===== REAL SECURITY SCAN STARTS HERE =====

# Internet check
echo "[*] Checking internet connectivity..." | tee -a "$REPORT"
if ping -c 2 8.8.8.8 >/dev/null 2>&1; then
    echo "[✓] Internet connected" | tee -a "$REPORT"
else
    echo "[!] No internet connectivity" | tee -a "$REPORT"
    deduct 10
fi

# Firewall check
echo "[*] Checking firewall status..." | tee -a "$REPORT"
if command -v ufw >/dev/null 2>&1 && ufw status | grep -q "Status: active"; then
    echo "[✓] Firewall active" | tee -a "$REPORT"
else
    echo "[!] Firewall inactive or not installed" | tee -a "$REPORT"
    deduct 15
fi

# Ports & services
echo "[*] Checking listening ports (local)..." | tee -a "$REPORT"
ss -tuln | tee -a "$REPORT"

# Telnet
if ss -lnt | grep -q ":23 "; then
    echo "[HIGH] Telnet service detected" | tee -a "$REPORT"
    echo "[FIX] Disable Telnet:" | tee -a "$REPORT"
    echo "      systemctl disable telnet" | tee -a "$REPORT"
    echo "      systemctl stop telnet" | tee -a "$REPORT"
    deduct 30
fi

# FTP
if ss -lnt | grep -q ":21 "; then
    echo "[MEDIUM] FTP service detected" | tee -a "$REPORT"
    echo "[FIX] Use SFTP instead (OpenSSH)" | tee -a "$REPORT"
    deduct 15
fi

# Docker API
if ss -lnt | grep -q ":2375 "; then
    echo "[HIGH] Docker API exposed locally" | tee -a "$REPORT"
    echo "[FIX] Bind Docker API to localhost or disable TCP socket" | tee -a "$REPORT"
    deduct 25
fi

# ===== SECURITY SCORE =====
if [ "$SECURITY_SCORE" -lt 0 ]; then
    SECURITY_SCORE=0
fi

if [ "$SECURITY_SCORE" -ge 80 ]; then
    RISK_LEVEL="LOW"
elif [ "$SECURITY_SCORE" -ge 50 ]; then
    RISK_LEVEL="MEDIUM"
else
    RISK_LEVEL="HIGH"
fi

echo "------------------------------------------" | tee -a "$REPORT"
echo "Security Score: $SECURITY_SCORE / 100" | tee -a "$REPORT"
echo "Risk Level: $RISK_LEVEL" | tee -a "$REPORT"

# Backup DNS (only if not already backed up)
if [ ! -f /etc/resolv.conf.backup ]; then
    cp /etc/resolv.conf /etc/resolv.conf.backup
    echo "[✓] DNS backup created (/etc/resolv.conf.backup)" | tee -a "$REPORT"
else
    echo "[i] DNS backup already exists" | tee -a "$REPORT"
fi

# Option to restore DNS
read -p "Do you want to restore previous DNS? (y/n): " restore_dns
if [ "$restore_dns" = "y" ] || [ "$restore_dns" = "Y" ]; then
    cp /etc/resolv.conf.backup /etc/resolv.conf
    echo "[✓] DNS restored from backup" | tee -a "$REPORT"
    exit 0
fi

# Internet check
echo "[*] Checking internet connectivity..." | tee -a "$REPORT"
if ping -c 2 8.8.8.8 > /dev/null 2>&1; then
    echo "[✓] Internet connected" | tee -a "$REPORT"
else
    echo "[!] No internet connection" | tee -a "$REPORT"
fi

echo "" | tee -a "$REPORT"
echo "[✓] SAFER scan completed successfully" | tee -a "$REPORT"
echo "" | tee -a "$REPORT"
echo "[*] Checking firewall status..." | tee -a "$REPORT"

if command -v ufw >/dev/null 2>&1; then
    ufw status | tee -a "$REPORT"
else
    echo "[!] UFW firewall not installed" | tee -a "$REPORT"
fi
echo "" | tee -a "$REPORT"
echo "[*] Checking DNS configuration..." | tee -a "$REPORT"

cat /etc/resolv.conf | tee -a "$REPORT"
echo "" | tee -a "$REPORT"
echo "[*] Listing network interfaces..." | tee -a "$REPORT"

ip addr show | tee -a "$REPORT"
echo "" | tee -a "$REPORT"
echo "[*] Checking listening ports (local)..." | tee -a "$REPORT"
ss -tuln | tee -a "$REPORT"
# Telnet check
# ===== Insecure services checks =====

# Telnet (23)
if ss -lnt | grep -q ":23 "; then
    echo "[HIGH] Telnet service detected" | tee -a "$REPORT"
    echo "[FIX] Disable Telnet:" | tee -a "$REPORT"
    echo "      systemctl disable telnet" | tee -a "$REPORT"
    echo "      systemctl stop telnet" | tee -a "$REPORT"
    echo "" | tee -a "$REPORT"
    deduct 30
    RISK_LEVEL="HIGH"
fi

# FTP (21)
if ss -lnt | grep -q ":21 "; then
    echo "[MEDIUM] FTP service detected" | tee -a "$REPORT"
    echo "[FIX] Use SFTP instead (OpenSSH)" | tee -a "$REPORT"
    echo "" | tee -a "$REPORT"
    deduct 15
fi

# Docker API (2375)
if ss -lnt | grep -q ":2375 "; then
    echo "[HIGH] Docker API exposed locally" | tee -a "$REPORT"
    echo "[FIX] Bind Docker API to localhost or disable TCP socket" | tee -a "$REPORT"
    echo "" | tee -a "$REPORT"
    deduct 25
    RISK_LEVEL="HIGH"
fi


echo "" | tee -a "$REPORT"
echo "==========================================" | tee -a "$REPORT"
echo "[✓] Security checks finished successfully" | tee -a "$REPORT"
echo "Report saved as: $REPORT" | tee -a "$REPORT"
echo "==========================================" | tee -a "$REPORT"
whiptail --title "SAFER Finished" \
--msgbox "Security scan completed successfully.\n\nReport saved as:\n$REPORT" 10 60
echo "==========================================" | tee -a "$REPORT"
# Ask user for report name
CUSTOM_NAME=$(whiptail --title "Save Report" \
--inputbox "Enter report name (without .txt):" 10 60 "my_security_report" \
3>&1 1>&2 2>&3)

if [ -n "$CUSTOM_NAME" ]; then
    FINAL_REPORT="$(dirname "$0")/${CUSTOM_NAME}.txt"
else
    FINAL_REPORT="$(dirname "$0")/safer_report_$(date +%F_%H-%M-%S).txt"
fi

mv "$TEMP_REPORT" "$FINAL_REPORT"
REPORT="$FINAL_REPORT"
# ===== Security Score =====
if [ "$SECURITY_SCORE" -lt 0 ]; then
    SECURITY_SCORE=0
fi

if [ "$SECURITY_SCORE" -ge 80 ]; then
    RISK_LEVEL="LOW"
elif [ "$SECURITY_SCORE" -ge 50 ]; then
    RISK_LEVEL="MEDIUM"
else
    RISK_LEVEL="HIGH"
fi

echo "------------------------------------------" | tee -a "$REPORT"
echo "Security Score: $SECURITY_SCORE / 100" | tee -a "$REPORT"
echo "Risk Level: $RISK_LEVEL" | tee -a "$REPORT"

echo "[✓] Security checks finished successfully" | tee -a "$REPORT"
echo "Report saved as: $REPORT" | tee -a "$REPORT"
echo "==========================================" | tee -a "$REPORT"


