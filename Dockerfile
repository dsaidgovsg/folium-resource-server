FROM openresty/openresty:1.15.8.3-alpine

# Overwrite the default openresty nginx.conf
COPY nginx.conf /usr/local/openresty/nginx/conf/nginx.conf
COPY ./static /usr/share/nginx/html/static
