#!/bin/bash
# Signs Wallet/Membership.pass into GymTool/Resources/Membership.pkpass, which
# the app bundles and offers on the Membership screen as Add to Apple Wallet.
# Wallet only accepts passes signed with a Pass Type ID certificate, and that
# can't be done on the phone, so it's done once here. Rerun after editing
# pass.json or the images, then commit the .pkpass.
#
# One-time setup, at developer.apple.com → Certificates, IDs & Profiles:
#   1. Identifiers → + → Pass Type IDs → pass.com.dalewebster.GymTool.membership
#   2. Certificates → + → Pass Type ID Certificate → pick that ID, and upload a
#      CSR (Keychain Access → Certificate Assistant → Request a Certificate
#      From a Certificate Authority → Saved to disk).
#   3. Open the downloaded .cer, then in Keychain Access → My Certificates,
#      right-click "Pass Type ID: pass.com.dalewebster.GymTool.membership"
#      → Export… as a .p12 with a password.
#
# Usage: Wallet/make-membership-pass.sh path/to/pass-certificate.p12
# Reads the .p12 password from $P12_PASSWORD, or asks for it.

set -euo pipefail

if [[ $# -ne 1 ]]; then
    sed -n '2,19p' "$0" | sed 's/^# \{0,1\}//'
    exit 1
fi

p12=$(cd "$(dirname "$1")" && pwd)/$(basename "$1")
cd "$(dirname "$0")/.."
source_dir=Wallet/Membership.pass
output=$PWD/GymTool/Resources/Membership.pkpass

if [[ -z ${P12_PASSWORD+set} ]]; then
    read -rsp "Password for $(basename "$p12"): " P12_PASSWORD
    echo
fi
export P12_PASSWORD

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

# Keychain exports use ciphers OpenSSL 3 only reads with -legacy, which
# LibreSSL (macOS's /usr/bin/openssl) doesn't know. Try both.
pkcs12() {
    openssl pkcs12 -in "$p12" -passin env:P12_PASSWORD "$@" 2>/dev/null ||
        openssl pkcs12 -legacy -in "$p12" -passin env:P12_PASSWORD "$@"
}
pkcs12 -clcerts -nokeys -out "$work/cert.pem"
pkcs12 -nocerts -nodes -out "$work/key.pem"

# The certificate has to be for the pass type and team named in pass.json, or
# Wallet rejects the pass.
subject=$(openssl x509 -in "$work/cert.pem" -noout -subject)
for id in passTypeIdentifier teamIdentifier; do
    value=$(sed -n "s/.*\"$id\": *\"\([^\"]*\)\".*/\1/p" "$source_dir/pass.json")
    if [[ $subject != *"$value"* ]]; then
        echo "The certificate isn't for $id $value: $subject" >&2
        exit 1
    fi
done

# Apple's intermediate certificate, which every pass signature must include.
curl -fsSL https://www.apple.com/certificateauthority/AppleWWDRCAG4.cer -o "$work/wwdr.cer"
openssl x509 -inform DER -in "$work/wwdr.cer" -out "$work/wwdr.pem"

mkdir "$work/pass"
cp "$source_dir"/*.json "$source_dir"/*.png "$work/pass/"

# The manifest lists a SHA-1 of every file in the pass; the signature covers
# the manifest.
{
    printf '{'
    separator=
    for file in "$work"/pass/*; do
        name=$(basename "$file")
        hash=$(openssl dgst -sha1 -r "$file" | cut -d' ' -f1)
        printf '%s\n  "%s": "%s"' "$separator" "$name" "$hash"
        separator=,
    done
    printf '\n}\n'
} > "$work/manifest.json"
mv "$work/manifest.json" "$work/pass/manifest.json"

openssl smime -binary -sign \
    -certfile "$work/wwdr.pem" \
    -signer "$work/cert.pem" \
    -inkey "$work/key.pem" \
    -in "$work/pass/manifest.json" \
    -out "$work/pass/signature" \
    -outform DER

mkdir -p "$(dirname "$output")"
rm -f "$output"
(cd "$work/pass" && zip -qX "$output" ./*)
echo "Wrote $output"
