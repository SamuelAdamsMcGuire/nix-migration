#!/usr/bin/env bash
# Clone every work repo back into place after the NixOS migration, in one swoop.
# Idempotent: skips any repo that's already cloned. Run from anywhere.
#
#   bash clone-all-repos.sh
#
# Prerequisites:
#   - git installed (it is, via the NixOS config)
#   - network access to each host. The LSY-internal repos
#     (git.int.k8s.lsyesp.lhgroup.de) need the company network / VPN.
#   - auth: HTTPS repos use your restored keyring/credentials; SSH repos need your
#     SSH key (restored from the bundle to ~/.ssh/yes).
set -u

# path-under-$HOME <TAB> remote-url   (one per line)
REPOS=$(cat <<'LIST'
# ---- LSY internal (git.int.k8s.lsyesp.lhgroup.de — needs company network/VPN) ----
projects/flightpos/flight-positioning	https://git.int.k8s.lsyesp.lhgroup.de/flightpos/flight-positioning.git
projects/flightpos/flight-positioning-rahla	https://git.int.k8s.lsyesp.lhgroup.de/flightpos/flight-positioning-rahla.git
projects/flightpos/flight-positioning-service	https://git.int.k8s.lsyesp.lhgroup.de/flightpos/flight-positioning-service.git
projects/flt/connexinfo-service	https://git.int.k8s.lsyesp.lhgroup.de/flt/connexinfo-service.git
projects/flt/eurocontrol-service	https://git.int.k8s.lsyesp.lhgroup.de/flt/eurocontrol-service.git
projects/flt/flight-engineer	https://git.int.k8s.lsyesp.lhgroup.de/flt/flight-engineer.git
projects/flt/flt-service	https://git.int.k8s.lsyesp.lhgroup.de/flt/flt-service.git
projects/flt/flt-test-fueling-duration	https://git.int.k8s.lsyesp.lhgroup.de/flt/flt-test-fueling-duration.git
projects/flt/flt-test-uplift-prediction	https://git.int.k8s.lsyesp.lhgroup.de/flt/flt-test-uplift-prediction.git
projects/flt/fueling-duration-predictor	https://git.int.k8s.lsyesp.lhgroup.de/flt/fueling-duration-predictor.git
projects/flt/fuel-service	https://git.int.k8s.lsyesp.lhgroup.de/flt/fuel-service.git
projects/flt/horizon	https://git.int.k8s.lsyesp.lhgroup.de/flt/horizon.git
projects/flt/ops-service	https://git.int.k8s.lsyesp.lhgroup.de/flt/ops-service.git
projects/flt/weather-service	https://git.int.k8s.lsyesp.lhgroup.de/flt/weather-service.git
projects/fraalliance/fraalliance-backup-services	https://git.int.k8s.lsyesp.lhgroup.de/fraap/fraalliance-backup-services.git
projects/fraalliance/fraalliance-datastore	https://git.int.k8s.lsyesp.lhgroup.de/fraap/fraalliance-datastore.git
projects/fraalliance/fraalliance-gui	https://git.int.k8s.lsyesp.lhgroup.de/fraap/fraalliance-gui.git
projects/fraalliance/fraalliance-gx	https://git.int.k8s.lsyesp.lhgroup.de/fraap/fraalliance-gx.git
projects/fraalliance/fraalliance-pfa-dbt-rahla	https://git.int.k8s.lsyesp.lhgroup.de/fraap/fraalliance-pfa-dbt-rahla.git
projects/fraalliance/fraalliance-pfa-gui	https://git.int.k8s.lsyesp.lhgroup.de/fraap/fraalliance-pfa-gui.git
projects/fraalliance/fraalliance-pfa	https://git.int.k8s.lsyesp.lhgroup.de/fraap/fraalliance-pfa.git
projects/fraalliance/fraalliance-pfa-reporting	https://git.int.k8s.lsyesp.lhgroup.de/fraap/fraalliance-pfa-reporting.git
projects/fraalliance/fraalliance-platform	https://git.int.k8s.lsyesp.lhgroup.de/fraap/fraalliance-platform.git
projects/fraalliance/fraalliance-user-metrics-scraper	https://git.int.k8s.lsyesp.lhgroup.de/fraap/fraalliance-user-metrics-scraper.git
projects/fraalliance/irrops-gx	https://git.int.k8s.lsyesp.lhgroup.de/fraap/irrops-gx.git
projects/fraalliance/irrops-service	https://git.int.k8s.lsyesp.lhgroup.de/fraap/irrops-service.git
projects/fraalliance/irrops-stress-test	https://git.int.k8s.lsyesp.lhgroup.de/fraap/irrops-stress-test.git
projects/vigilo/vigilo-rahla	https://git.int.k8s.lsyesp.lhgroup.de/vigilo/vigilo-rahla.git
projects/vigilo/vigilo-services	https://git.int.k8s.lsyesp.lhgroup.de/vigilo/vigilo-services.git
projects/lsy-repos/prometheus-alertrule-generator	https://git.int.k8s.lsyesp.lhgroup.de/maas/prometheus-alertrule-generator.git
# ---- datatactics gitea (repo.datatactics.dev) ----
dtacs-repos/dbt-run-api	https://repo.datatactics.dev/oss/dbt-run-api.git
dtacs-repos/harvester	https://repo.datatactics.dev/agriculture/harvester.git
dtacs-repos/odd-collector-rahla	https://repo.datatactics.dev/s.mcguire/odd-collector-rahla.git
dtacs-repos/opsint	https://repo.datatactics.dev/aviation/opsint.git
dtacs-repos/sita-parser	https://repo.datatactics.dev/aviation/sita-parser.git
dtacs-repos/skills	https://repo.datatactics.dev/tactician/skills.git
dtacs-repos/sops-secrets	https://repo.datatactics.dev/tactician/sops-secrets.git
# ---- github: dttctcs org ----
dtacs-repos/dtacs-playground	https://github.com/dttctcs/dtacs-playground.git
dtacs-repos/dtacs-secrets	https://github.com/dttctcs/dtacs-secrets.git
dtacs-repos/mlrunner	https://github.com/dttctcs/mlrunner.git
dtacs-repos/local-k8s	git@github.com:dttctcs/local-k8s.git
projects/horn/cube_horn	https://github.com/dttctcs/horn-cosifan-cubes.git
projects/horn/datavault_horn	https://github.com/dttctcs/horn-cosifan-dv.git
# ---- github: personal / public ----
presentations/samueladamsmcguire.github.io	https://github.com/SamuelAdamsMcGuire/samueladamsmcguire.github.io.git
tutorials/ds-book-template	https://github.com/neuefische/ds-book-template.git
tutorials/prompt-eng-interactive-tutorial	https://github.com/anthropics/prompt-eng-interactive-tutorial.git
tutorials/spiced-data-analytics	https://github.com/SamuelAdamsMcGuire/spiced-data-analytics.git
LIST
)

ok=0; skip=0; fail=0
while IFS=$'\t' read -r rel url; do
  case "$rel" in ''|\#*) continue;; esac          # skip blanks/comments
  dest="$HOME/$rel"
  if [ -d "$dest/.git" ]; then
    echo "  ⏭  exists: $rel"; skip=$((skip+1)); continue
  fi
  echo "  ⬇  cloning $rel"
  mkdir -p "$(dirname "$dest")"
  if git clone --quiet "$url" "$dest"; then ok=$((ok+1)); else echo "     ❌ FAILED: $url"; fail=$((fail+1)); fi
done <<< "$REPOS"

echo
echo "Done — cloned $ok, skipped $skip (already present), failed $fail."
echo
echo "NOT clonable (restore from the backup drive/bundle instead):"
echo "  - tutorials/agent-irrops-test   (no remote — only copy is in work_backup_pre_nix_01062026/tutorials/)"
echo "  - this config repo (nix-migration) — you already cloned it to run the migration"
echo
echo "Reminders:"
echo "  - LSY repos need the company network / VPN to reach git.int.k8s.lsyesp.lhgroup.de"
echo "  - failures are usually auth (keyring not unlocked) or network (VPN) — fix and re-run; it skips what's done"
echo "  - unpushed feature branches you had are on the remotes (we pushed them); 'git fetch' to see them"
