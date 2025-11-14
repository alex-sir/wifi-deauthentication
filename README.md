# Wi-Fi Deauthentication Attack Simulation Using Arch Linux

Scripts for performing a deauthentication attack on clients connected to a
software WAP on Arch Linux. For demonstration purposes only.

## Required Packages

- **aircrack-ng**: Suite of tools for auditing Wi-Fi security.
- **dnsmasq**: Lightweight DHCP and DNS server.
- **hostapd**: Daemon for creating Wi-Fi access points.
- **iproute2**: Collection of utilities for managing network interfaces, routing,
  and IP configuration.
- **iw**: Command-line tool for configuring wireless interfaces.
- **macchanger**: Utility to manipulate the MAC address of a network interface.
- **mdk3**: Wireless attack tool that exploits vulnerabilities in IEEE 802.11 networks.
- **networkmanager**: System service and tools for managing network connections,
  including Wi-Fi, Ethernet, and VPNs.
- **nftables**: Framework for packet filtering, NAT, and other tasks involving
  packet management.
- **psmisc**: Miscellaneous tools for the proc file system.
- **ripgrep**: Fast regex search tool.
- **wireshark-qt**: Qt-based GUI for Wireshark, a network protocol analyzer.

## Scripts

The scripts should be executed in the order listed here. All scripts except for **check-hardware.sh**
need to be executed with root privileges.

1. check-packages.sh
2. check-hardware.sh
3. setup-wap.sh
4. capture.sh
5. attack.sh
6. cleanup.sh
