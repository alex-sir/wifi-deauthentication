#!/bin/bash
# Perform a simulation of a Wi-Fi deauthentication attack using aircrack-ng
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
echo -e "${YELLOW}=== Perform Deauthentication Attack Step 1: Display ===${NORMAL}\n"

# Three terminal windows are required for the attack, notify the user
echo -e "Three terminal windows are ${BOLD}required${NORMAL} to perform the deauthentication attack:"
echo -e "${GREEN}${BOLD}1. Display the WAP that will be attacked${NORMAL}"
echo -e "2. Capture data from the WAP into a file"
echo -e "3. Perform the deauthentication attack"
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
INTERFACE_NAME="${WIFI_INTERFACES[${INTERFACE_I} - 1]}"

# Set the interface into monitor mode
INTERFACE_NAME_MONITOR="${INTERFACE_NAME}mon"
echo -e "Setting interface ${BOLD}${INTERFACE_NAME}${NORMAL} into monitor mode"
sudo airmon-ng start "${INTERFACE_NAME}"
echo -e "Monitoring interface name is ${BOLD}${INTERFACE_NAME_MONITOR}${NORMAL}\n"

# Discover wireless access points (WAPs) around the monitoring interface
echo -e "Searching for WAPs using ${BOLD}${INTERFACE_NAME_MONITOR}${NORMAL}"
echo -e "${GREEN}Note down the ${BOLD}BSSID${NORMAL}${GREEN} & ${BOLD}CH${NORMAL}${GREEN} value of the WAP you wish to attack. You will be asked to enter them.${NORMAL}"
read -n 1 -s -r -p "Press any key to continue..."
echo -e
sudo airodump-ng -b abg "${INTERFACE_NAME_MONITOR}"
# Ask user to enter BSSID value of the WAP they wish to attack
read -rp "Enter BSSID of WAP to attack (MAC Address, e.g. AA:BB:CC:11:22:33): " BSSID
echo -e

# Display only the specified WAP that will be attacked
echo -e "Displaying WAP with BSSID ${BOLD}${BSSID}${NORMAL}"
read -n 1 -s -r -p "Press any key to continue..."
echo -e
sudo airodump-ng -b abg "${INTERFACE_NAME_MONITOR}" -d "${BSSID}"
