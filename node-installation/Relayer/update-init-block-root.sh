#!/bin/bash

# Config file which contain our variables is separated and sourced here
source "${HOME}/conf/relayer.conf"

# Logging function
function log() {

    local level="$1"
    local message="$2"
    local timestamp

    timestamp=$(date +"%Y-%m-%d %H:%M:%S")

    # Check if log file is writable
    if ! touch "$LOG_FILE" &>/dev/null; then
        echo "[$timestamp] [ERROR] Cannot write to log file: $LOG_FILE"
        exit 4
    fi

    echo "[$timestamp] [$level] $message" >>"$LOG_FILE"

}

# Check dependency
function check_tools() {

    if ! command -v wget &>/dev/null; then
        log "ERROR" "wget is not installed. Please install wget to continue."
        exit 2
    fi

    if ! command -v jq &>/dev/null; then
        log "ERROR" "jq is not installed. Please install jq to continue."
        exit 2
    fi

}

# Function to check the key file from eth-relay.toml as we already sure both configs have identical path ( for unknwon reason )
function check_key_file() {

    local key_path

    # Extract signer secret key path from the config file using awk
    key_path=$(awk -F' = ' '/path_to_signer_secret_key/ {gsub(/"/, "", $2); print $2}' "$ETH_RELAY_CONFIG_FILE")

    # Check if path is extracted correctly
    if [ -z "$key_path" ]; then
        log "ERROR" "Failed to extract the path to the signer secret key from $ETH_RELAY_CONFIG_FILE"
        exit 1
    fi

    # Check if key file exists
    if [ ! -f "$key_path" ]; then
        log "ERROR" "The signer secret key file does not exist at the extracted path: $key_path"
        log "INFO" "Create: ggxchain-node key generate -w 24 --scheme sr25519 --output-type json | jq -r .secretPhrase >$key_path"
        exit 1
    fi

    # Check if the file contains exactly 24 words
    # WC prevent any sensative content exposure as it reads directly from the file and not stored in RAM
    local word_count

    word_count=$(wc -w <"$key_path")

    if [ "$word_count" -ne 24 ]; then
        log "ERROR" "The signer secret key file at $key_path does not contain exactly 24 words"
        exit 1
    fi

    # Check file permissions and fix if not set to 600
    permissions=$(stat -c "%a" "$key_path")

    if [ "$permissions" != "600" ]; then

        log "ERROR" "Incorrect permissions for $key_path. Expected 600, got $permissions"
        log "INFO" "Attempting to apply required permissions on $key_path"

        if chmod 0600 "$key_path"; then
            log "INFO" "Permissions on $key_path corrected to 600 successfully."
        else
            log "ERROR" "Failed to set permissions on $key_path to 600."
            exit 1
        fi

    fi

    log "INFO" "The signer secret key file at $key_path exists, contains exactly 24 words, and has the correct permissions."

}

# Helper function to update the key file path. Accept config path $1
function update_config_path() {

    local config_file="$1"
    local current_path

    # Extract current path from the configuration
    current_path=$(awk -F' = ' '/path_to_signer_secret_key/ {gsub(/"/, "", $2); print $2}' "$config_file")

    # Only update if the current path is different from the desired path
    if [ "$current_path" != "$SECRET_KEY_PTH" ]; then
        if ! sed -i "s|path_to_signer_secret_key = \".*\"|path_to_signer_secret_key = \"$SECRET_KEY_PTH\"|" "$config_file"; then
            log "ERROR" "Failed to set the signer secret key path in $config_file"
            exit 1
        fi
        log "INFO" "Updated the signer secret key path in $config_file to $SECRET_KEY_PTH"
    else
        log "INFO" "The signer secret key path in $config_file already matches the expected path"
    fi

}

# Function to check and download configuration files from GitHub if ! -f
function ensure_config_files() {

    # Check and download eth-init.toml if it doesn't exist
    if [ ! -f "$ETH_INIT_CONFIG_FILE" ]; then
        log "INFO" "eth-init.toml not found, downloading..."
        if ! wget "$ETH_INIT_URL" -P "$CONF_DIR" -q --show-progress; then
            log "ERROR" "Failed to download eth-init.toml please download manually"
            exit 1
        fi
    fi

    # Check and download eth-relay.toml if it doesn't exist
    if [ ! -f "$ETH_RELAY_CONFIG_FILE" ]; then
        log "INFO" "eth-relay.toml not found, downloading..."
        if ! wget "$ETH_RELAY_URL" -P "$CONF_DIR" -q --show-progress; then
            log "ERROR" "Failed to download eth-relay.toml please download manually"
            exit 1
        fi
    fi

    # Ensure permissions for both configuration files
    chmod 0600 "$ETH_RELAY_CONFIG_FILE"
    chmod 0600 "$ETH_INIT_CONFIG_FILE"

    # Update path in both config files
    update_config_path "$ETH_INIT_CONFIG_FILE"
    update_config_path "$ETH_RELAY_CONFIG_FILE"

}

# URL validation function
function validate_url() {

    local url="$1"

    if ! [[ $url =~ ^https?://[a-zA-Z0-9.-]+(/[a-zA-Z0-9._/?=&%-]*)?$ ]]; then
        log "ERROR" "Invalid URL provided: $url"
        exit 3
    fi

}

# Function to update the init_block_root in the configuration file
function update_init_block_root() {

    local url="${1}"

    validate_url "$url" # Validate URL before proceeding

    local finalized_root

    # Fetch the root hash using curl and parse it using jq
    if ! finalized_root=$(curl -s "$url" | jq -r '.data.finality.finalized.root' 2>/dev/null); then
        log "ERROR" "Failed to fetch or parse the root hash from $url"
        exit 1
    fi

    # Validate the root hash format
    if ! [[ $finalized_root =~ ^0x[a-fA-F0-9]{64}$ ]]; then
        log "ERROR" "The fetched root hash does not match the expected format (0x followed by 64 hex characters)"
        exit 1
    fi

    # Update the configuration file using sed
    if ! sed -i "s|init_block_root.*=.*|init_block_root=\"$finalized_root\"|" "$ETH_INIT_CONFIG_FILE"; then
        log "ERROR" "Failed to update the configuration file"
        exit 1
    fi

    log "INFO" "Successfully updated init_block_root to $finalized_root in $ETH_INIT_CONFIG_FILE"
}

log "INFO" "Starting boot sequence ==>"

check_tools         # Ensures necessary tools are available
ensure_config_files # Check and ensure configuration files are in place
check_key_file      # check for key file presence ( do not validate )

update_init_block_root "${1:-$DEFAULT_URL}" # Pass the first command line argument to the function or use the default

log "INFO" "Service restarted successfully <=="
