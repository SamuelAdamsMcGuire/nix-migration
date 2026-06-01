---
name: reference-startplatz-wifi
description: "STARTPLATZ office WiFi — 2.4 GHz channel 6 is heavily congested; NetworkManager profile \"STARTPLATZ-Community\" is locked to 5 GHz (band=a) to avoid intermittent stalls that previously got blamed on the VPN."
metadata: 
  node_type: memory
  type: reference
  originSessionId: 006b770d-c735-4abd-9a0b-cc819cf7bbf6
---

User works from STARTPLATZ (Cologne). Two SSIDs: `STARTPLATZ-Community` (used) and `STARTPLATZ-Intern`. Both broadcast on 2.4 GHz channel 6 from multiple APs, and that band is severely congested at this site.

**Symptom previously reported as "internet issues / maybe VPN, maybe laptop":** intermittent stalls, blamed on the vpnc VPN tunnel.

**Actual cause:** 2.4 GHz airtime contention on channel 6.
- ~65% TX retry rate, max 174 ms latency to the local WiFi gateway, ~34 ms jitter
- VPN endpoint inherited the WiFi instability: 10% loss, max 384 ms RTT
- Signal strength was fine throughout (-51 dBm) — it was channel congestion, not range

**Fix applied (2026-05-18):** locked the NetworkManager profile to 5 GHz:
```
sudo nmcli connection modify "STARTPLATZ-Community" 802-11-wireless.band a
```
After switch: connected on 5 GHz channel 116, 40 MHz, HE-MCS 7. Gateway latency 38 ms → 4 ms, VPN endpoint 136 ms → 16 ms, packet loss gone.

**To revert** (e.g. if user moves somewhere with weak 5 GHz coverage): `sudo nmcli connection modify "STARTPLATZ-Community" 802-11-wireless.band ""`.

**If user reports "internet issues" again at STARTPLATZ:** first verify the band lock is still in place (`nmcli connection show "STARTPLATZ-Community" | grep band`). If yes and problems persist, look elsewhere (VPN endpoint, ISP, captive portal) rather than re-diagnosing the WiFi from scratch.

The VPN client is vpnc (NetworkManager-vpnc), tunnel device `tun0`, internal address space 10.176.38.0/24, search domains include `lufthansa.com`, `lufthansagroup.com`, `ads.dlh.de`. Related: [[project-lh-cute-user-agent-filter]].
