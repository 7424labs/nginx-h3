# Nginx with HTTP/3 Support

Nginx Docker image with HTTP/3 (QUIC), Brotli compression, and additional modules.

**Stack:** Nginx 1.29.2 • OpenSSL 3.5.4 • Brotli 1.0.0rc • Alpine 3.22 • Multi-arch (amd64/arm64)

## Usage

> **Important:** This image does not include a default server configuration. You must provide your own `example.com.conf` file. See [example/example.com.conf](example/example.com.conf) for a sample configuration.

```bash
# Pull image
docker pull ghcr.io/7424labs/nginx-h3:latest

# Run with your configuration
docker run -d --name nginx-h3 \
  -p 80:80 -p 443:443 -p 443:443/udp \
  -v $(pwd)/example.com.conf:/etc/nginx/conf.d/example.com.conf:ro \
  -v $(pwd)/certs:/etc/nginx/ssl:ro \
  ghcr.io/7424labs/nginx-h3:latest

# Build locally
docker build -t nginx-h3 .
```

### Firewall Configuration

Ensure the following ports are open:

- **80/TCP** - HTTP traffic
- **443/TCP** - HTTPS traffic (HTTP/2)
- **443/UDP** - HTTP/3 (QUIC) traffic

```bash
# Example: UFW firewall rules
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 443/udp

# Example: iptables rules
iptables -A INPUT -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -p tcp --dport 443 -j ACCEPT
iptables -A INPUT -p udp --dport 443 -j ACCEPT
```

## Configuration

Mount volumes for custom configuration:

```bash
# Server configuration
-v $(pwd)/example.com.conf:/etc/nginx/conf.d/example.com.conf:ro

# SSL certificates (expected at /etc/nginx/ssl/cert.pem and /etc/nginx/ssl/key.pem)
-v $(pwd)/certs:/etc/nginx/ssl:ro

# Static content
-v $(pwd)/html:/usr/share/nginx/html:ro
```

## Testing HTTP/3

```bash
# Test with curl (requires HTTP/3 support)
curl --http3 https://your-domain.com

# Check Alt-Svc header
curl -I https://your-domain.com
```

**Browser testing:** Enable HTTP/3 in browser settings, then check DevTools → Network → Protocol column for "h3" or "HTTP/3".

**Endpoints:**
- `/` - Server root
- `/health` - Health check (200 OK)
- `/nginx-status` - Status page (localhost only)

## GitHub Actions

Automatic builds on push to main/master with multi-arch support (amd64/arm64). Enable "Read and write permissions" in repository Actions settings.

**Available tags:** `latest`, `1.29.2`, `1.29`, `1`

## Deployment Examples

<details>
<summary><b>Docker Compose</b></summary>

```yaml
services:
  nginx:
    image: ghcr.io/7424labs/nginx-h3:latest
    ports:
      - "80:80"
      - "443:443"
      - "443:443/udp"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
      - ./certs:/etc/nginx/ssl:ro
      - ./html:/usr/share/nginx/html:ro
    restart: unless-stopped
```
</details>

<details>
<summary><b>Kubernetes</b></summary>

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-h3
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx-h3
  template:
    metadata:
      labels:
        app: nginx-h3
    spec:
      containers:
      - name: nginx
        image: ghcr.io/7424labs/nginx-h3:latest
        ports:
        - {containerPort: 80, protocol: TCP}
        - {containerPort: 443, protocol: TCP}
        - {containerPort: 443, protocol: UDP}
        volumeMounts:
        - {name: config, mountPath: /etc/nginx/nginx.conf, subPath: nginx.conf}
        - {name: certs, mountPath: /etc/nginx/ssl}
      volumes:
      - {name: config, configMap: {name: nginx-config}}
      - {name: certs, secret: {secretName: nginx-tls}}
---
apiVersion: v1
kind: Service
metadata:
  name: nginx-h3
spec:
  type: LoadBalancer
  ports:
  - {name: http, port: 80, protocol: TCP}
  - {name: https, port: 443, protocol: TCP}
  - {name: quic, port: 443, protocol: UDP}
  selector:
    app: nginx-h3
```
</details>

## Troubleshooting

```bash
# Check version and modules
docker run --rm ghcr.io/7424labs/nginx-h3:latest nginx -V

# Verify HTTP/3 support
docker run --rm ghcr.io/7424labs/nginx-h3:latest nginx -V 2>&1 | grep http_v3

# View logs
docker logs nginx-h3

# Interactive shell
docker exec -it nginx-h3 sh
```

## License

MIT License
