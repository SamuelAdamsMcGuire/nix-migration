---
name: fraalliance API public URLs
description: Public hostnames + REST_CONTEXT_PATH for the fraalliance Camel REST API in INT and PROD (resolves the {{REST_CONTEXT_PATH}} placeholder in the rahla XML configs)
type: reference
originSessionId: 88b72962-13ad-4caf-9c5e-5657092faa88
---
The fraalliance Camel REST endpoints (defined in `fraalliance-pfa/rahla/integration/<env>/config/fraalliance.xml`) are exposed via:

- PROD: `https://prod.lsyesp.lhgroup.de/fraalliance/api/v1/...`
- INT:  `https://int.lsyesp.lhgroup.de/fraalliance/api/v1/...`

So `{{REST_CONTEXT_PATH}}` resolves to `/fraalliance/api` and the internal port `8183` is fronted by the LH ingress on `*.lsyesp.lhgroup.de`.

Example: the `<get path="/sec/fra/">` route in espprod is reachable at `https://prod.lsyesp.lhgroup.de/fraalliance/api/v1/sec/fra/` and requires header `x-api-key` matching the configured `x-api-key-sec-fra`.
