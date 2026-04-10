FROM nginx:alpine

# Install gettext for envsubst
RUN apk add --no-cache gettext

# Copy nginx config template (not the actual config, will be generated at runtime)
COPY nginx.conf /etc/nginx/nginx.conf.template

# Copy entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 80

ENTRYPOINT ["/entrypoint.sh"]
