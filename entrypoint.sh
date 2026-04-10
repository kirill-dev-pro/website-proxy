#!/bin/sh
set -e

# Check if TARGET_HOST is set
if [ -z "$TARGET_HOST" ]; then
    echo "ERROR: TARGET_HOST environment variable is required but not set."
    echo "Usage: docker run -e TARGET_HOST=example.com -p 8080:80 telegram-proxy"
    exit 1
fi

echo "Starting proxy for target: $TARGET_HOST"

# Substitute environment variables in nginx config
envsubst '$TARGET_HOST' < /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf

# Start nginx
exec nginx -g 'daemon off;'
