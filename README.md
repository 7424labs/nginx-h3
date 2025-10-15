# Nginx with HTTP/3 Support

A custom-built Nginx Docker image based on Alpine Linux with HTTP/3 (QUIC), Brotli compression, and additional useful modules.

## Features

- **HTTP/3 (QUIC) Support**: Built with OpenSSL 3.5.4 for native QUIC support
- **HTTP/2 Support**: Full HTTP/2 support enabled
- **Brotli Compression**: Google's Brotli compression algorithm for better compression ratios
- **Headers More Module**: Additional header manipulation capabilities
- **Alpine Linux Base**: Minimal image size (~30MB runtime)
- **Multi-architecture**: Supports both amd64 and arm64 platforms

## Version Information

- Nginx: 1.29.2
- OpenSSL: 3.5.4 (with QUIC support)
- Brotli: 1.0.0rc
- Headers More: 0.39
- Base Image: Alpine Linux 3.22

## Quick Start

### Pull from GitHub Container Registry

```bash
docker pull ghcr.io/YOUR_USERNAME/nginx-h3:latest
```

### Run the Container

```bash
docker run -d \
  --name nginx-h3 \
  -p 80:80 \
  -p 443:443 \
  -p 443:443/udp \
  ghcr.io/YOUR_USERNAME/nginx-h3:latest
```

Note: Port 443/udp is required for HTTP/3 (QUIC) support.

## Building Locally

### Build the Image

```bash
docker build -t nginx-h3 .
```

### Build with Custom CPU Cores

```bash
docker build \
  --build-arg BUILD_CORES=4 \
  -t nginx-h3 .
```

## Configuration

### Using Custom nginx.conf

Mount your custom configuration:

```bash
docker run -d \
  --name nginx-h3 \
  -p 80:80 \
  -p 443:443 \
  -p 443:443/udp \
  -v $(pwd)/my-nginx.conf:/etc/nginx/nginx.conf:ro \
  ghcr.io/YOUR_USERNAME/nginx-h3:latest
```

### SSL Certificates

The default configuration expects SSL certificates at:
- `/etc/nginx/ssl/cert.pem`
- `/etc/nginx/ssl/key.pem`

Mount your certificates:

```bash
docker run -d \
  --name nginx-h3 \
  -p 80:80 \
  -p 443:443 \
  -p 443:443/udp \
  -v $(pwd)/certs:/etc/nginx/ssl:ro \
  ghcr.io/YOUR_USERNAME/nginx-h3:latest
```

### Serving Static Content

```bash
docker run -d \
  --name nginx-h3 \
  -p 80:80 \
  -p 443:443 \
  -p 443:443/udp \
  -v $(pwd)/html:/usr/share/nginx/html:ro \
  ghcr.io/YOUR_USERNAME/nginx-h3:latest
```

## Testing HTTP/3

### Using curl

```bash
# Test HTTP/3 support (requires curl with HTTP/3 support)
curl --http3 https://your-domain.com

# Check Alt-Svc header for HTTP/3 advertisement
curl -I https://your-domain.com
```

### Using Chrome/Edge

1. Open `chrome://flags/#enable-quic`
2. Enable QUIC protocol
3. Visit your site
4. Check DevTools -> Network -> Protocol column (should show "h3")

### Using Firefox

1. Open `about:config`
2. Set `network.http.http3.enabled` to `true`
3. Visit your site
4. Check DevTools -> Network -> Protocol column (should show "HTTP/3")

## Endpoints

- `/` - Default server root
- `/health` - Health check endpoint (returns 200 OK)
- `/nginx-status` - Nginx status page (restricted to localhost)

## GitHub Actions

This repository includes a GitHub Actions workflow that automatically:
- Builds the Docker image on push to main/master
- Creates multi-architecture images (amd64, arm64)
- Pushes to GitHub Container Registry
- Tags images based on branch/tag names
- Creates release tags for version tags (v1.0.0, etc.)

### Setting Up

1. Go to your repository settings
2. Navigate to Actions -> General
3. Under "Workflow permissions", select "Read and write permissions"
4. Push to your repository - the workflow will automatically run

### Available Tags

- `latest` - Latest build from main/master branch
- `main` or `master` - Latest build from respective branch
- `v1.0.0` - Specific version tags
- `sha-<commit>` - Specific commit builds

## Docker Compose Example

```yaml
version: '3.8'

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

## Kubernetes Example

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
        - containerPort: 80
          protocol: TCP
        - containerPort: 443
          protocol: TCP
        - containerPort: 443
          protocol: UDP
        volumeMounts:
        - name: config
          mountPath: /etc/nginx/nginx.conf
          subPath: nginx.conf
        - name: certs
          mountPath: /etc/nginx/ssl
      volumes:
      - name: config
        configMap:
          name: nginx-config
      - name: certs
        secret:
          secretName: nginx-tls
---
apiVersion: v1
kind: Service
metadata:
  name: nginx-h3
spec:
  type: LoadBalancer
  ports:
  - name: http
    port: 80
    targetPort: 80
    protocol: TCP
  - name: https
    port: 443
    targetPort: 443
    protocol: TCP
  - name: quic
    port: 443
    targetPort: 443
    protocol: UDP
  selector:
    app: nginx-h3
```

## Troubleshooting

### Check Nginx Version and Modules

```bash
docker run --rm ghcr.io/YOUR_USERNAME/nginx-h3:latest nginx -V
```

### Check if HTTP/3 is Compiled

```bash
docker run --rm ghcr.io/YOUR_USERNAME/nginx-h3:latest nginx -V 2>&1 | grep http_v3
```

### View Logs

```bash
docker logs nginx-h3
```

### Interactive Shell

```bash
docker exec -it nginx-h3 sh
```

## Performance Tuning

### Adjust Worker Processes

The default configuration uses `worker_processes auto`, which automatically detects the number of CPU cores. You can override this in your custom nginx.conf.

### Build with More CPU Cores

During the build process, you can use more CPU cores:

```bash
docker build --build-arg BUILD_CORES=8 -t nginx-h3 .
```

## Security Considerations

1. **SSL Certificates**: Always use valid SSL certificates from a trusted CA
2. **Update Regularly**: Keep the image updated with the latest security patches
3. **Restrict Access**: Use firewall rules to restrict access to sensitive endpoints
4. **Configuration Review**: Review and customize nginx.conf for your security requirements

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is open source and available under the MIT License.

## Acknowledgments

- [Nginx](https://nginx.org/)
- [OpenSSL](https://www.openssl.org/)
- [Google Brotli](https://github.com/google/brotli)
- [Headers More Module](https://github.com/openresty/headers-more-nginx-module)
