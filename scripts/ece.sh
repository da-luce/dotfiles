#!/bin/bash

source /Users/sixsa/.dotfiles/.secrets.env

LOGIN_COMMAND="ssh $VPN_USERNAME@ecelinux.ece.cornell.edu"
VPN_EXEC=/opt/cisco/secureclient/bin/vpn

get_ssid() {
    local ssid=$(/System/Library/PrivateFrameworks/Apple80211.framework/Resources/airport -I | awk -F': ' '/ SSID/{print $2}')

    # Trim leading and trailing whitespace and linebreaks
    ssid=$(echo "$ssid" | tr -d '\n' | awk '{$1=$1};1')

    echo "$ssid"
}

is_empty() {
    local var="$1"
    [[ -z "${var// }" ]]
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

    # For security
    rm ./secureclient.txt

    # Accept push!
}

# Main script logic
connect() {
    SSID=$(get_ssid)

    if is_empty "$SSID"; then
        echo "No network detected. Please connect to a network and try again."
        return
    fi

    CORNELL_NETWORKS=(
        "eduroam"
        "RedRover"
        "Cornell-Visitor"
    )

    if contains "$SSID" "${CORNELL_NETWORKS[@]}"; then
        echo "Connected to a Cornell network [$SSID]. Logging in to ecelinux..."
        $LOGIN_COMMAND
    else
        echo $SSID
        echo "Not connected to a Cornell network [$SSID]. Checking VPN status..."

        if vpn_connected; then
            echo "Already connected to Cornell VPN."
            $LOGIN_COMMAND
        else
            echo "Not connected to Cornell VPN."
            echo "Attepting to connect to VPN..."
            connect_to_vpn
            echo "Logging in to ecelinux..."
            $LOGIN_COMMAND
        fi
    fi
}
