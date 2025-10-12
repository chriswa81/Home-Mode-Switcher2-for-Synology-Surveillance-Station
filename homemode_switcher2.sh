#!/bin/bash

########## Mandatory configuration
SYNO_USER="HomeModeSwitcher"
SYNO_PASS="yourpassword"
SYNO_URL="192.168.xx.xx:5000"    # Replace with your NAS IP and DSM port
######################################

ARGUMENTS=$@
MACS=$(echo $ARGUMENTS | tr '[:lower:]' '[:upper:]')

ID="$RANDOM"
COOKIESFILE="$0_cookies_$ID"
AMIHOME="$0_AMIHOME"


function switchHomemode() {
    login_output=$(wget -q --keep-session-cookies --save-cookies $COOKIESFILE -O- "http://${SYNO_URL}//webapi/auth.cgi?api=SYNO.API.Auth&method=login&version=3&account=${SYNO_USER}&passwd=${SYNO_PASS}&session=SurveillanceStation" | awk -F'[][{}]' '{ print $4 }' | awk -F':' '{ print $2 }')

    if [ "$login_output" == "true" ]; then
        homestate_prev_syno=$(wget -q --load-cookies $COOKIESFILE -O- "http://${SYNO_URL}//webapi/entry.cgi?api=SYNO.SurveillanceStation.HomeMode&version=1&method=GetInfo&need_mobiles=true" | awk -F',' '{ print $124 }' | awk -F':' '{ print $2 }')
        homestate_prev_syno=$(echo "$homestate_prev_syno" | tr -d '"')

        echo "[DEBUG] homestate_prev_syno='$homestate_prev_syno'"

        if [ "$homestate" == "true" ] && [ "$homestate_prev_syno" != "$homestate" ]; then
            switch_output=$(wget -q --load-cookies $COOKIESFILE -O- "http://${SYNO_URL}//webapi/entry.cgi?api=SYNO.SurveillanceStation.HomeMode&version=1&method=Switch&on=true")
            if [ "$switch_output" = '{"success":true}' ]; then
                echo "Homemode correctly activated"
            else
                echo "Something went wrong during the activation of Homemode"
                exit 1
            fi
        elif [ "$homestate" == "false" ] && [ "$homestate_prev_syno" != "$homestate" ]; then
            switch_output=$(wget -q --load-cookies $COOKIESFILE -O- "http://${SYNO_URL}//webapi/entry.cgi?api=SYNO.SurveillanceStation.HomeMode&version=1&method=Switch&on=false")
            if [ "$switch_output" = '{"success":true}' ]; then
                echo "Homemode correctly deactivated"
            else
                echo "Something went wrong during the deactivation of Homemode"
                exit 1
            fi
        else
            echo "No change needed, Synology Homemode already in desired state"
        fi

        # Update local AMIHOME cache file
        echo "$homestate" > $AMIHOME

        logout_output=$(wget -q --load-cookies $COOKIESFILE -O- "http://${SYNO_URL}/webapi/auth.cgi?api=SYNO.API.Auth&method=Logout&version=1")
        if [ "$logout_output" = '{"success":true}' ]; then
            echo "Logout to Synology successful"
        fi
    else
        echo "Login to Synology went wrong"
        exit 1
    fi

    rm $COOKIESFILE
}


function macs_check_v1() {
    matching_macs=0

    ip_pool="${SYNO_URL%:*}"
    base="${ip_pool%.*}"
    ip_pool="${base}.0/24"

    echo "Using ip_pool: $ip_pool"
    echo "Scanning hosts in the same network of the Synology NAS..."

    collected_macs=""
    if command -v nmap >/dev/null 2>&1; then
        echo "Trying nmap..."
        collected_macs=$(timeout 30 nmap -sn "$ip_pool" 2>/dev/null | awk '/MAC Address|MAC/{print $3}' || true)
    fi

    if [ -z "$collected_macs" ]; then
        echo "nmap returned nothing — performing quick ping-sweep..."
        for i in $(seq 1 254); do
            ping -c1 -W1 "${base}.${i}" >/dev/null 2>&1 &
        done
        wait
    fi

    arp_macs=""
    if [ -f /proc/net/arp ]; then
        arp_macs=$(awk 'NR>1 && $4!~/^00:00:00:00:00:00$/ {print toupper($4)}' /proc/net/arp || true)
    fi

    neigh_macs=$(ip neigh show 2>/dev/null | awk '/lladdr/ {print toupper($5)}' || true)

    all_macs=$(printf "%s\n%s\n%s\n" "$collected_macs" "$arp_macs" "$neigh_macs" \
        | tr '[:lower:]' '[:upper:]' \
        | sed '/^$/d' \
        | grep -E '^([0-9A-F]{2}:){5}[0-9A-F]{2}$' \
        | sort -u)

    if [ -z "$all_macs" ]; then
        echo "Keine gültigen MAC-Adressen gefunden."
        return 1
    fi

    echo -e "\nHosts found in your network (unique, filtered MACs):"
    matching_macs=0
    for host_mac in $all_macs; do
        echo "  $host_mac"
        for authorized_mac in $MACS; do
            if [ "$host_mac" = "$authorized_mac" ]; then
                matching_macs=$((matching_macs+1))
                echo "    -> Match with authorized MAC: $authorized_mac"
            fi
        done
    done
    return 0
}


function is_nighttime() {
    current_time=$(date "+%H%M")
    if [ "$current_time" -ge "0053" ] && [ "$current_time" -le "0458" ]; then
        return 0
    else
        return 1
    fi
}


if [ $# -eq 0 ]; then
    echo "MAC address or addresses missing"
    exit 1
fi

# Initialize AMIHOME cache if missing
if [ ! -f $AMIHOME ]; then
    echo "unknown" > $AMIHOME
fi

homestate_prev_file=$(<$AMIHOME)

echo "Executed at: $(/bin/date "+%d.%m.%Y, %H:%M:%S")"
echo "[Previous State] AMIHOME='$homestate_prev_file'"
echo "MAC addresses authorized to enable the Homemode: $MACS"

if is_nighttime; then
    echo "Nighttime, setting homestate to false..."
    homestate="false"
else
    macs_check_v1
    echo -e "\nTotal matches: $matching_macs"
    if [ "$matching_macs" -eq 0 ]; then
        homestate="false"
    else
        homestate="true"
    fi
fi

echo "[Current State] Desired homemode='$homestate'"

switchHomemode

echo
echo "Finished at: $(/bin/date "+%d.%m.%Y, %H:%M:%S")"
exit 0
