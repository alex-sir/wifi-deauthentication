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
- **networkmanager**: System service and tools for managing network connections,
  including Wi-Fi, Ethernet, and VPNs.
- **nftables**: Framework for packet filtering, NAT, and other tasks involving
  packet management.
- **psmisc**: Miscellaneous tools for the proc file system.
- **wireshark-qt**: Qt-based GUI for Wireshark, a network protocol analyzer.

## Order of Execution for Scripts

1. check-packages.sh
2. check-hardware.sh
3. setup-wap.sh
4. display.sh
5. capture.sh
6. attack.sh
7. cleanup.sh
