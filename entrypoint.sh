#!/bin/sh
set -e

# Check if TARGET_HOST is set
if [ -z "$TARGET_HOST" ]; then
    echo "ERROR: TARGET_HOST environment variable is required but not set."
    echo "Usage: docker run -e TARGET_HOST=example.com -p 8080:80 website-mirror"
    exit 1
fi

echo "Starting proxy for target: $TARGET_HOST"

# Generate IP allow/deny directives to a temporary file
ALLOW_DENY_FILE="/tmp/nginx_allow_deny.conf"
echo "" > "$ALLOW_DENY_FILE"

# Process blacklist IPs first (they have priority)
if [ -n "$BLACKLIST_IPS" ]; then
    echo "Configuring blacklist IPs: $BLACKLIST_IPS"
    OLDIFS="$IFS"
    IFS=','
    for ip in $BLACKLIST_IPS; do
        # Trim whitespace
        ip=$(echo "$ip" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        if [ -n "$ip" ]; then
            # Validate IP or subnet format (basic check)
            if echo "$ip" | grep -qE '^([0-9]{1,3}\.){3}[0-9]{1,3}(/[0-9]{1,2})?$'; then
                echo "        deny $ip;" >> "$ALLOW_DENY_FILE"
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
    OLDIFS="$IFS"
    IFS=','
    for ip in $WHITELIST_IPS; do
        # Trim whitespace
        ip=$(echo "$ip" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        if [ -n "$ip" ]; then
            # Validate IP or subnet format (basic check)
            if echo "$ip" | grep -qE '^([0-9]{1,3}\.){3}[0-9]{1,3}(/[0-9]{1,2})?$'; then
                echo "        allow $ip;" >> "$ALLOW_DENY_FILE"
            else
                echo "WARNING: Invalid IP format in WHITELIST_IPS: $ip"
            fi
        fi
    done
    IFS="$OLDIFS"
    # If whitelist is configured, deny all others
    echo "        deny all;" >> "$ALLOW_DENY_FILE"
fi

# Substitute environment variables in nginx config
envsubst '$TARGET_HOST' < /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf

# Insert the allow/deny directives into the nginx config using sed
if [ -s "$ALLOW_DENY_FILE" ]; then
    # Create a marker to replace in nginx.conf
    sed -i '/# IP_FILTERING_PLACEHOLDER/r '"$ALLOW_DENY_FILE"'' /etc/nginx/nginx.conf
fi

# Remove the placeholder line if it exists
sed -i '/# IP_FILTERING_PLACEHOLDER/d' /etc/nginx/nginx.conf

echo "Nginx configuration generated successfully"

# Clean up
rm -f "$ALLOW_DENY_FILE"

# Start nginx
exec nginx -g 'daemon off;'
