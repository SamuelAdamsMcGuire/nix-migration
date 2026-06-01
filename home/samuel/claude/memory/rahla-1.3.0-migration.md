---
name: Rahla 1.3.0 migration notes
description: Breaking changes and known issues when upgrading from Rahla 1.2.x to 1.3.0
type: reference
---

# Rahla 1.3.0 Breaking Changes (released 2026-02-12)

## Official breaking changes
- Base image: `linuxserver/baseimage-alpine:3.23`
- JDK: temurin `jdk-21.0.10+7` (was JDK 11)
- **File paths**: `/rahla/deploy` → `/config/deploy` (symlinked), `/rahla/etc` → `/config/etc`. `/rahla/deploy` no longer scanned.
- **`RAHLA_DEPLOY_PATH` removed**: use `org.apache.felix.fileinstall` instead
- **Jetty → Undertow**: `pax-web-http-jetty` replaced with `pax-web-http-undertow`
- Container user renamed: `rahla` → `abc`

## Known issues from real upgrades

### Undertow REST body type
Undertow won't auto-convert objects (e.g. LinkedHashMap) to bytes.
**Fix:** Add `<setBody><constant>OK</constant></setBody>` after final processing step in routes that don't return an explicit body.

### GET with JSON body breaks in Undertow
REST endpoints that use GET + JSON body work in Jetty 1.2.x but break in Undertow 1.3.0.
**Fix:** Switch consumers to POST with JSON body, or use query params. Keep GET + POST during transition period.

### Dockerfile container user rename
`COPY --chown=rahla:rahla deploy /config/deploy` fails because user is now `abc`.
**Fix:** Change to `COPY --chown=abc:abc deploy /config/deploy`

### JDK 21 TLS cipher suite change
JDK 21 dropped `TLS_RSA_WITH_AES_128_CBC_SHA256`.
**Fix:** Update SSLCipherSuite to `TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384` on both the Camel endpoint AND the MQ server channel (contact queue admin). Both sides must match.
- Mainly affects IBM MQ connections
- Contact: framescon@lhsystems.com for MQ server channel updates

## Config migration (Camel XML)
- Remove `<restConfiguration>` block
- Remove `<rest>` DSL block (GET/POST entries)
- Convert `check-key-*` routes: `<from uri="direct:..."/>` → `<from uri="undertow:http://0.0.0.0:8183/{{REST_CONTEXT_PATH}}/v1/..."/>`
- Update all file paths: `resource:file:/rahla/deploy/` → `resource:file:/config/deploy/`
- Update bean paths: `file:///rahla/deploy/parsing/` → `file:///config/deploy/parsing/`
