#!/usr/bin/env bash
# Emit the URL-safe base64 SHA-256 signing-certificate checksum for an APK.
# Matches ApkSignatureVerifier / Android MDM provisioning format.
set -euo pipefail

apk="${1:?APK path}"
apksigner="${2:-apksigner}"

digest="$("$apksigner" verify --print-certs "$apk" 2>/dev/null | awk -F': ' '/SHA-256 digest:/ {print $2; exit}')"
if [[ -z "$digest" ]]; then
  echo "Could not read APK signing certificate digest from $apk" >&2
  exit 1
fi

python3 - "$digest" <<'PY'
import base64
import sys

hex_digest = sys.argv[1].replace(":", "").lower()
if len(hex_digest) != 64:
    raise SystemExit(f"unexpected SHA-256 digest length: {hex_digest}")
raw = bytes.fromhex(hex_digest)
encoded = base64.urlsafe_b64encode(raw).decode("ascii").rstrip("=")
print(encoded)
PY
