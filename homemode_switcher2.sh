#!/bin/bash
#
# Home-Mode Switcher for Synology Surveillance Station (FritzBox Integration)
# ------------------------------------------------------------
# Version: 1.03
#
# Erkennt Geräte (per MAC-Adresse) im Netzwerk über:
#   1. FRITZ!Box-API (fritzconnection, Python in venv)
#   2. Fallback: lokaler Ping-/ARP-Scan
#
# Schaltet den Surveillance Station Home Mode automatisch ein/aus.
#

########## Pflicht-Konfiguration ##########
SYNO_USER="SYNO_USER"					# Synology User
SYNO_PASS="SYNO_PASS"					# Synology-Password
SYNO_URL="192.168.xxx.xxx:xxxx"    		# IP and DSM-Port Synology
FRITZ_IP="192.168.xxx.xxx"           	# IP FritzBox
FRITZ_USER="FRITZ_USER"     			# FritzBox-User
FRITZ_PASS="FRITZ_PASS"					# FritzBox-Password
VENV_PYTHON="$(dirname "$0")/venv/bin/python3"   # Path to Python inside virtual environment (auto-detected)
###########################################

ARGUMENTS=$@
MACS=$(echo $ARGUMENTS | tr '[:lower:]' '[:upper:]')

ID="$RANDOM"
COOKIESFILE="/tmp/homemode_cookies_$ID"

#############################################
# Funktion: Home Mode auf Synology umschalten
#############################################
function switchHomemode() {
    # Login bei der Synology
    local login_output
    login_output=$(wget -q --keep-session-cookies --save-cookies "$COOKIESFILE" -O- \
        "http://${SYNO_URL}/webapi/auth.cgi?api=SYNO.API.Auth&method=login&version=3&account=${SYNO_USER}&passwd=${SYNO_PASS}&session=SurveillanceStation")

    # Erfolg prüfen
    if ! echo "$login_output" | grep -q '"success":[[:space:]]*true'; then
        echo "[ERROR] Login zur Synology fehlgeschlagen."
        rm -f "$COOKIESFILE"
        return 1
    fi

    # Aktuellen Zustand der SS auslesen
    local homestate_prev_syno
    homestate_prev_syno=$(wget -q --load-cookies "$COOKIESFILE" -O- \
        "http://${SYNO_URL}/webapi/entry.cgi?api=SYNO.SurveillanceStation.HomeMode&version=1&method=GetInfo" \
        | grep -o '"on":[^,]*' | cut -d':' -f2 | tr -d '"')

    echo "[DEBUG] homestate_prev_syno='$homestate_prev_syno'"

    # Wenn gleich → keine Aktion
    if [ "$homestate_prev_syno" == "$homestate" ]; then
        echo "Keine Änderung nötig (Homemode bereits im gewünschten Zustand)"
        rm -f "$COOKIESFILE"
        return 0
    fi

    # Umschalten nur bei Änderung
    if [ "$homestate" == "true" ]; then
        switch_output=$(wget -q --load-cookies "$COOKIESFILE" -O- \
            "http://${SYNO_URL}/webapi/entry.cgi?api=SYNO.SurveillanceStation.HomeMode&version=1&method=Switch&on=true")
        [[ "$switch_output" = '{"success":true}' ]] && echo "Homemode aktiviert" || echo "Fehler bei Aktivierung"
    else
        switch_output=$(wget -q --load-cookies "$COOKIESFILE" -O- \
            "http://${SYNO_URL}/webapi/entry.cgi?api=SYNO.SurveillanceStation.HomeMode&version=1&method=Switch&on=false")
        [[ "$switch_output" = '{"success":true}' ]] && echo "Homemode deaktiviert" || echo "Fehler bei Deaktivierung"
    fi

    
    # Logout
    wget -q --load-cookies "$COOKIESFILE" -O- \
        "http://${SYNO_URL}/webapi/auth.cgi?api=SYNO.API.Auth&method=Logout&version=1" >/dev/null
    rm -f "$COOKIESFILE"
}

#############################################
# Funktion: MAC-Adressen über FritzBox lesen
#############################################
function macs_from_fritzbox() {
    echo "Versuche, aktive Geräte über FritzBox-API zu ermitteln..."
    local fritz_macs=""
    local tmpfile
    tmpfile=$(mktemp /tmp/fritz_hosts_XXXX.json)

    "$VENV_PYTHON" - <<EOF > "$tmpfile"
from fritzconnection.lib.fritzhosts import FritzHosts
try:
    fh = FritzHosts(address="${FRITZ_IP}", user="${FRITZ_USER}", password="${FRITZ_PASS}")
    hosts = fh.get_hosts_info()
    for h in hosts:
        if h.get("status") in (True, "1") and h.get("mac"):
            print(h["mac"].upper())
except Exception as e:
    print("Fehler in FritzBox-Abfrage:", e)
EOF

    fritz_macs=$(grep -E '^([0-9A-F]{2}:){5}[0-9A-F]{2}$' "$tmpfile" | sort -u)
    rm -f "$tmpfile"
    echo "$fritz_macs"
}

#############################################
# Fallback: lokaler Ping-/ARP-Scan
#############################################
function macs_fallback_scan() {
    local collected=""
    local base
    base=$(echo "$SYNO_URL" | cut -d':' -f1)
    base="${base%.*}"
    local ip_pool="${base}.0/24"
    echo "Führe Fallback-Ping-/ARP-Scan durch ($ip_pool)..."

    for i in $(seq 1 254); do
        ping -c1 -W1 "${base}.${i}" >/dev/null 2>&1 &
    done
    wait
    collected=$(awk 'NR>1 {print toupper($4)}' /proc/net/arp | grep -E '^([0-9A-F]{2}:){5}[0-9A-F]{2}$' | sort -u)
    echo "$collected"
}

#############################################
# MAC-Adressen prüfen
#############################################
function macs_check_v1() {
    matching_macs=0

    all_macs=$(macs_from_fritzbox)

    # Falls FritzBox nichts liefert → Fallback
    if [ -z "$all_macs" ]; then
        echo "[WARN] FritzBox-API lieferte keine Daten — nutze Fallback."
        all_macs=$(macs_fallback_scan)
    fi

    if [ -z "$all_macs" ]; then
        echo "[ERROR] Keine MAC-Adressen gefunden – Abbruch."
        exit 1
    fi

    echo -e "\nGefundene MAC-Adressen im Netzwerk:"
    echo "$all_macs"
    echo ""

    for host_mac in $all_macs; do
        for authorized_mac in $MACS; do
            if [ "$host_mac" == "$authorized_mac" ]; then
                matching_macs=$((matching_macs + 1))
                echo "  -> Treffer mit autorisierter MAC: $authorized_mac"
            fi
        done
    done
}

#############################################
# Nachtmodus (optional)
#############################################
function is_nighttime() {
    current_time=$(date "+%H%M")
    if [ "$current_time" -ge "0053" ] && [ "$current_time" -le "0458" ]; then
        return 0
    else
        return 1
    fi
}

#############################################
# Hauptprogramm
#############################################
if [ $# -eq 0 ]; then
    echo "Fehler: Keine MAC-Adresse angegeben."
    exit 1
fi

# Live-Zustand von der Synology lesen
echo "Ermittle aktuellen HomeMode-Status aus Surveillance Station..."
homestate_prev_file=$(wget -q -O- \
  "http://${SYNO_URL}/webapi/auth.cgi?api=SYNO.API.Auth&method=login&version=3&account=${SYNO_USER}&passwd=${SYNO_PASS}&session=SurveillanceStation" \
  --save-cookies "$COOKIESFILE" --keep-session-cookies \
  | grep -q '"success":[[:space:]]*true' && \
  wget -q --load-cookies "$COOKIESFILE" -O- \
  "http://${SYNO_URL}/webapi/entry.cgi?api=SYNO.SurveillanceStation.HomeMode&version=1&method=GetInfo" \
  | grep -o '"on":[^,]*' | cut -d':' -f2 | tr -d '"')

if [ -z "$homestate_prev_file" ]; then
    homestate_prev_file="unknown"
fi
rm -f "$COOKIESFILE"

echo "[Previous State] Homemode (Synology)='$homestate_prev_file'"


echo "Executed at: $(date '+%d.%m.%Y, %H:%M:%S')"
echo "[Previous State] AMIHOME='$homestate_prev_file'"
echo "Autorisierte MAC-Adressen: $MACS"

# Nachtmodus oder FritzBox-Prüfung
if is_nighttime; then
    echo "Nachtmodus erkannt – Homemode AUS."
    homestate="false"
else
    macs_check_v1
    echo -e "\nTreffer insgesamt: $matching_macs"
    if [ "$matching_macs" -eq 0 ]; then
        homestate="false"
    else
        homestate="true"
    fi
fi

echo "[Current State] Desired homemode='$homestate'"

# HomeMode nur umschalten, wenn sich etwas geändert hat
if [ "$homestate_prev_file" == "$homestate" ]; then
    echo "Zustand unverändert – kein Umschalten nötig."
else
    switchHomemode
fi

echo
echo "Finished at: $(date '+%d.%m.%Y, %H:%M:%S')"
exit 0
