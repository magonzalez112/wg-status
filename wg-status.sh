#!/bin/bash

# Get the WireGuard interface name
INTERFACE_NAME="wg0"

# Get the peer status as a list of lines
PEER_STATUS=$(wg show $INTERFACE_NAME dump | awk '(NR>1)')

# Define color codes
GREEN=$(tput setaf 2)
RED=$(tput setaf 1)
YELLOW=$(tput setaf 3)
NC=$(tput sgr0)

# Parse the peer status into a table
echo "-----------------------------------------------------------------------------------------------------------------------------------"
printf "%-55s | %-22s | %-17s | %-13s | %-9s | %-9s |\n" "${YELLOW}Peer${NC}" "Endpoint" "Allowed IP" "Last seen (s)" "RX (MiB)" "TX (MiB)"
echo "==================================================================================================================================="
while read -r LINE; do
    PEER=$(echo "$LINE" | awk '{print $1}')
    ENDPOINT=$(echo "$LINE" | awk '{print $3}')
    ALLOWED_IP=$(echo "$LINE" | awk '{print $4}')
    LATEST_HANDSHAKE=$(echo "$LINE" | awk '{print $5}')
    RX_DATA_B=$(echo "$LINE" | awk '{print $6}')
    TX_DATA_B=$(echo "$LINE" | awk '{print $7}')
    RX_DATA_M=$(printf "%.2f\n" $((10**2 * RX_DATA_B / 1024 / 1024))e-2)
    TX_DATA_M=$(printf "%.2f\n" $((10**2 * TX_DATA_B / 1024 / 1024))e-2)

    now=$(date +%s)
    duration=$((now - LATEST_HANDSHAKE))

    if [[ $duration -gt "1600000000" ]]; then
        duration="${RED}never${NC}"
    elif [[ $duration -gt "300" ]]; then
        duration="${RED}$duration${NC}"
    elif  [[ $duration -gt "100" ]]; then
        duration="${YELLOW}$duration${NC}"
    else
        duration="${GREEN}$duration${NC}"
    fi

    if [[ $RX_DATA_M == "0.00" ]]; then
        RX_DATA_M="\e[31m$RX_DATA_M     \e[0m"
    fi
    if [[ $TX_DATA_M == "0.00" ]]; then
        TX_DATA_M="\e[31m$TX_DATA_M     \e[0m"
    fi

    if [[ $ENDPOINT = '(none)' ]]; then
        ENDPOINT="\e[31m$ENDPOINT                \e[0m"
    fi

    printf "%-55s | %-22b | %-17s | %-24s | %-9b | %-9b |\n" "${YELLOW}$PEER${NC}" "$ENDPOINT" "$ALLOWED_IP" "${duration}" "${RX_DATA_M}" "${TX_DATA_M}"
done <<< "$PEER_STATUS"
echo "-----------------------------------------------------------------------------------------------------------------------------------"
