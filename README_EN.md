# website-mirror

A simple nginx proxy for redirecting requests to any API or website. Useful for bypassing blocks or creating mirrors.

## Quick Start

### Docker

```bash
# Build
docker build -t website-mirror .

# Run (TARGET_HOST is required!)
docker run -e TARGET_HOST=openrouter.ai -p 8080:80 website-mirror
```

### Docker Compose

```yaml
version: '3'
services:
  proxy:
    build: .
    ports:
      - "8080:80"
    environment:
      - TARGET_HOST=openrouter.ai
    # Optional: health check (requires curl/wget in image or sidecar container)
    # healthcheck:
    #   test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost:80/health"]
    #   interval: 30s
    #   timeout: 3s
    #   retries: 3
```

Run:
```bash
docker-compose up -d
```

## Environment Variables

| Variable | Description | Required |
|----------|-------------|----------|
| `TARGET_HOST` | Target host for proxying (without https://) | Yes |
| `WHITELIST_IPS` | Allowed IP addresses or subnets (comma-separated). If set, only these IPs have access. | No |
| `BLACKLIST_IPS` | Blocked IP addresses or subnets (comma-separated). Takes priority over whitelist. | No |

## IP Filtering

Supports single addresses and CIDR subnets:

```bash
# Whitelist only — access only for specified IPs
docker run -e TARGET_HOST=api.example.com \
  -e WHITELIST_IPS="192.168.1.100,10.0.0.0/8,172.16.0.0/12" \
  -p 8080:80 website-mirror

# Blacklist only — access for everyone except specified
docker run -e TARGET_HOST=api.example.com \
  -e BLACKLIST_IPS="192.168.1.200,203.0.113.0/24" \
  -p 8080:80 website-mirror

# Both lists — whitelist allows, blacklist blocks (blacklist has priority)
docker run -e TARGET_HOST=api.example.com \
  -e WHITELIST_IPS="192.168.0.0/16" \
  -e BLACKLIST_IPS="192.168.1.200" \
  -p 8080:80 website-mirror
```

**Notes:**
- If `WHITELIST_IPS` is not set — all IPs are allowed by default
- `BLACKLIST_IPS` always has priority: IPs in the blacklist will be blocked even if in the whitelist
- Both variables can be used together for precise access control

## Usage Examples

**OpenRouter:**
```bash
docker run -e TARGET_HOST=openrouter.ai -p 8080:80 website-mirror
# API available at: http://localhost:8080/api/v1/chat/completions
```

**OpenAI:**
```bash
docker run -e TARGET_HOST=api.openai.com -p 8080:80 website-mirror
```

**Any other API:**
```bash
docker run -e TARGET_HOST=api.example.com -p 8080:80 website-mirror
```

## Health Check

```bash
curl http://localhost:8080/health
# Response: OK
```

## Features

- Streaming support (SSE)
- Pass through all headers including Authorization
- HTTPS on port 443
- IP address and subnet filtering

## License

MIT
