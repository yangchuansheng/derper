# Custom DERP Build

A slim Docker build of Tailscale's `derper` service with one tweaks aimed at self‑hosted use:
- TLS certificate verification is disabled, making it easier to run with self-signed certificates.

Because certificate checks are turned off, use this build only in controlled environments where you understand the security trade-offs.
