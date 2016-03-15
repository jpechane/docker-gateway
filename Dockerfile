FROM alpine:3.3
MAINTAINER 3scale <operations@3scale.net>

ENV OPENRESTY_VERSION=1.9.7.3 NGINX_PREFIX=/opt/openresty/nginx

EXPOSE 80

# Based on https://github.com/ficusio/openresty

RUN export OPENRESTY_PREFIX=/opt/openresty VAR_PREFIX=/var/nginx \
 && apk update \
 && apk add --virtual build-deps \
    make gcc musl-dev \
    pcre-dev openssl-dev zlib-dev ncurses-dev readline-dev \
    perl \
 && apk add curl unzip \
 && mkdir -p /root/ngx_openresty \
 && cd /root/ngx_openresty \
 && curl -sSL http://openresty.org/download/openresty-${OPENRESTY_VERSION}.tar.gz | tar -xvz \
 && cd openresty-* \
 && readonly NPROC=$(grep -c ^processor /proc/cpuinfo 2>/dev/null || 1) \
 && ./configure \
    --prefix=$OPENRESTY_PREFIX \
    --http-client-body-temp-path=$VAR_PREFIX/client_body_temp \
    --http-proxy-temp-path=$VAR_PREFIX/proxy_temp \
    --http-log-path=$VAR_PREFIX/access.log \
    --error-log-path=$VAR_PREFIX/error.log \
    --pid-path=$VAR_PREFIX/nginx.pid \
    --lock-path=$VAR_PREFIX/nginx.lock \
    --with-luajit \
    --with-pcre-jit \
    --with-ipv6 \
    --with-http_ssl_module \
    --without-http_ssi_module \
    --without-http_userid_module \
    --without-http_uwsgi_module \
    --without-http_scgi_module \
    -j${NPROC} \
 && make -j${NPROC} \
 && make install \
 && ln -sf $NGINX_PREFIX/sbin/nginx /usr/local/bin/nginx \
 && ln -sf $NGINX_PREFIX/sbin/nginx /usr/local/bin/openresty \
 && ln -sf $OPENRESTY_PREFIX/bin/resty /usr/local/bin/resty \
 && ln -sf $OPENRESTY_PREFIX/luajit/bin/luajit-* $OPENRESTY_PREFIX/luajit/bin/lua \
 && ln -sf $OPENRESTY_PREFIX/luajit/bin/luajit-* /usr/local/bin/lua \
 && apk del build-deps \
 && apk add \
    libpcrecpp libpcre16 libpcre32 openssl libssl1.0 pcre libgcc libstdc++ \
 && rm -rf /var/cache/apk/* \
 && rm -rf /root/ngx_openresty

COPY entrypoint.sh /

WORKDIR $NGINX_PREFIX/

ENTRYPOINT ["/entrypoint.sh"]