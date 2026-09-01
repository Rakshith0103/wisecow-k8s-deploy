#!/usr/bin/env bash
# Generates a self-signed TLS certificate for wisecow.local and creates
# the corresponding Kubernetes TLS secret used by k8s/ingress.yaml.
#
# Run this once against your Kind/Minikube cluster before applying ingress.yaml.

set -e

CERT_DIR="./tls"
mkdir -p "$CERT_DIR"

openssl req -x509 -nodes -days 365 \
  -newkey rsa:2048 \
  -keyout "$CERT_DIR/tls.key" \
  -out "$CERT_DIR/tls.crt" \
  -subj "/CN=wisecow.local/O=wisecow"

kubectl create secret tls wisecow-tls \
  --cert="$CERT_DIR/tls.crt" \
  --key="$CERT_DIR/tls.key" \
  --dry-run=client -o yaml | kubectl apply -f -

echo "TLS secret 'wisecow-tls' created/updated."
echo "Add '127.0.0.1 wisecow.local' to /etc/hosts (or your Minikube/Kind IP) to test locally."
