#!/usr/bin/env bash
# Emit URL-safe base64 SHA-256 of the APK signing certificate (Android MDM format).
set -euo pipefail

APK="${1:?apk path required}"
BUILD_TOOLS="${ANDROID_HOME}/build-tools"
APKSIGNER="$(find "$BUILD_TOOLS" -maxdepth 2 -name apksigner -type f 2>/dev/null | sort -V | tail -n1)"
[[ -n "$APKSIGNER" ]] || {
    echo "error: apksigner not found under ANDROID_HOME=$ANDROID_HOME" >&2
    exit 1
}

DIGEST="$("$APKSIGNER" verify --print-certs "$APK" 2>/dev/null | sed -n 's/^Signer #1 certificate SHA-256 digest: //p' | head -n1)"
[[ -n "$DIGEST" ]] || {
    echo "error: could not read signing certificate digest from $APK" >&2
    exit 1
}

python3 - "$DIGEST" <<'PY'
import base64
import sys

hex_digest = sys.argv[1].lower().replace(":", "").strip()
raw = bytes.fromhex(hex_digest)
alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_"
out = []
i = 0
while i < len(raw):
    b0 = raw[i]
    i += 1
    if i < len(raw):
        b1 = raw[i]
        i += 1
        if i < len(raw):
            b2 = raw[i]
            i += 1
            out.append(alphabet[b0 >> 2])
            out.append(alphabet[((b0 & 3) << 4) | (b1 >> 4)])
            out.append(alphabet[((b1 & 15) << 2) | (b2 >> 6)])
            out.append(alphabet[b2 & 63])
        else:
            out.append(alphabet[b0 >> 2])
            out.append(alphabet[((b0 & 3) << 4) | (b1 >> 4)])
            out.append(alphabet[(b1 & 15) << 2])
    else:
        out.append(alphabet[b0 >> 2])
        out.append(alphabet[(b0 & 3) << 4])
print("".join(out))
PY
