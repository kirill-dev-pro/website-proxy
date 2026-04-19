#!/bin/sh
set -e

# Check if TARGET_HOST is set
if [ -z "$TARGET_HOST" ]; then
    echo "ERROR: TARGET_HOST environment variable is required but not set."
    echo "Usage: docker run -e TARGET_HOST=example.com -p 8080:80 website-mirror"
    exit 1
fi

echo "Starting proxy for target: $TARGET_HOST"

# Generate IP allow/deny directives
ALLOW_DIRECTIVES=""
DENY_DIRECTIVES=""
DENY_ALL_DIRECTIVES=""

# Process blacklist IPs first (they have priority)
if [ -n "$BLACKLIST_IPS" ]; then
    echo "Configuring blacklist IPs: $BLACKLIST_IPS"
    # Split by comma and create deny directives
    OLDIFS="$IFS"
    IFS=','
    for ip in $BLACKLIST_IPS; do
        # Trim whitespace
        ip=$(echo "$ip" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        if [ -n "$ip" ]; then
            # Validate IP or subnet format (basic check)
            if echo "$ip" | grep -qE '^([0-9]{1,3}\.){3}[0-9]{1,3}(/[0-9]{1,2})?$'; then
                DENY_DIRECTIVES="${DENY_DIRECTIVES}        deny $ip;\\n"
            else
                echo "WARNING: Invalid IP format in BLACKLIST_IPS: $ip"
            fi
        fi
    done
    IFS="$OLDIFS"
fi

# Process whitelist IPs
if [ -n "$WHITELIST_IPS" ]; then
    echo "Configuring whitelist IPs: $WHITELIST_IPS"
    # Split by comma and create allow directives
    OLDIFS="$IFS"
    IFS=','
    for ip in $WHITELIST_IPS; do
        # Trim whitespace
        ip=$(echo "$ip" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        if [ -n "$ip" ]; then
            # Validate IP or subnet format (basic check)
            if echo "$ip" | grep -qE '^([0-9]{1,3}\.){3}[0-9]{1,3}(/[0-9]{1,2})?$'; then
                ALLOW_DIRECTIVES="${ALLOW_DIRECTIVES}        allow $ip;\\n"
            else
                echo "WARNING: Invalid IP format in WHITELIST_IPS: $ip"
            fi
        fi
    done
    IFS="$OLDIFS"
    # If whitelist is configured, deny all others
    DENY_ALL_DIRECTIVES="        deny all;\\n"
fi

# Export for envsubst
export ALLOW_DIRECTIVES
export DENY_DIRECTIVES
export DENY_ALL_DIRECTIVES

# Substitute environment variables in nginx config
envsubst '$TARGET_HOST $ALLOW_DIRECTIVES $DENY_DIRECTIVES $DENY_ALL_DIRECTIVES' < /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf

echo "Nginx configuration generated successfully"

# Start nginx
exec nginx -g 'daemon off;'
