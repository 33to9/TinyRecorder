#!/bin/bash
# Generate a self-signed code-signing certificate for TinyRecorder CI builds.
#
# Why: macOS remembers Screen Recording / Microphone permission per signing identity.
# Ad-hoc signatures change on every build, so users must re-grant permission after each
# update. Signing every release with this same certificate keeps the permission.
#
# Run this ONCE on your Mac (Terminal), then add the two printed values as GitHub secrets:
#   Settings -> Secrets and variables -> Actions -> New repository secret
#     MACOS_CERT_P12       (the long base64 text, copied to your clipboard)
#     MACOS_CERT_PASSWORD  (the password printed below)
# Keep the generated folder somewhere safe (or delete it after adding the secrets):
# anyone with cert.p12 + password can sign apps as "TinyRecorder Self-Signed".
set -euo pipefail

NAME="TinyRecorder Self-Signed"
OUT="$HOME/TinyRecorder-signing"
mkdir -p "$OUT"
cd "$OUT"

cat > cert.cnf <<'EOF'
[ req ]
distinguished_name = dn
x509_extensions    = ext
prompt             = no
[ dn ]
CN = TinyRecorder Self-Signed
[ ext ]
basicConstraints = critical, CA:false
keyUsage         = critical, digitalSignature
extendedKeyUsage = critical, codeSigning
EOF

openssl req -x509 -newkey rsa:2048 -nodes -days 3650 \
  -keyout key.pem -out cert.pem -config cert.cnf

PW=$(openssl rand -hex 16)
LEGACY=""
# OpenSSL 3 needs -legacy so macOS `security import` can read the .p12; LibreSSL doesn't have it.
if openssl pkcs12 -help 2>&1 | grep -q -- '-legacy'; then LEGACY="-legacy"; fi
openssl pkcs12 -export $LEGACY -inkey key.pem -in cert.pem -name "$NAME" \
  -out cert.p12 -passout "pass:$PW"
rm -f key.pem cert.cnf

base64 < cert.p12 | tr -d '\n' | pbcopy
echo
echo "✅ Certificate created in: $OUT"
echo "   The base64 of cert.p12 is now in your clipboard -> paste it as secret MACOS_CERT_P12"
echo "   MACOS_CERT_PASSWORD = $PW"
echo
openssl x509 -in cert.pem -noout -subject -fingerprint -sha1
