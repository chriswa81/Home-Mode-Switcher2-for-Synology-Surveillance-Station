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
- Go to **User** → **List** → **Add**
- Create a new account (e.g. HomeModeSwitcher)
- Assign a permission profile where only “Manually switch to Home Mode” is allowed, and disable other privileges

This Bash version does not require Python3 or pyotp, so Python/pyotp does not need to be installed at all.

Download the script
1. Download the script (e.g. `homemode_switcher2.sh`) to your NAS, e.g. `/volume1/`.
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
6. Schedule execution of the script
   
   Use DSM’s Task Scheduler to run the script periodically:
   - Go to **Control Panel** → **Task Scheduler** → **Create** → **Scheduled Task** → **User-defined script**
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
8. Test manually
   Run from SSH to test:
   ```bash
   /bin/bash /volume1/Scripts/homemode_switcher2.sh AA:BB:CC:11:22:33 DD:EE:FF:44:55:66
   ```
   Check console output: it should show:
   - Previous state
   - Scanning hosts
   - Matches found
   - Switching Home Mode (if needed)
9. Verify in Surveillance Station

   After the script runs, open Surveillance Station → Home Mode settings, and see if Home Mode is activated or deactivated as expected.

---

## 🔧 Recommended Package
For best performance, install the **SynoCli Network Tools** package from SynoCommunity.
This package provides **`nmap`** and **`fping`**, which make network scanning faster and more reliable.
Installation:
1. Open **Package Center** on your Synology NAS
2. Go to **Settings** → **Package Sources**
3. Add SynoCommunity:
   ```bash
   Name: SynoCommunity
   Location: https://packages.synocommunity.com/
   ```
4. Apply the changes and go back to the main Package Center
5. Search for **SynoCli Network Tools** and click **Install**

The script will still work without this package, but scanning will be slower and may miss some devices.

---

## 🌙 Nighttime Mode (Optional)
The script includes an optional helper function called **`is_nighttime()`**.
It allows you to automatically disable Home Mode during specific nighttime hours — for example, to save power or silence notifications while everyone is asleep.

By default, the function looks like this:
```bash
function is_nighttime() {
    current_time=$(date "+%H%M")
    if [ "$current_time" -ge "0053" ] && [ "$current_time" -le "0458" ]; then
        return 0
    else
        return 1
    fi
}
```
This means:
-  Between **00:53 (12:53 AM)** and **04:58 (4:58 AM)** → **`is_nighttime()`** returns *true*
   → the script automatically sets Home Mode to **false**
- At all other times, the normal MAC detection logic is used.

You can easily adjust these hours to fit your own schedule.
For example, to define nighttime between **23:00 and 06:00**, change the lines to:
```bash
if [ "$current_time" -ge "2300" ] || [ "$current_time" -lt "0600" ]; then
```
If you prefer to disable this feature entirely, simply make the function always return **`1`**:
```bash
is_nighttime() { return 1; }
```

---

## 🔍 Troubleshooting
- **`nmap`** **not found or returns nothing**
  
  If **`nmap`** is missing or not found in your system path, the script automatically falls back to a quick **`ping`** sweep.
  This fallback works but may not refresh the ARP table quickly enough — meaning Home Mode changes can be delayed.
  To fix this:
  ```bash
  which nmap
  ```
  If it returns nothing, make sure **SynoCli Network Tools** is installed on your Synology NAS and try adding **`nmap`** to your system path:
  ```bash
  export PATH=$PATH:/usr/local/bin
  ```
  Then rerun the script. Once **`nmap`** is available, network scanning becomes much faster and more reliable. 🚀
- **iPhones not detected immediately**
  
  iPhones sometimes put their Wi-Fi chip to sleep to save power.
  The script mitigates this by checking both the ARP cache and direct ICMP pings.
  Short detection delays (up to 1–2 minutes) can still occur until the iPhone becomes active again.
  This behavior is normal and not caused by the script.
- **Manual Home Mode changes not reflected**
  
  If you manually toggle Home Mode (e.g., via the Synology app or Surveillance Station),
  the script will automatically detect this on its next run and re-synchronize the internal state.

---

## 💡 Tips for reliable performance
- Ensure **SynoCli Network Tools** (with **`nmap`**) is installed and functional.
- Run the script via **Task Scheduler** every 1–2 minutes.
- Keep your NAS and all tracked devices within the same local subnet.
- Disable Private Wi-Fi Address on iPhones to ensure consistent MAC address detection.

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

