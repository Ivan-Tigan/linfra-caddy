# Stage 1: Base Caddy with Curl installed (Less Frequent Change)
# This layer will only be busted if you change the base image or the apk line.
FROM caddy:2-alpine AS builder

# Install curl once, which will be cached unless the image or the apk packages change.
# This should be a highly cached step.
RUN apk add --no-cache curl

# --- End of highly cached layers ---

# Stage 2: Application Layer (More Frequent Change)
# Copy the startup script first, as it changes less frequently than the Caddyfile.
# The cache bust starts here if caddy-start.sh changes.
COPY caddy-start.sh /usr/local/bin/

# Set file permissions
RUN chmod +x /usr/local/bin/caddy-start.sh

# Copy the Caddyfile LAST. This is the file most likely to change.
# If Caddyfile changes, ONLY this layer and subsequent layers are busted (just CMD/ENTRYPOINT).
# If Caddyfile is unchanged, the entire layer below is cached.
COPY Caddyfile /etc/caddy/Caddyfile

# --- End of frequently changing layers ---

# Set the custom script as the new entrypoint
ENTRYPOINT ["/usr/local/bin/caddy-start.sh"]

# Keep the original Caddy command
CMD ["caddy", "run", "--config", "/etc/caddy/Caddyfile", "--adapter", "caddyfile"]