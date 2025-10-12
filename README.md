# Homemode Switcher2 for Synology Surveillance Station
Bash fork of dtypo’s Home-Mode-Switcher for Synology Surveillance Station. Includes robust MAC detection and direct Synology Home Mode sync.

This project is a **Bash-based fork** of [dtypo/Home-Mode-Switcher-for-Synology-Surveillance-Station](https://github.com/dtypo/Home-Mode-Switcher-for-Synology-Surveillance-Station).

It automatically enables or disables **Home Mode** in Synology Surveillance Station depending on the presence of specific devices in your home Wi-Fi network.

![homemode-switcher-Logo](homemode-switcher.png)

Unlike the original Python version, this script:
- is written entirely in **Bash**, no Python required;
- includes a **robust MAC address detection** method (works reliably with iPhones and Android devices);
- directly checks and syncs the actual **Synology Home Mode state** (never out of sync);
- is easy to automate via **Synology Task Scheduler**.

---

## ✨ Features
- ✅ Pure **Bash version** — no Python or `pyotp` required  
- ✅ Automatically toggles Home Mode via Synology Web API  
- ✅ Works with **Android and iOS (iPhones)** — includes enhanced MAC detection logic  
- ✅ Uses `nmap` or a fallback ping-sweep to discover active devices  
- ✅ Keeps Synology Home Mode state in sync with actual system state  
- ✅ Minimal setup and resource usage — runs directly on your NAS  
- ✅ Ideal for scheduled automation (via DSM Task Scheduler)

---

## 🧩 Requirements
- A Synology NAS with **DSM 7.x or newer**
- **Surveillance Station** installed and configured
- `nmap` available in your system PATH  
  *(You can install it from SynoCommunity or via Entware if missing)*

---

## ⚙️ Installation Instructions
Create a dedicated user with limited privileges (optional but recommended)
In Surveillance Station:
- Go to User → List → Add
- Create a new account (e.g. HomeModeSwitcher)
- Assign a permission profile where only “Manually switch to Home Mode” is allowed, and disable other privileges

This Bash version does not require Python3 or pyotp, so Python/pyotp does not need to be installed at all.

Download the script
1. Copy the script (e.g. `homemode_switcher2.sh`) to your NAS, e.g. `/volume1/`.
2. Edit the configuration section:
   ```bash
   SYNO_USER="HomeModeSwitcher"
   SYNO_PASS="yourpassword"
   SYNO_URL="192.168.xx.xx:5000"    # Replace with your NAS IP and DSM port
3. Set executable permissions
   SSH into your NAS and run:
   ```bash
   chmod +x /path/to/homemode_switcher2.sh
4. Note your authorized MAC addresses
   Choose which devices should trigger “Home” mode (e.g. your phone, partner’s phone, etc.).
   You will supply these MAC addresses as arguments when running the script.
5. Schedule execution of the script
   Use DSM’s Task Scheduler to run the script periodically:
   - Go to Control Panel → Task Scheduler → Create → Scheduled Task → User-defined script
   - Set:
      - Task name: e.g. homemode_switcher
      - User: root (or a user that has permission to run the script and access nmap, arp, etc.)
      - Frequency: every 5 or 10 minutes (as you prefer)
      - Run command:
        ```bash
        /bin/bash /volume1/Scripts/homemode_switcher2.sh AA:BB:CC:11:22:33 DD:EE:FF:44:55:66
        ```
        Replace with your actual MACs, space-separated
      - Optionally enable email notifications for failures
6. Test manually
   Run from SSH to test:
   ```bash
   /bin/bash /volume1/Scripts/homemode_switcher2.sh AA:BB:CC:11:22:33 DD:EE:FF:44:55:66
   ```
   Check console output: it should show:
   - Previous state
   - Scanning hosts
   - Matches found
   - Switching Home Mode (if needed)
7. Verify in Surveillance Station
   After the script runs, open Surveillance Station → Home Mode settings, and see if Home Mode is activated or deactivated as expected.

---

## 🔍 Troubleshooting
- If nmap returns nothing, the script automatically falls back to a quick ping sweep.
- iPhones may sleep their Wi-Fi chip; the script compensates by scanning the ARP cache and cross-checking multiple sources.
- If you manually change Home Mode, the script detects this on its next run and re-synchronizes.
- Add echo or DEBUG statements inside the script for deeper logging.

---

## 🧠 Technical Notes
- Uses Synology’s internal Surveillance Station Web API to toggle Home Mode.
- Detects devices by MAC address from nmap, ip neigh, or arp -an.
- Maintains a lightweight state file (homemode_switcher2.sh_AMIHOME) for reference between runs.
- Automatically reconciles file state and actual Synology state to prevent drift.

---

## 🪪 License
This project is released under the MIT License — the same as the original project.
```
MIT License

Copyright (c) 2025 [Your Name]

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
```
Credit and inspiration: [Home-Mode-Switcher-for-Synology-Surveillance-Station by dtypo](https://github.com/dtypo/Home-Mode-Switcher-for-Synology-Surveillance-Station)

---

## 🤝 Contributions welcome!
Feel free to fork, improve, and submit pull requests.
If you encounter bugs or have enhancement ideas, open an issue on GitHub.

