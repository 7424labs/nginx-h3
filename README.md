# Nginx with HTTP/3 Support

Nginx Docker image with HTTP/3 (QUIC), Brotli compression, and additional modules.

**Stack:** Nginx 1.29.2 • OpenSSL 3.5.4 • Brotli 1.0.0rc • Alpine 3.22 • Multi-arch (amd64/arm64)

## Usage

```bash
# Pull and run
docker pull ghcr.io/YOUR_USERNAME/nginx-h3:latest
docker run -d --name nginx-h3 -p 80:80 -p 443:443 -p 443:443/udp ghcr.io/YOUR_USERNAME/nginx-h3:latest

# Build locally
docker build -t nginx-h3 .

# Build with custom CPU cores
docker build --build-arg BUILD_CORES=4 -t nginx-h3 .
```

> **Note:** Port 443/udp is required for HTTP/3 (QUIC) support.

## Configuration

Mount volumes for custom configuration:

```bash
# Custom nginx.conf
-v $(pwd)/nginx.conf:/etc/nginx/nginx.conf:ro

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

**Available tags:** `latest`, `main`, `master`, `v1.0.0`, `sha-<commit>`

## Deployment Examples

<details>
<summary><b>Docker Compose</b></summary>

```yaml
services:
  nginx:
    image: ghcr.io/YOUR_USERNAME/nginx-h3:latest
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
        image: ghcr.io/YOUR_USERNAME/nginx-h3:latest
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
docker run --rm ghcr.io/YOUR_USERNAME/nginx-h3:latest nginx -V

# Verify HTTP/3 support
docker run --rm ghcr.io/YOUR_USERNAME/nginx-h3:latest nginx -V 2>&1 | grep http_v3

# View logs
docker logs nginx-h3

# Interactive shell
docker exec -it nginx-h3 sh
```

## License

MIT License
