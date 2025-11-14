#!/bin/bash
# Set up a software wireless access point (WAP) for a Wi-Fi deauthentication attack simulation
# Author: Alex Carbajal
# Dependencies:
# - https://thekelleys.org.uk/dnsmasq/doc.html
# - https://w1.fi/hostapd
# - https://git.kernel.org/pub/scm/network/iproute2/iproute2.git
# - https://git.kernel.org/pub/scm/linux/kernel/git/jberg/iw.git
# - https://github.com/alobbs/macchanger
# - https://gitlab.freedesktop.org/NetworkManager/NetworkManager
# - https://git.kernel.org/pub/scm/linux/kernel/git/netfilter/nf-next.git
# - https://gitlab.com/psmisc/psmisc
# - https://github.com/BurntSushi/ripgrep

# Check if running as root
if [[ $EUID -ne 0 ]]; then
  echo "Run as root"
  exit
fi

BOLD="\e[1m"
RED="\e[0;31m"
GREEN="\e[0;32m"
BLUE="\e[0;34m"
YELLOW="\e[0;33m"
NORMAL="\e[0m"

# Let user terminate the script at any time
exit_script() {
  echo -e "${RED}\n\nSoftware WAP setup interrupted. Exiting...${NORMAL}"
  exit 130
}
trap exit_script INT

echo -e "${BLUE}${BOLD}*** Wi-Fi Deauthentication Attack Simulation Using Arch Linux ***${NORMAL}"
echo -e "${YELLOW}=== Software WAP Setup ===${NORMAL}\n"

# *********************************************************************
# ******************** SETTING UP THE SOFTWARE WAP ********************
# *********************************************************************
echo -e "${YELLOW}=== SETTING UP THE SOFTWARE WAP ===${NORMAL}\n"

# Find the names of the wireless network interface controllers (WNICs)
readarray -t WIFI_INTERFACES < <(iw dev | rg -o 'wlp.*')

# List the names of the found WNICs
echo -e "${BOLD}${#WIFI_INTERFACES[@]}${NORMAL} wireless network interface(s) detected:"
for ((i = 0; i < ${#WIFI_INTERFACES[@]}; i++)); do
  echo -e "$((i + 1)). ${BOLD}${WIFI_INTERFACES[i]}${NORMAL}"
done
echo -e

# Let the user pick a WNIC from the numbered list of WNICs
read -r -p "Select an interface to use for software WAP (1..${#WIFI_INTERFACES[@]}): " INTERFACE_I
# Check that the pick is valid
if ((INTERFACE_I < 1 || INTERFACE_I > ${#WIFI_INTERFACES[@]})); then
  echo -e "${RED}Invalid interface. Please select an interface from the list.${NORMAL}"
  exit 1
fi
INTERFACE_NAME="${WIFI_INTERFACES[${INTERFACE_I} - 1]}"

# Create a virtual interface for the software WAP and set it to AP mode
WAP_INTERFACE_NAME="${INTERFACE_NAME}_wap"
echo -e "Creating virtual interface ${BOLD}${WAP_INTERFACE_NAME}${NORMAL} for the software WAP"
iw dev "${INTERFACE_NAME}" interface add "${WAP_INTERFACE_NAME}" type __ap
echo -e

# Ignore the software WAP in NetworkManager
echo -e "Ignoring ${BOLD}${WAP_INTERFACE_NAME}${NORMAL} in NetworkManager"
nmcli device set "${WAP_INTERFACE_NAME}" managed no
echo -e

# Set the software WAP to AP mode
echo -e "Setting ${BOLD}${WAP_INTERFACE_NAME}${NORMAL} to AP mode"
ip link set dev "${WAP_INTERFACE_NAME}" down
iw dev "${WAP_INTERFACE_NAME}" set type __ap
echo -e

# Spoof the MAC address of the software WAP
echo -e "Spoof MAC address of ${BOLD}${WAP_INTERFACE_NAME}${NORMAL}?"
select response in "Yes" "No"; do
  case $response in
  Yes)
    echo -e "Spoofing ${BOLD}${WAP_INTERFACE_NAME}${NORMAL} MAC address"
    macchanger -r "${WAP_INTERFACE_NAME}"
    break
    ;;
  No) break ;;
  esac
done
echo -e

# Assign a static IPv4 address to the software WAP
WAP_IP_NETWORK_ID="192.168.2"
WAP_IP_HOST_ID=".1"
WAP_SUBNET_MASK="24"
WAP_IP="${WAP_IP_NETWORK_ID}${WAP_IP_HOST_ID}"
WAP_IP_SUBNET="${WAP_IP}/${WAP_SUBNET_MASK}"
echo -e "Adding IP address ${BOLD}${WAP_IP_SUBNET}${NORMAL} to ${BOLD}${WAP_INTERFACE_NAME}${NORMAL}"
ip addr add "${WAP_IP_SUBNET}" dev "${WAP_INTERFACE_NAME}"
echo -e

# Let the user pick a custom SSID for the software WAP, otherwise use the default SSID
read -r -p "SSID (blank for default): " CUSTOM_SSID
SSID="${CUSTOM_SSID:-FreeWiFi}"
echo -e "SSID ${BOLD}${SSID}${NORMAL} will be utilized"
echo -e

# *********************************************************************
# ********************** MISCELLANEOUS OPERATIONS *********************
# *********************************************************************
echo -e "${YELLOW}=== MISCELLANEOUS OPERATIONS ===${NORMAL}\n"

# Enable packet forwarding using sysctl
echo -e "Enabling IPv4 & IPv6 packet forwarding"
sysctl -w net.ipv4.ip_forward=1 \
  net.ipv4.conf.all.forwarding=1 \
  net.ipv6.conf.all.forwarding=1
echo -e

# Disable UFW if it is installed & enabled
if command -v ufw >/dev/null 2>&1 && ufw status | rg -q "Status: active"; then
  echo -e "Active UFW instance detected - disabling"
  ufw disable
  echo -e
fi

# *********************************************************************
# ***************************** ENABLING NAT **************************
# *********************************************************************
echo -e "${YELLOW}=== ENABLING NAT ===${NORMAL}\n"

echo -e "Enabling NAT for the software WAP using ${BOLD}nftables${NORMAL}"
# Create a new NAT table
nft add table inet nat
# Create a postrouting chain for the new table
nft add chain inet nat postrouting '{ type nat hook postrouting priority srcnat ; }'
# Masquerade the addresses coming in to the internet-facing interface
nft add rule inet nat postrouting oifname "${INTERFACE_NAME}" masquerade
# Allow forwarding of NAT traffic (default policy of /etc/nftables.conf drops it)
nft add chain inet nat forward
nft add rule inet nat forward ct state related,established accept
nft add rule inet nat forward iifname "${WAP_INTERFACE_NAME}" oifname "${INTERFACE_NAME}" accept
echo -e

# *********************************************************************
# ************************ CONFIGURING DNSMASQ ************************
# *********************************************************************
echo -e "${YELLOW}=== CONFIGURING DNSMASQ ===${NORMAL}\n"

# Create the dnsmasq configuration file for the software WAP
DNSMASQ_CONF_FILE_DIR="/etc/dnsmasq.d"
DNSMASQ_CONF_FILE="${DNSMASQ_CONF_FILE_DIR}/dnsmasq-deauth.conf"
if [ ! -f "${DNSMASQ_CONF_FILE}" ]; then
  # Create "dnsmasq-deauth.conf" in the appropriate directory if it does not exist
  echo -e "Creating ${BOLD}${DNSMASQ_CONF_FILE}${NORMAL}"
  mkdir -p ${DNSMASQ_CONF_FILE_DIR} && touch ${DNSMASQ_CONF_FILE}
else
  echo -e "${BOLD}${DNSMASQ_CONF_FILE}${NORMAL} already exists. File will be overwritten."
fi

# Set the contents of the hostapd configuration file
tee "${DNSMASQ_CONF_FILE}" >/dev/null <<EOF
# dnsmasq configuration file for a software wireless access point (software WAP)
# Provides DHCP & DNS services to devices connecting to the software WAP
# For demonstration purposes only

# Wireless network interface to use for the software WAP
interface=${WAP_INTERFACE_NAME}
# Range of IP addresses available for lease & a lease time
# First 3 octets should match the IP of the software WAP
dhcp-range=${WAP_IP_NETWORK_ID}.2,${WAP_IP_NETWORK_ID}.100,255.255.255.0,12h
# Gateway and DNS server set to the software WAP's IP
# All DNS queries now guaranteed to go through the software WAP
dhcp-option=3,${WAP_IP} # Gateway
dhcp-option=6,${WAP_IP} # DNS server
# Set the DNS to resolve queries locally
no-resolv
server=1.1.1.1 # Cloudflare DNS
# DHCP leases are logged for devices connected to the software WAP
# Default location for the file is: /var/lib/misc/dnsmasq.leases
log-dhcp # Extra information about DHCP transactions
EOF

# Run the dnsmasq configuration file in the background
echo -e "Running ${BOLD}${DNSMASQ_CONF_FILE}${NORMAL} in the background"
dnsmasq -C ${DNSMASQ_CONF_FILE} >/dev/null
echo -e

# *********************************************************************
# ************************ CONFIGURING HOSTAPD ************************
# *********************************************************************
echo -e "${YELLOW}=== CONFIGURING HOSTAPD ===${NORMAL}\n"

# Grab the channel that the software WAP is connected to in the Wi-Fi network
CHANNEL=$(iw dev "$INTERFACE_NAME" info | rg -oP 'channel \K\d+')
echo -e "Parent interface ${BOLD}${INTERFACE_NAME}${NORMAL} connected on channel ${BOLD}${CHANNEL}${NORMAL}"
echo -e

# Create the hostapd configuration file for the software WAP
HOSTAPD_CONF_FILE="/etc/hostapd/hostapd-deauth.conf"
if [ ! -f "${HOSTAPD_CONF_FILE}" ]; then
  # Create "hostapd-deauth.conf" if it does not exist
  echo -e "Creating ${BOLD}${HOSTAPD_CONF_FILE}${NORMAL}"
  touch ${HOSTAPD_CONF_FILE}
else
  echo -e "${BOLD}${HOSTAPD_CONF_FILE}${NORMAL} already exists. File will be overwritten."
fi
echo -e

# TODO: Programatically acquire the band for the software WAP (2.4 GHz vs 5 GHz)
# Set the contents of the hostapd configuration file
tee "${HOSTAPD_CONF_FILE}" >/dev/null <<EOF
# hostapd configuration file to create a software wireless access point (software WAP)
# For demonstration purposes only

# Wireless network interface to use for the software WAP
interface=${WAP_INTERFACE_NAME}
# Driver for the interface (nl80211 is standard for Linux)
driver=nl80211
# Country code to indicate country device is operating in
country_code=US
# Set regulatory limits
ieee80211d=1
# Enable DFS & radar support
ieee80211h=1
# Service Set Identifier (SSID), or name, of the software WAP
ssid=${SSID}
# Enable 802.11ac support
ieee80211ac=1
# Enable Wi-Fi Multimedia (WMM) to enhance quality of service (QoS)
wmm_enabled=1
# Hardware mode
# 'a' for 5 GHz on 802.11ac Wi-Fi 5
# 'g' for 2.4GHz on IEEE 802.11g
hw_mode=a
# software WAP channel (must be the same as the Wi-Fi channel)
channel=${CHANNEL}
# Beacon interval in kus (1.024 ms)
beacon_int=100
# DTIM (delivery traffic information message) period
dtim_period=2
# Stations are not required to know the SSID to connect to the network
ignore_broadcast_ssid=0
# Enable short preamble for improved network performance
preamble=1
EOF

# Ask user to input which security protocol to use (None, WEP, WPA-PSK, WPA2-PSK)
USING_SECURITY_PROTOCOL=true
SECURITY_PROTOCOL="WPA"
echo -e "Select a wireless security protocol to use for the software WAP:"
select response in "None" "WEP" "WPA-PSK" "WPA2-PSK"; do
  case $response in
  None)
    USING_SECURITY_PROTOCOL=false
    tee -a "${HOSTAPD_CONF_FILE}" >/dev/null <<EOF
# Open System Authentication (OSA) but with no password
auth_algs=1
EOF
    echo -e "${RED}Warning: Open Wi-Fi network - ANYONE can connect!${NORMAL}"
    break
    ;;
  WEP)
    tee -a "${HOSTAPD_CONF_FILE}" >/dev/null <<EOF
# Shared Key Authentication (WEP)
auth_algs=2
EOF
    SECURITY_PROTOCOL="WEP"
    echo -e "Using ${BOLD}Wired Equivalent Privacy (WEP)${NORMAL}"
    break
    ;;
  WPA-PSK)
    tee -a "${HOSTAPD_CONF_FILE}" >/dev/null <<EOF
# Open System Authentication (OSA) with password
auth_algs=1
# Enable WPA
wpa=1
# Enable pre-shared key (PSK) for WPA
wpa_key_mgmt=WPA-PSK
# Temporal Key Integrity Protocol (TKIP) encryption algorithm for pairwise keys
wpa_pairwise=TKIP
# Explicitly disable Management Frame Protection (MFP), allowing for deauthentication attacks
ieee80211w=0
EOF
    echo -e "Using ${BOLD}Wi-Fi Protected Access Pre-Shared Key (WPA-PSK)${NORMAL}"
    break
    ;;
  WPA2-PSK)
    tee -a "${HOSTAPD_CONF_FILE}" >/dev/null <<EOF
# Open System Authentication (OSA) with password
auth_algs=1
# Enable WPA2
wpa=2
# Enable pre-shared key (PSK) for WPA
wpa_key_mgmt=WPA-PSK
# Robust Security Network (RSN) using pairwise cipher Counter Mode Cipher Block Chaining Message Authentication Code Protocol (CCMP)
rsn_pairwise=CCMP
# Explicitly disable Management Frame Protection (MFP), allowing for deauthentication attacks
ieee80211w=0
EOF
    echo -e "Using ${BOLD}Wi-Fi Protected Access 2 Pre-Shared Key (WPA2-PSK)${NORMAL}"
    break
    ;;
  esac
done
echo -e

# Ask user to input a Wi-Fi password after they select a security protocol
# Input password for WEP
if [ "$USING_SECURITY_PROTOCOL" == "true" ] && [ "$SECURITY_PROTOCOL" == "WEP" ]; then
  # Keep asking user to input a password until it is valid
  while true; do
    read -r -p "Enter WEP Wi-Fi password (5, 13, or 16 characters): " WIFI_PASSWORD
    case ${#WIFI_PASSWORD} in
    5 | 13 | 16) break ;;
    *) echo -e "Invalid Wi-Fi password length of ${BOLD}${#WIFI_PASSWORD}${NORMAL}. Must be 5, 13, or 16 characters for WEP.\n" ;;
    esac
  done
  tee -a "${HOSTAPD_CONF_FILE}" >/dev/null <<EOF
# Static WEP key configuration
# Key number to use when transmitting
wep_default_key=0
# Key/password
wep_key0=${WIFI_PASSWORD}
EOF
  echo -e
fi
# Input password for WPA
if [ "$USING_SECURITY_PROTOCOL" == "true" ] && [ "$SECURITY_PROTOCOL" == "WPA" ]; then
  while true; do
    read -r -p "Enter WPA Wi-Fi password (8-63 characters): " WIFI_PASSWORD
    if ((${#WIFI_PASSWORD} >= 8 && ${#WIFI_PASSWORD} <= 63)); then
      break
    else
      echo -e "Invalid Wi-Fi password length of ${BOLD}${#WIFI_PASSWORD}${NORMAL}. Must be between 8-63 characters for WPA.\n"
    fi
  done
  tee -a "${HOSTAPD_CONF_FILE}" >/dev/null <<EOF
# WPA Wi-Fi password
wpa_passphrase=${WIFI_PASSWORD}
EOF
  echo -e
fi

# Run the hostapd configuration file in the background
echo -e "Running ${BOLD}${HOSTAPD_CONF_FILE}${NORMAL} in the background"
hostapd -B ${HOSTAPD_CONF_FILE} >/dev/null
echo -e

# Enable the software WAP interface
ip link set dev "${WAP_INTERFACE_NAME}" up
echo -e "${GREEN}Software WAP running on name ${BOLD}${SSID}${NORMAL}"
