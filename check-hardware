#!/bin/bash
# Check wireless network interface controllers (WNICs) support for monitor mode and software WAPs
# Dependencies:
# - https://git.kernel.org/pub/scm/linux/kernel/git/jberg/iw.git
# - https://github.com/BurntSushi/ripgrep

BOLD="\e[1m"
RED="\e[0;31m"
GREEN="\e[0;32m"
BLUE="\e[0;34m"
YELLOW="\e[0;33m"
NORMAL="\e[0m"

NUM_REQUIRED_WIFI_INTERFACES=2

echo -e "${BLUE}${BOLD}*** Wi-Fi Deauthentication Attack Simulation Using Arch Linux ***${NORMAL}"
echo -e "${YELLOW}=== Hardware Check ===${NORMAL}"
echo -e "${GREEN}NOTICE: This script performs a basic check. Verify more thoroughly yourself with the command 'iw list'.${NORMAL}\n"

# Find the names of the WNICs
readarray -t WIFI_INTERFACES < <(iw dev | rg -o 'wlp.*')

# List the names of the found WNICs
echo -e "Found ${BOLD}${#WIFI_INTERFACES[@]}${NORMAL} wireless network interface(s):"
for wifi_interface in "${WIFI_INTERFACES[@]}"; do
  echo -e "${BOLD}$wifi_interface${NORMAL}"
done
echo -e

# Check that the appropriate number of WNICs are present in the system
if [ ${#WIFI_INTERFACES[@]} -lt ${NUM_REQUIRED_WIFI_INTERFACES} ]; then
  echo -e "${RED}${BOLD}WARNING: ${NUM_REQUIRED_WIFI_INTERFACES} or more wireless network interfaces are required. Found ${#WIFI_INTERFACES[@]}.${NORMAL}"
  exit 1
fi

# List the supported interface modes of all WNICs
iw list | rg -A 7 "Supported interface modes"
echo -e "\n${GREEN}Check that both '* AP' and '* monitor' are present for all wireless network interfaces.${NORMAL}"
