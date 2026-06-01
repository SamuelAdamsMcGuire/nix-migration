# Init container truststore approach

## Goal
Dynamically fetch certs at pod startup — no static `keystore.jks` binary in repo.

## How it works
- Init container uses `datatactics/rahla:1.3.0` (has both `openssl` + `keytool`)
- Fetches full cert chain with `openssl s_client -showcerts -connect host:port 2>/dev/null`
- Splits chain with `csplit`, imports each cert with `keytool -import -trustcacerts -noprompt`
- Writes to `/truststore/keystore.jks` on a shared emptyDir volume
- Main container mounts emptyDir at `/keystore.jks` — same path as before, no EXTRA_JAVA_OPTS change needed

## Endpoints to fetch
- `artifactory.lsyesp.lhgroup.de:443` — corporate CA
- `lsymxhci2.mesx.lsy.fra.dlh.de:1417` — MQ INT
- `lsymxhcp2.mesx.lsy.fra.dlh.de:1417` — MQ PROD (for espprod)

## Kustomization change
Remove `keystore` configMapGenerator entry — no more binary JKS needed.

## Gotcha
Namespace quota requires explicit `resources.requests` and `resources.limits` on init containers.
Use: limits cpu=500m/memory=256Mi, requests cpu=100m/memory=128Mi

## Status
Tested on interface/espint — blocked by namespace quota (fixed with resources).
Parked — revert to static keystore for now, revisit when ready.
