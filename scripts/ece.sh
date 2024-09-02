#!/bin/bash

source /Users/sixsa/.dotfiles/.secrets.env

LOGIN_COMMAND="ssh -X $VPN_USERNAME@ecelinux.ece.cornell.edu"
VPN_EXEC=/opt/cisco/secureclient/bin/vpn

# Color codes
BLUE='\033[38;2;137;160;195m'  # #89a0c3 (Light Blue)
GREEN='\033[38;2;182;189;136m'  # #b6bd88 (Light Green)
YELLOW='\033[38;2;217;166;126m' # #d9a67e (Peach/Brown)
RED='\033[38;2;226;121;120m'    # #e27978 (Red)
NC='\033[0m'

# Message types
OK="${GREEN}●${NC}"
FAIL="${RED}●${NC}"
WARN="${YELLOW}◍${NC}"
INFO="${BLUE}○${NC}"

get_os_vers() {
    local os_version=$(sw_vers -productVersion)
    echo -e "$os_version"
}

# For MacOS <= 14
get_ssid_old() {
    local ssid=$(/System/Library/PrivateFrameworks/Apple80211.framework/Resources/airport -I | awk -F': ' '/ SSID/{print $2}')

    # Trim leading and trailing whitespace and linebreaks
    ssid=$(echo "$ssid" | tr -d '\n' | awk '{$1=$1};1')

    echo "$ssid"
}

# More MacOS == 15
get_ssid_new() {
    local ssid=$(sudo wdutil info | awk -F': ' '/ SSID/{print $2}')

    # Trim leading and trailing whitespace and linebreaks
    ssid=$(echo "$ssid" | tr -d '\n' | awk '{$1=$1};1')

    echo "$ssid"
}


is_empty() {
    [ -z "$1" ]
}

contains() {
    local element
    for element in "${@:2}"; do
        if [[ "$element" == "$1" ]]; then
            return 0
        fi
    done
    return 1
}

vpn_connected() {
    local status_output
    status_output=$($VPN_EXEC status | grep "state:" | tail -n 1)

    if [[ "$status_output" == *"Connected"* ]]; then
        return 0  # true
    else
        return 1  # false
    fi
}

connect_to_vpn() {

    # WARNING: Don't connect if already connected to VPN: stuff gets wonky

    # Generate secureclient.txt file dynamically using secretss
    cat <<EOF > ./secureclient.txt
connect $VPN_HOST
$VPN_USERNAME
$VPN_PASSWORD
$VPN_METHOD
y
exit
EOF

    # Connect
    $VPN_EXEC -s < ./secureclient.txt

    # Capture the return code
    local ret_code=$?

    # For security
    rm ./secureclient.txt

    # Accept push!

    # Return the captured return code
    return $ret_code
}

# Main script logic
connect() {

    echo -ne "${INFO} Getting macOS Version... "
    VERS=$(get_os_vers)
    echo -e "$VERS"
    local major_version=$(echo "$VERS" | awk -F '.' '{print $1}')

    echo -ne "${INFO} Fetching SSID... "
    if (( major_version <= 14 )); then
        SSID=$(get_ssid_old)
    else
        SSID=$(get_ssid_new)
    fi
    echo -e "$SSID"

    if is_empty "$SSID"; then
        echo -e "${FAIL} No network detected. Please connect to a network and try again."
        return
    fi

    CORNELL_NETWORKS=(
        "eduroam"
        "RedRover"
        "Cornell-Visitor"
    )

    if contains "$SSID" "${CORNELL_NETWORKS[@]}"; then
        echo -e "${OK} Connected to a Cornell network [$SSID]."
    else
        echo -e "${WARN} Not connected to a Cornell network."
        echo -e "${INFO} Checking VPN status..."

        if vpn_connected; then
            echo -e "${OK} Already connected to Cornell VPN."
        else
            echo -e "${WARN} Not connected to Cornell VPN."
            echo -e "${INFO} Attepting to connect to VPN..."
            connect_to_vpn

            vpn_return_code=$?

            if [ $vpn_return_code -ne 0 ]; then
                echo -e "${FAIL} Failed to connect to VPN. Return code: $vpn_return_code"
                return
            fi

            echo -e "${OK} VPN connected successfully."

        fi
    fi

    if pgrep -x "Xquartz" > /dev/null; then
        echo -e "${OK} XQuartz is running."
    else
        echo -e "${WARN} XQuartz is not running."
        echo -e "${INFO} Starting XQuartz..."
        open -a XQuartz

        xquartz_return_code=$?

        if [ $xquartz_return_code -ne 0 ]; then
            echo -e "${WARN} Could not open XQuartz."
        else
            echo -e "${OK} Started XQuartz."
        fi
    fi

    echo -e "${INFO} Logging in to ecelinux..."
    $LOGIN_COMMAND
}
