#!/bin/bash
# Stop and clean up processes related to a Wi-Fi deauthentication attack simulation
# Dependencies:
# - https://git.kernel.org/pub/scm/linux/kernel/git/jberg/iw.git
# - https://github.com/BurntSushi/ripgrep
# - https://gitlab.freedesktop.org/NetworkManager/NetworkManager

BOLD="\e[1m"
GREEN="\e[0;32m"
BLUE="\e[0;34m"
YELLOW="\e[0;33m"
NORMAL="\e[0m"

echo -e "${BLUE}${BOLD}*** Wi-Fi Deauthentication Attack Simulation Using Arch Linux ***${NORMAL}"
echo -e "${YELLOW}=== Cleanup ===${NORMAL}\n"

# Find the names of the wireless network interface controllers (WNICs)
readarray -t WIFI_INTERFACES < <(iw dev | rg -o 'wlp.*')

# Stop interface monitor mode
# Find the WNIC that is the monitor
for interface in "${WIFI_INTERFACES[@]}"; do
  if [[ "${interface}" == *mon ]]; then
    MONITOR_INTERFACE_NAME="${interface}"
    break
  fi
done
echo -e "Stopping monitor mode for the interface"
sudo airmon-ng stop "${MONITOR_INTERFACE_NAME}"
echo -e

# Stop dnsmasq & hostapd processes
echo -e "Stopping ${BOLD}dnsmasq${NORMAL} & ${BOLD}hostapd${NORMAL}"
sudo killall dnsmasq hostapd
echo -e

# Delete the virtual interface for the software WAP
# Find the WNIC that is the software WAP
for interface in "${WIFI_INTERFACES[@]}"; do
  if [[ "${interface}" == *_wap ]]; then
    WAP_INTERFACE_NAME="${interface}"
    break
  fi
done
echo -e "Deleting virtual interface for the software WAP ${BOLD}${WAP_INTERFACE_NAME}${NORMAL}"
sudo iw dev "${WAP_INTERFACE_NAME}" del
echo -e

# Disable packet forwarding using sysctl
echo -e "Disabling IPv4 & IPv6 packet forwarding"
sudo sysctl -w net.ipv4.ip_forward=0 \
  net.ipv4.conf.all.forwarding=0 \
  net.ipv6.conf.all.forwarding=0
echo -e

# Remove the NAT table
echo -e "Removing the NAT table"
sudo nft delete table inet nat
echo -e

# Restart NetworkManager
echo -e "Restarting NetworkManager"
sudo systemctl start NetworkManager
echo -e

# Re-enable UFW
if command -v ufw >/dev/null 2>&1 && sudo ufw status | rg -q "Status: inactive"; then
  echo -e "Inactive UFW instance detected - enabling"
  sudo ufw enable
  echo -e
fi

echo -e "${GREEN}Cleanup complete - system restored${NORMAL}"
