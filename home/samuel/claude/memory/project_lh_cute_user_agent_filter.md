---
name: LH cute.dlh.de gateway User-Agent filtering
description: Lufthansa CUTE GraphQL gateway returns 500 for Apache-HttpClient and arbitrary custom User-Agents — workaround is to set User-Agent to curl/X.Y.Z
type: project
originSessionId: 303598c3-b2a9-46f9-a572-daed5bf00fff
---
The CUTE checkin counter API at `https://ctraffic-prodref-az.cute.dlh.de/gateway/services/monitor/api/graphql/execute?queryName=businessClassWorkstations` started filtering on `User-Agent` around 2026-04-30. Behaviour observed:

- `User-Agent: curl/X.Y.Z` → **200 with workstation data**
- `User-Agent: Apache-HttpClient/...` → **500** ("Invalid field 'workstations'" GraphQL error from the backend)
- `User-Agent: fraalliance-rahla/1.0` → **500** (sometimes JHipster generic `org.zalando.problem` error, sometimes the GraphQL one — LH's behaviour is unstable, likely mid-deploy)

The same auth flow + URL works fine from curl in the rahla pod, only the UA value matters. Documented LH API contract makes no mention of this — it's an upstream regression / WAF rule.

**Why:** LH appears to be filtering non-curl/non-browser UAs at the gateway level. Likely an anti-scraper rule rolled out without communication.

**How to apply:** In Camel routes calling this endpoint (and probably any other `*.cute.dlh.de` endpoint), set `<setHeader name="User-Agent"><constant>curl/8.5.0</constant></setHeader>` before the `<to>`. If a previously-working route to a Lufthansa endpoint suddenly starts 500'ing, check the UA first — Apache HttpClient defaults to `Apache-HttpClient/X.Y.Z` and that gets blocked.

Fixed in `rahla/interface/espprod/config/fraalliance.xml` and `rahla/interface/espint/config/fraalliance.xml` on 2026-04-30. Worth opening a ticket with LH about this — they should fix the WAF rule, not require all clients to spoof curl.
