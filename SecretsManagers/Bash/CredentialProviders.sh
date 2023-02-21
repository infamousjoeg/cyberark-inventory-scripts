#!/bin/bash
set -eux -o pipefail

# Define CyberArk REST API Function
# ---------------------------------
# This function is used to invoke the CyberArk REST API
# It returns the HTTP status code and the response body
# The response body is returned as a JSON object
function invoke_cyberark_rest_api {
    access_token="$1"
    method="$2"
    uri="$3"
    body="$4"

    request=("-s" "-H" "Content-Type: application/json" "-H" "Authorization: $access_token" "-X" "$method" "$uri")

    if [ "$method" = "POST" ] || [ "$method" = "PUT" ] || [ "$method" = "PATCH" ]; then
        request+=("-d" "$body")
    fi

    response=$(curl "${request[@]}" 2>/dev/null)
    echo "$response"
}

# User-Defined Variables
# ----------------------
# The base URI for the CyberArk REST API (e.g. https://cyberark.example.com)
read -rp "Enter the base URI for the CyberArk REST API (e.g. https://cyberark.example.com): " base_uri
if [[ -z "$base_uri" ]]; then
    echo "Error: No base URI specified"
    exit 1
fi

# The authentication type to use (cyberark or ldap)
read -rp "Enter the authentication type ([cyberark] or ldap): " auth_type
auth_type=${auth_type:-cyberark}
auth_type=$(echo "$auth_type" | tr '[:upper:]' '[:lower:]')

# Get CyberArk Administrator Credentials
read -rp "Enter your CyberArk Administrator username: " cyberark_username
read -s -rp "Enter your CyberArk Administrator password: " cyberark_password
body="{\"username\":\"$cyberark_username\",\"password\":\"$cyberark_password\",\"concurrentSession\":true}"
unset cyberark_password

# Define CyberArk REST API Logon Parameters
logon_post_params=("-s" "-H" "Content-Type: application/json" "-X" "POST" "$base_uri/passwordvault/api/auth/$auth_type/logon")

logon_post_params+=("-d" "$body")

# Logon to CyberArk REST API
response=$(curl "${logon_post_params[@]}" 2>/dev/null)
access_token=${response//\"/}

# Get System Health Details for AIM Component
uri="$base_uri/passwordvault/api/componentsmonitoringdetails/aim"
response=$(invoke_cyberark_rest_api "$access_token" "GET" "$uri" "")

# Export the response to a CSV file
if [ -f "CredentialProvidersInventory.csv" ]; then
    rm "CredentialProvidersInventory.csv"
fi
echo "$response" | jq '.ComponentsDetails' | jq -r '([.[] | keys_unsorted as $k | $k, [.[] | tostring]]) | @csv' > CredentialProvidersInventory.csv
