# FLT Phase 1 Improvement Backlog

## Current best models (as of 2026-02-26)
- **deps**: `deps_15022026_91f46a45667246dfb67a137cade43a09` (old Feb 15)
- **mins short**: `mins_short_15022026_59cd834e4be242edb46484b69f7d39cb` (old Feb 15)
- **mins mid**: `mins_mid_15022026_d255627736a94250b49ee2993d6fdab3` (old Feb 15)
- Model config in: `flt-test-uplift-prediction/main.py` lines ~69, ~108, ~124

## Current WAPE scores (Feb 15 models, Jul–Dec 2025)
| Metric | Jul | Aug | Sep | Oct | Nov | Dec | **Mean** |
|--------|-----|-----|-----|-----|-----|-----|----------|
| Deps   | 2.02| 2.11| 2.47| 4.45|14.53|19.90| 7.58% |
| Mins   | 2.58| 2.85| 3.40| 4.04| 8.46|16.49| 6.30% |
| Sched baseline (deps) | 2.50|1.37|1.65|2.78|15.90|21.29| 7.58% |

## Why the Feb 25 clean-data retrain was WORSE
- Deps: new model wins Aug/Sep/Oct but loses Jul/Nov/Dec → net +0.52% mean WAPE
- Mid mins: new model loses December badly (+1.02pp) — even though Oct/Nov improve slightly
- Root cause: corrupt training data (inflated Q4 2023) accidentally gave more weight to autumn/winter
  seasonal patterns. Cleaning it removed those extra "votes" for the hard months.
- Conclusion: don't retrain on clean data alone without adding new features first

## Improvement ideas (not yet attempted)

### Priority 1 — Feature engineering for Nov/Dec volatility
- **Historical cancellation rate** by (airline, airport, month) — e.g. % of scheduled deps that
  actually operated in prior years. Main signal the model is missing for winter months.
- **Schedule reliability score** per route: std dev of act/sched ratio over last 12 months.
  Routes with high variability need more aggressive correction.

### Priority 2 — Targeted correction for high-error months
- **Seasonal bias correction layer**: fit a simple per-(airline, airport, month) bias term on top
  of model predictions. Apply as post-processing to lift Nov/Dec performance.
- **Hybrid: use schedule for accurate months, model for volatile months** — Aug/Sep/Oct the
  model makes things worse vs raw schedule; Nov/Dec it genuinely helps. Consider routing
  high-reliability routes through schedule directly.

### Priority 3 — Training data improvements
- Training data already covers Q4 2023 – Q2 2025 unbroken (two full winters: Q4 2023 and Q4 2024).
  Volume is healthy: 168K–182K rows per winter month. Data coverage is NOT the bottleneck.
- If 2022 SSIM files were available it could add a third winter, but the evidence suggests
  the problem is missing features rather than insufficient data.

### Priority 4 — Model architecture
- Separate **cancellation model** (binary: does route operate at all?) from **departure count
  model** (how many deps when it does operate?). The current regression conflates these.

## Benchmark script
`flt-test-uplift-prediction/benchmark_phase1_models.py` — tests all model combinations.
Update `ACTIVE_*` constants if main.py model paths change before re-running.
