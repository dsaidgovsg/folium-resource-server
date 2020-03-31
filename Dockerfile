FROM caddy/caddy:2.0.0-beta.20-alpine

WORKDIR /app
COPY ./static /app/static

CMD ["caddy", "file-server", "--listen", ":8080", "--root", "/app/static"]
