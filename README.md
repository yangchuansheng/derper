# Custom DERP Build

A slim Docker build of Tailscale's `derper` service with one tweaks aimed at self‑hosted use:
- TLS certificate verification is disabled, making it easier to run with self-signed certificates.

Because certificate checks are turned off, use this build only in controlled environments where you understand the security trade-offs.

## Run

The container ships with sensible defaults and auto-generates a 2‑year self-signed cert when `DERP_CERT_MODE=manual` (default) and no cert exists.

### Quick start (self-signed)

```bash
docker run -d \
  --name derper \
  -p 12345:12345/tcp -p 3478:3478/udp \
  -e DERP_DOMAIN=derp.example.com \
  -e DERP_ADDR=':12345' \
  -e DERP_STUN_PORT='3478' \
  -e DERP_HTTP_PORT='-1' \
  -e DERP_VERIFY_CLIENTS="false" \
  -e DERP_CERT_DIR=/cert \
  -v $(pwd)/cert:/cert \
  ghcr.io/yangchuansheng/derper:v1.90.6
```

- Ports: `443/tcp` for DERP, `3478/udp` for STUN (disable via `DERP_STUN=false`).
- Certificates: the entrypoint writes `certs/{DERP_DOMAIN}.crt` and `.key` if missing. Replace them with your own certs to trust a known CA.

### docker compose

```yaml
services:
  derper:
    image: ghcr.io/yangchuansheng/derper:v1.90.6
    container_name: derper
    ports:
      - "12345:12345/tcp"
      - "3478:3478/udp"
    environment:
      DERP_DOMAIN: derp.example.com
      DERP_CERT_MODE: manual
      DERP_CERT_DIR: /cert
      DERP_ADDR: ':12345'
      DERP_STUN_PORT: '3478'
      DERP_HTTP_PORT: '-1'
      DERP_VERIFY_CLIENTS: "false"
    volumes:
      - ./cert:/cert
```

## Configuration

Environment variables worth adjusting (image defaults in parentheses):

- `DERP_DOMAIN` (no default): hostname DERP advertises; must match what clients dial.
- `DERP_CERT_DIR` (`/app/certs`): path for `*.crt`/`*.key`; example uses `/cert` with a bind mount.
- `DERP_CERT_MODE` (`manual`): reads from `DERP_CERT_DIR`; auto-generates self-signed certs when missing.
- `DERP_ADDR` (`:443`): DERP listen address; example binds `:12345` so publish `-p 12345:12345/tcp`.
- `DERP_STUN` (`true`) / `DERP_STUN_PORT` (`3478`): enable/port for STUN; disable by setting `DERP_STUN=false`.
- `DERP_HTTP_PORT` (`-1`): keeps the HTTP debug port off; set to a port to enable.
- `DERP_VERIFY_CLIENTS` (`true` or `false`): keep TLS client verification on for DERP peers.
- `DERP_VERIFY_CLIENT_URL` (empty): optional URL to fetch verification keys.

## Notes

- TLS certificate verification inside `derper` is disabled in this build to simplify self-signed setups—use only in trusted networks.
- Keep `DERP_DOMAIN` consistent with the hostname your Tailscale nodes are configured to use.
