# Custom DERP Build

A slim Docker build of Tailscale's `derper` service with one tweaks aimed at self‑hosted use:
- TLS certificate verification is disabled, making it easier to run with self-signed certificates.

Because certificate checks are turned off, use this build only in controlled environments where you understand the security trade-offs.

## Get Started

> 1-click deployment with Sealos:
>
> [![](https://sealos.io/Deploy-on-Sealos.svg)](https://sealos.io/products/app-store/derper)

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

## Troubleshooting

### Custom DERP Configuration (for Headscale/Tailscale)

When using a self-hosted DERP server, you need to inform clients about it.

-   **For Headscale:** This is typically done by providing a `derp.json` file that maps your DERP nodes.
-   **For Tailscale:** You can add your DERP server in the `derpMap` section of your [Access Controls (ACLs)](https://tailscale.com/kb/1192/acl-derp-servers).

If your DERP server uses a self-signed certificate, you may need to use settings like `"InsecureForTests": true` in a Headscale `derp.json` to allow clients to connect without verifying the TLS certificate.

**Example `derp.json` for Headscale:**
```json
{
  "Regions": {
    "901": {
      "RegionID": 901,
      "RegionCode": "derp-cd",
      "RegionName": "derp-chengdu",
      "Nodes": [
        {
          "Name": "901a",
          "RegionID": 901,
          "DERPPort": xxxx,
          "STUNPort": xxxx,
					"STUNOnly": false,
          "HostName": "xxxx",
          "InsecureForTests": true
        }
      ]
    }
  }
}
```

### Common Errors

Here are a few common health check errors you might encounter when using a custom DERP server.

#### `not connected to home DERP region...`

**Symptom:**
```shell
# Health check:
#     - not connected to home DERP region 902
```

**Cause:** This error often occurs when a client is configured to use a custom DERP server with a self-signed certificate but fails to connect because it doesn't trust the certificate.

**Solution:** For Headscale, set `"InsecureForTests": true` in your `derp.json` configuration for the node. This tells the client to bypass TLS certificate verification. For the official Tailscale service, this is not a recommended configuration.

#### `TLS connection error... certificate is self-signed`

**Symptom:**
```shell
# Health check:
#     - TLS connection error for "": certificate is self-signed
```

**Cause:** This is a warning indicating that the client connected to the DERP server but detected that the TLS certificate is self-signed and not trusted by a public Certificate Authority (CA).

**Solution:** In most self-hosted environments, this warning is expected and can be safely ignored. It does not typically affect the functionality of the DERP server.

#### `Tailscale could not connect to the 'test' relay server...`

**Symptom:**
```shell
# Health check:
#     - Tailscale could not connect to the 'test' relay server. Your Internet connection might be down, or the server might be temporarily unavailable.
```

**Cause:** This generic error message usually points to a network connectivity issue between the client and the DERP server. The client cannot reach the DERP port at all.

**Solution:**
- **Check Firewall Rules:** Ensure that firewalls on your server, cloud provider (e.g., AWS Security Groups), or local network are not blocking the DERP port (e.g., `443/tcp` and `3478/udp`).
- **Verify Port Forwarding:** If your DERP server is behind a NAT, confirm that you have correctly configured port forwarding on your router.
- **Confirm the DERP Service is Running:** SSH into your server and check that the `derper` Docker container is running and has not crashed.
