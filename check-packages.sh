#!/bin/bash
# Check & install required & optional Arch Linux packages for a Wi-Fi deauthentication attack simulation
# Author: Alex Carbajal

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
  echo -e "${RED}\n\nPackage check interrupted. Exiting...${NORMAL}"
  exit 130
}
trap exit_script INT

REQUIRED_PACKAGES=(
  "aircrack-ng"
  "dnsmasq"
  "hostapd"
  "iproute2"
  "iw"
  "macchanger"
  "mdk3"
  "networkmanager"
  "nftables"
  "psmisc"
  "ripgrep"
  "wireshark-qt"
)
OPTIONAL_PACKAGES=(
  "wavemon"
)
MISSING_REQUIRED_PACKAGES=()
MISSING_OPTIONAL_PACKAGES=()

# Check if a package is installed
# $1 = package name
is_installed() {
  pacman -Q "$1" &>/dev/null
}

echo -e "${BLUE}${BOLD}*** Wi-Fi Deauthentication Attack ***${NORMAL}"
echo -e "${YELLOW}=== Package Setup ===${NORMAL}"

# Check if the user already has all required packages installed
echo -e "\n${YELLOW}=== REQUIRED PACKAGES ===${NORMAL}"
all_required_packages_installed=true
for package in "${REQUIRED_PACKAGES[@]}"; do
  if is_installed "$package"; then
    echo -e "${GREEN}✔  ${NORMAL}${package}"
  else
    echo -e "${RED}🗙  ${NORMAL}${package}"
    MISSING_REQUIRED_PACKAGES+=("$package")
    all_required_packages_installed=false
  fi
done
if [ "$all_required_packages_installed" == "true" ]; then
  echo -e "All required packages are installed."
fi

# Check if the user already has all optional packages installed
echo -e "\n${YELLOW}=== OPTIONAL PACKAGES ===${NORMAL}"
all_optional_packages_installed=true
for package in "${OPTIONAL_PACKAGES[@]}"; do
  if is_installed "$package"; then
    echo -e "${GREEN}✔  ${NORMAL}${package}"
  else
    echo -e "${RED}🗙  ${NORMAL}${package}"
    MISSING_OPTIONAL_PACKAGES+=("$package")
    all_optional_packages_installed=false
  fi
done
if [ "$all_optional_packages_installed" == "true" ]; then
  echo -e "All optional packages are installed."
fi

if [ "$all_required_packages_installed" == "true" ] && [ "$all_optional_packages_installed" == "true" ]; then
  exit 0
fi
echo -e

# Ask user for input on whether to install missing required packages
if [ "$all_required_packages_installed" == "false" ]; then
  echo -e "${YELLOW}=== INSTALL MISSING REQUIRED PACKAGES ===${NORMAL}"
  echo -e "Install ${BOLD}${#MISSING_REQUIRED_PACKAGES[@]}${NORMAL} missing required package(s)?"
  select response in "Yes" "No"; do
    case $response in
    Yes)
      pacman -Syu "${MISSING_REQUIRED_PACKAGES[@]}"
      break
      ;;
    No) break ;;
    esac
  done
  echo -e
fi

# Ask user for input on whether to install missing optional packages
if [ "$all_optional_packages_installed" == "false" ]; then
  echo -e "${YELLOW}=== INSTALL MISSING OPTIONAL PACKAGES ===${NORMAL}"
  echo -e "Install ${BOLD}${#MISSING_OPTIONAL_PACKAGES[@]}${NORMAL} missing optional package(s)?"
  select response in "Yes" "No"; do
    case $response in
    Yes)
      pacman -Syu "${MISSING_OPTIONAL_PACKAGES[@]}"
      break
      ;;
    No) break ;;
    esac
  done
  echo -e
fi

echo -e "${YELLOW}=== Package Installation Complete ===${NORMAL}"
echo -e "${GREEN}${BOLD}NOTICE: Reboot or log out/in for group changes (e.g., wireshark).${NORMAL}"
