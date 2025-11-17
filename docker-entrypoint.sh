#!/bin/sh

[ -n "$DEBUG" ] && set -x

if [ "${1#-}" != "$1" ] || echo $@ | grep derper; then
    Name_type=DNS

    if [ $1 != /bin/sh ];then
        set -- derper "$@"
    fi

    if [ "$DERP_CERT_MODE" == manual ] && \
            [ -n "$DERP_DOMAIN" ] && \
            [ -n "$DERP_CERT_DIR" ] && \
            [ ! -f "${DERP_CERT_DIR}/${DERP_DOMAIN}.crt" ];then
            [ ! -d "$DERP_CERT_DIR" ] && mkdir -p "$DERP_CERT_DIR"

    if echo $DERP_DOMAIN | grep -Eq '([0-9]{1,3}\.){3}[0-9]{1,3}';then
        Name_type=IP
    fi

echo "[req]
default_bits  = 2048
distinguished_name = req_distinguished_name
req_extensions = req_ext
x509_extensions = v3_req
prompt = no

[req_distinguished_name]
countryName = XX
stateOrProvinceName = N/A
localityName = N/A
organizationName = Self-signed certificate
commonName = $DERP_DOMAIN: Self-signed certificate

[req_ext]
subjectAltName = @alt_names

[v3_req]
subjectAltName = @alt_names

[alt_names]
${Name_type}.1 = $DERP_DOMAIN
" > openssl.conf
        openssl req -x509 -nodes -days 730 -newkey rsa:2048 -keyout "$DERP_CERT_DIR/$DERP_DOMAIN.key" -out "$DERP_CERT_DIR/$DERP_DOMAIN.crt" -config openssl.conf
    fi
fi

exec "$@"
