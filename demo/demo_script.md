# Assembly Line Digital Twin

**Thailand - Automotive Assembly**
Use case: Assembly Line Digital Twin

> A digital twin of 24 synthetic assembly stations (body weld cells, paint booths, trim and chassis stations, end-of-line test cells) at a fictional vehicle assembler in six Thai plant cities. Dynamic tables, a holdout-evaluated line-stop risk classifier, a line-stop hours forecast and grounded AI answers.

## Why Snowflake

- **Dynamic tables** reconcile station KPIs from RAW twin readings, with checks in `run_core.py`
- **Line-stop risk classification** gives a holdout-evaluated next-7-day line-stop risk per station
- **Line-stop forecast** projects 14 days of plant-network line-stop hours with prediction intervals
- **Grounded AI**: the Cortex Agent (Analyst over a semantic view, plus Search over SOPs) shows its SQL and SOP citations. The memo is written by Cortex AI_COMPLETE (Snowflake build) or Amazon Bedrock (AWS build).
- **Live ingestion**: `APP.SIMULATE_TELEMETRY` in the Snowflake build, or IoT Core to S3 to Snowpipe auto-ingest in the AWS build, then an alert and email

## What is built

| | |
|---|---|
| Dimension table | `RAW.STATIONS` (24 rows) |
| Fact table | `RAW.SENSOR_READINGS` (2,160 station-days, 90 days) |
| Curated layer | `CURATED.KPI_SUMMARY`, `PERFORMANCE_SUMMARY`, `DOWNTIME_CAUSES`, `TREND_ANALYSIS` |
| ML | `ML.FAILURE_RISK_SCORES`, `ML.FAILURE_RISK_HOLDOUT_METRICS`, `ML.DOWNTIME_FORECAST`, `ML.VIBRATION_ANOMALIES` |

Plant cities: Rayong, Chonburi, Chachoengsao, Ayutthaya, Samut Prakan, Prachinburi.
Station types: Body Weld Cell, Paint Booth, Trim and Chassis Station, End-of-Line Test Cell.

## KPI cards (live from `CURATED.KPI_SUMMARY`; no fallback values)

| Card | Value in a fresh build |
|---|---|
| Station Availability | 99% (99.01%) |
| Unplanned Line Stops | 154 |
| MTBF (Avg) | 243.5 hrs |
| Stations Twinned | 24 |
| Parts on Order | 4 |
| Lineside Spare Coverage | 64.9% |

Values are synthetic. A rebuild reproduces them because the data is HASH-seeded.

## Demo flow

1. Executive Cockpit (Kanokwan Thepsuwan): KPIs, daily station availability and line-stop hours by stop cause; robot servo faults lead the hours lost
2. Predictive (Thanakorn Rattanachai): holdout metrics, risk bands, 14-day line-stop hours forecast, vibration anomalies
3. Line Planning: lineside spare coverage, PM compliance against first-pass yield, then Generate a memo written from Snowflake tables only
4. Live IoT: run `CALL APP.SIMULATE_TELEMETRY(20)` (Snowflake build) or `python aws/publish_telemetry.py --count 20` (AWS build; messages arrive about 20-60 s later through IoT Core, S3 and Snowpipe). Then run `EXECUTE ALERT APP.LIVE_ALARM_ALERT` and show the alert log and email.
5. Ask AI: the Cortex Agent answers metric questions through the semantic view and cites SOPs from Cortex Search. The SQL is shown.
6. QuickSight (AWS build only): the same Snowflake tables through DIRECT_QUERY; risk and IoT visuals
7. Architecture: both diagrams, the current build first

## Talking points

- Availability ranges from 96.21% to 100% by station, and Prachinburi is the lowest plant city at 98.51%. Line-stop hours are concentrated in a few stations.
- Body weld cells lose the most hours (148.4 h); robot servo faults (57.1 h) and weld tip wear (47.9 h) are the top two causes.
- The risk model is evaluated on a time-based holdout: precision 0.54 and recall 0.39 at 0.5, against a 0.33 base rate. Present it as triage, not a guarantee.
- Plant power dips (Ayutthaya and Chonburi) are excluded from line-stop labels.

## Business impact

Use only the sourced references in `README.md` (Business Impact).

---
Hand-maintained.
