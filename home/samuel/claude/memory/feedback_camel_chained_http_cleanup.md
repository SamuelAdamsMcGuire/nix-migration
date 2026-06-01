---
name: Camel chained HTTP — wipe headers and body between calls
description: When chaining HTTP calls in a Camel route, headers and body propagate from the previous step and can poison the next request — explicit cleanup is required
type: feedback
originSessionId: 303598c3-b2a9-46f9-a572-daed5bf00fff
---
In Camel (4.x, camel-http on Apache HttpClient), `<to>` HTTP calls inherit all message headers and the body from the prior processor. Two real-world consequences in this codebase:

1. Headers set in an auth route (e.g. `<setHeader name="Content-Type"><constant>application/json"/>`) leak into a subsequent GraphQL call and get sent on the wire.
2. The body from the auth response (or a `<transform>` after unmarshal) becomes the request body of the next `<to>` — Apache HttpClient sees a non-empty body and silently promotes a `httpMethod=GET` URI parameter to POST.

**Why:** This bit `rahla/interface/espprod/config/fraalliance.xml` on 2026-04-29 — Camel was sending the JWT as a POST body with `Content-Type: application/json` to the LH GraphQL endpoint, getting 404. The `httpMethod=GET` URI parameter was being silently ignored.

**How to apply:** For chained HTTP routes, before each `<to>`:

```xml
<setProperty name="bearerToken"><simple>${body}</simple></setProperty>  <!-- stash anything you need -->
<removeHeaders pattern="*"/>                                            <!-- wipe ALL prior headers -->
<setBody><constant></constant></setBody>                                <!-- empty body so HTTP method isn't promoted -->
<setHeader name="Authorization"><simple>Bearer ${exchangeProperty.bearerToken}</simple></setHeader>
<setHeader name="CamelHttpMethod"><constant>GET</constant></setHeader>  <!-- force method via header, NOT URI -->
<to uri="https://..."/>
```

`CamelHttpMethod` header is the reliable way to set method in Camel 4.x — the `?httpMethod=GET` URI parameter is unreliable.

Also add `streamCache="true"` to any route where you `<log>` the body or it could be consumed before reaching the next processor (HTTP responses are streams).
