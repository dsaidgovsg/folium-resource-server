FROM caddy/caddy:2.0.0-beta.20-alpine

WORKDIR /app
COPY ./static /app/static

# --browse is added for health check purposes
CMD ["caddy", "file-server", "--browse", "--listen", ":8080", "--root", "/app/static"]
