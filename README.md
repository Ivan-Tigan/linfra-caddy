# linfra-caddy

Caddy reverse proxy setup for linfra infrastructure deployments.

## Features

- **Automatic HTTPS** with Let's Encrypt
- **HTTP/3 support** (QUIC)
- **Auto-reload** - Watches `Caddyfile` for changes and automatically reloads Caddy
- **Health checks** - Monitors Caddy health
- **Host networking** - Direct access to localhost services

## Usage

### With linfra

Use as a file-based project in your `infrastructure.xml`:

```xml
<project folder="~/caddy">
    <file path="Caddyfile">
example.com {
    reverse_proxy localhost:3000
}

api.example.com {
    reverse_proxy localhost:8080
}
    </file>
</project>
```

linfra will:
1. Create the `~/caddy` folder
2. Write the `Caddyfile`
3. Pull this repo's `docker-compose.yml` (or you can include it as another `<file>`)
4. Run `docker compose up -d`

### Manual Usage

```bash
# Create Caddyfile
cat > Caddyfile << 'EOF'
example.com {
    reverse_proxy localhost:3000
}
EOF

# Start Caddy
docker compose up -d
```

## How Auto-Reload Works

The `caddy-reloader` service watches the `Caddyfile` using `inotify`. When changes are detected:

1. Detects file modification
2. Executes `caddy reload` inside the Caddy container
3. Caddy gracefully reloads with zero downtime

This means `linfra up` can update the `Caddyfile` and Caddy will automatically pick up changes **without needing a container restart**.

## Configuration

### Caddyfile Format

Standard Caddy configuration format. See [Caddy docs](https://caddyserver.com/docs/caddyfile).

Example:
```
# Simple reverse proxy
example.com {
    reverse_proxy localhost:3000
}

# With basic auth
admin.example.com {
    basicauth {
        admin $2a$14$...hashed_password...
    }
    reverse_proxy localhost:8080
}

# File server
static.example.com {
    root * /var/www/html
    file_server
}
```

### Volumes

- `caddy_data` - SSL certificates and Caddy data (persistent)
- `caddy_config` - Caddy configuration cache (persistent)
- `./Caddyfile` - Your reverse proxy configuration (bind mount)

## Troubleshooting

### Check Caddy logs
```bash
docker compose logs caddy -f
```

### Check reloader logs
```bash
docker compose logs caddy-reloader -f
```

### Manual reload
```bash
docker compose exec caddy caddy reload --config /etc/caddy/Caddyfile
```

### Validate Caddyfile
```bash
docker compose exec caddy caddy validate --config /etc/caddy/Caddyfile
```

## License

MIT
