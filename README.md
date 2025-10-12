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

