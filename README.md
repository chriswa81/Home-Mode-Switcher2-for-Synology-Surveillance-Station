# Home-Mode-Switcher2-for-Synology-Surveillance-Station
Bash fork of dtypo’s Home-Mode-Switcher for Synology Surveillance Station. Includes robust MAC detection and direct Synology Home Mode sync.

This project is a **Bash-based fork** of [dtypo/Home-Mode-Switcher-for-Synology-Surveillance-Station](https://github.com/dtypo/Home-Mode-Switcher-for-Synology-Surveillance-Station).

It automatically enables or disables **Home Mode** in Synology Surveillance Station depending on the presence of specific devices in your home Wi-Fi network.

Unlike the original Python version, this script:
- is written entirely in **Bash**, no Python required;
- includes a **robust MAC address detection** method (works reliably with iPhones and Android devices);
- directly checks and syncs the actual **Synology Home Mode state** (never out of sync);
- is easy to automate via **Synology Task Scheduler**.

---

## ✨ Features
- Automatic switching of Surveillance Station Home Mode.
- Reliable detection of devices (via `nmap`, `arp`, `ip neigh`).
- Works even if Home Mode was changed manually in Surveillance Station.
- Designed for Synology NAS (DSM 7.x+).

---

## ⚙️ Requirements
- Synology NAS with Surveillance Station.
- `nmap` installed (available via SynoCommunity or package manager).
- Bash 4+.
- No Python required.

---

## 🚀 Usage
1. Copy the script (e.g. `homemode_switcher2.sh`) to your NAS, e.g. `/volume1/`.
2. Edit the configuration section:
   ```bash
   SYNO_USER="HomeModeSwitcher"
   SYNO_PASS="yourpassword"
   SYNO_URL="192.168.xx.xx:5000"
