# Custom Nginx with HTTP/3 (QUIC) and Brotli support
# Using Alpine's system OpenSSL for faster builds
# Based on Alpine Linux for minimal size

FROM alpine:3.22 AS builder

# Nginx and module versions
ENV NGINX_VERSION=1.29.2
ENV BROTLI_VERSION=1.0.0rc
ENV HEADERS_MORE_VERSION=0.39

# Install build dependencies including system OpenSSL development libraries
RUN apk add --no-cache \
    gcc \
    g++ \
    make \
    cmake \
    perl \
    perl-dev \
    pcre-dev \
    zlib-dev \
    openssl-dev \
    linux-headers \
    curl \
    git

# Create build directory
WORKDIR /build

# Clone Brotli module
RUN git clone --depth=1 --branch=v${BROTLI_VERSION} https://github.com/google/ngx_brotli.git && \
    cd ngx_brotli && \
    git submodule update --init

# Clone headers-more module
RUN git clone --depth=1 --branch=v${HEADERS_MORE_VERSION} https://github.com/openresty/headers-more-nginx-module.git

# Download, extract and build Nginx with HTTP/3 and Brotli
# Using system OpenSSL (Alpine 3.22 ships with OpenSSL 3.3.x which has QUIC support)
RUN curl -L https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz | tar xz && \
    cd nginx-${NGINX_VERSION} && \
    ./configure \
    --prefix=/etc/nginx \
    --sbin-path=/usr/sbin/nginx \
    --modules-path=/usr/lib/nginx/modules \
    --conf-path=/etc/nginx/nginx.conf \
    --error-log-path=/var/log/nginx/error.log \
    --http-log-path=/var/log/nginx/access.log \
    --pid-path=/var/run/nginx.pid \
    --lock-path=/var/run/nginx.lock \
    --http-client-body-temp-path=/var/cache/nginx/client_temp \
    --http-proxy-temp-path=/var/cache/nginx/proxy_temp \
    --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
    --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
    --http-scgi-temp-path=/var/cache/nginx/scgi_temp \
    --user=nginx \
    --group=nginx \
    --with-compat \
    --with-file-aio \
    --with-threads \
    --with-http_addition_module \
    --with-http_auth_request_module \
    --with-http_dav_module \
    --with-http_flv_module \
    --with-http_gunzip_module \
    --with-http_gzip_static_module \
    --with-http_mp4_module \
    --with-http_random_index_module \
    --with-http_realip_module \
    --with-http_secure_link_module \
    --with-http_slice_module \
    --with-http_ssl_module \
    --with-http_stub_status_module \
    --with-http_sub_module \
    --with-http_v2_module \
    --with-http_v3_module \
    --with-mail \
    --with-mail_ssl_module \
    --with-stream \
    --with-stream_realip_module \
    --with-stream_ssl_module \
    --with-stream_ssl_preread_module \
    --with-cc-opt="-O3 -fstack-protector-strong" \
    --add-module=/build/ngx_brotli \
    --add-module=/build/headers-more-nginx-module && \
    make -j$(nproc) && \
    make install

# Final stage - minimal runtime image
FROM alpine:3.22

# Install runtime dependencies including OpenSSL libraries
RUN apk add --no-cache \
    pcre \
    zlib \
    openssl \
    ca-certificates \
    tzdata

# Copy nginx from builder
COPY --from=builder /usr/sbin/nginx /usr/sbin/nginx
COPY --from=builder /etc/nginx /etc/nginx
# Note: Modules are statically compiled, no separate modules directory needed

# Copy custom main nginx.conf
COPY nginx.conf /etc/nginx/nginx.conf

# Create nginx user and required directories
RUN addgroup -g 101 -S nginx && \
    adduser -S -D -H -u 101 -h /var/cache/nginx -s /sbin/nologin -G nginx -g nginx nginx && \
    mkdir -p /var/cache/nginx/client_temp \
             /var/cache/nginx/proxy_temp \
             /var/cache/nginx/fastcgi_temp \
             /var/cache/nginx/uwsgi_temp \
             /var/cache/nginx/scgi_temp \
             /var/log/nginx \
             /var/run && \
    chown -R nginx:nginx /var/cache/nginx /var/log/nginx /var/run

# Forward request and error logs to docker log collector
RUN ln -sf /dev/stdout /var/log/nginx/access.log && \
    ln -sf /dev/stderr /var/log/nginx/error.log

# Expose HTTP, HTTPS and QUIC (UDP)
EXPOSE 80 443 443/udp

STOPSIGNAL SIGTERM

CMD ["nginx", "-g", "daemon off;"]
