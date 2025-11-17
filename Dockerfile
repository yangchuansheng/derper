
FROM golang AS builder

# ARG TARGETPLATFORM
ARG TARGETARCH
# ARG BUILDARCH

COPY build_src/tailscale /opt/
WORKDIR /opt/

SHELL ["/bin/bash", "-c"]

RUN set -ex; \
    go run ./cmd/mkversion > .envrc; \
    cat .envrc /etc/os-release; \
    source .envrc; \
    CGO_ENABLED=0 GOOS=linux GOARCH=${TARGETARCH} go build -o /opt/derper -ldflags="\
      -X tailscale.com/version.longStamp=$VERSION_LONG \
      -X tailscale.com/version.shortStamp=$VERSION_SHORT \
      -X tailscale.com/version.gitCommitStamp=$VERSION_GIT_HASH" -ldflags "-s -w"  cmd/derper/*.go

FROM alpine

WORKDIR /app
COPY --from=builder /opt/derper /usr/bin/
COPY docker-entrypoint.sh /

ENV DERP_DOMAIN your-hostname.com
ENV DERP_CERT_MODE manual
ENV DERP_CERT_DIR /app/certs
ENV DERP_ADDR :443
ENV DERP_STUN true
ENV DERP_STUN_PORT 3478
ENV DERP_HTTP_PORT -1
ENV DERP_VERIFY_CLIENTS true
ENV DERP_VERIFY_CLIENT_URL ""

RUN set -eux; \
    sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories; \
    apk update; \
    apk add --no-cache \
        curl \
        ca-certificates \
        openssl

ENTRYPOINT ["/docker-entrypoint.sh"]

CMD exec derper --hostname=$DERP_DOMAIN \
  --certmode=$DERP_CERT_MODE \
  --certdir=$DERP_CERT_DIR \
  --a=$DERP_ADDR \
  --stun=$DERP_STUN \
  --stun-port=$DERP_STUN_PORT \
  --http-port=$DERP_HTTP_PORT \
  --verify-clients=$DERP_VERIFY_CLIENTS \
  --verify-client-url=$DERP_VERIFY_CLIENT_URL
