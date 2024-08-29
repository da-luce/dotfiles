#!/bin/bash

source /Users/sixsa/.dotfiles/.secrets.env

LOGIN_COMMAND="ssh -X $VPN_USERNAME@ecelinux.ece.cornell.edu"
VPN_EXEC=/opt/cisco/secureclient/bin/vpn

# Color codes
BLUE='\033[38;2;137;160;195m'  # #89a0c3 (Light Blue)
GREEN='\033[38;2;182;189;136m'  # #b6bd88 (Light Green)
YELLOW='\033[38;2;217;166;126m' # #d9a67e (Peach/Brown)
NC='\033[0m'

# Message types
GOOD="${GREEN}●${NC}"
WARN="${YELLOW}◍${NC}"
INFO="${BLUE}○${NC}"

get_ssid() {
    local ssid=$(/System/Library/PrivateFrameworks/Apple80211.framework/Resources/airport -I | awk -F': ' '/ SSID/{print $2}')

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

    echo -ne "${INFO} Fetching SSID... "
    SSID=$(get_ssid)
    echo -e "$SSID"

    if is_empty "$SSID"; then
        echo "${WARN} No network detected. Please connect to a network and try again."
        return
    fi

    if pgrep -x "Xquartz" > /dev/null; then
        echo -e "${GOOD} XQuartz is running."
    else
        echo -e "${WARN} XQuartz is not running."
        # TODO: start xquartz
    fi

    CORNELL_NETWORKS=(
        "eduroam"
        "RedRover"
        "Cornell-Visitor"
    )

    if contains "$SSID" "${CORNELL_NETWORKS[@]}"; then
        echo -e "${GOOD} Connected to a Cornell network [$SSID]."
        echo -e "${INFO} Logging in to ecelinux..."
        $LOGIN_COMMAND
    else
        echo -e "${WARN} Not connected to a Cornell network [$SSID]."
        echo -e "${INFO} Checking VPN status..."

        if vpn_connected; then
            echo -e "${GOOD} Already connected to Cornell VPN."
            $LOGIN_COMMAND
        else
            echo -e "${WARN} Not connected to Cornell VPN."
            echo -e "${INFO} Attepting to connect to VPN..."
            connect_to_vpn

            vpn_return_code=$?

            if [ $vpn_return_code -ne 0 ]; then
                echo -e "${WARN} Failed to connect to VPN. Return code: $vpn_return_code"
                return
            fi

            echo -e "${GOOD} VPN connected successfully."
            echo -e "${INFO} Logging in to ecelinux..."

            $LOGIN_COMMAND
        fi
    fi
}
