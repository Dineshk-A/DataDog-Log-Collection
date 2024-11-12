#!/bin/bash

LOG_PATHS=(
    "/var/log/amazon/ssm/amazon.log"  
    "/var/log/application1/*.log"
    "/var/log/application2/*.log"
    "/opt/myapp/logs/*.log"
    "/var/log/amazon/ssm/amazon.log"
    # Add as many paths as you need!
)

DD_AGENT_USER="dd-agent"
GROUP="logaccess"  # Group for restricted access

# Create the logaccess group if it doesn’t exist
if ! getent group "$GROUP" > /dev/null 2>&1; then
    sudo groupadd "$GROUP"
    echo "Group $GROUP created."
fi

# Add dd-agent to the logaccess group
sudo usermod -aG "$GROUP" "$DD_AGENT_USER"
echo "Added $DD_AGENT_USER to $GROUP group."

# Set ownership for Datadog config files
sudo chown dd-agent:dd-agent /etc/datadog-agent/conf.d/custom_log_collection.d/
sudo chown dd-agent:dd-agent /etc/datadog-agent/datadog.yaml
echo "Datadog configuration files ownership set to dd-agent."

# Ensure permissions for each log path
for log_path in "${LOG_PATHS[@]}"; do
    if sudo [ -e "$log_path" ]; then
        # Apply ownership and permissions to parent directories up to the log file level
        second_level_path="$(dirname "$(dirname "$log_path")")"
        third_level_path="$(dirname "$log_path")"

        sudo chown -R :$GROUP "$second_level_path" "$third_level_path" "$log_path"
        sudo chmod -R 750 "$second_level_path" "$third_level_path" "$log_path"

        echo "Permissions set for $log_path and parent directories."
    else
        echo "Log path $log_path does not exist or is inaccessible."
    fi
done
