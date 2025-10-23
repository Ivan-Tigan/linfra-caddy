# Use the official Caddy image as the base
FROM caddy:2-alpine

# Install curl for API interaction
RUN apk add --no-cache curl

# Copy the Caddyfile and the startup script
COPY Caddyfile /etc/caddy/Caddyfile
COPY caddy-start.sh /usr/local/bin/

# Make the script executable
RUN chmod +x /usr/local/bin/caddy-start.sh

# Set the custom script as the new entrypoint
ENTRYPOINT ["/usr/local/bin/caddy-start.sh"]

# Keep the original Caddy command
CMD ["caddy", "run", "--config", "/etc/caddy/Caddyfile", "--adapter", "caddyfile"]