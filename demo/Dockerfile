FROM openresty/openresty:1.21.4.2-0-jammy

RUN opm get cooperlyt/lua-resty-seaweedfs

RUN useradd -d /home/www -s /sbin/nologin www 

COPY nginx/conf/nginx.conf /usr/local/openresty/nginx/conf/nginx.conf
