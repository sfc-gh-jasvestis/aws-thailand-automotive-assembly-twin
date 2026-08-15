# Demo Script: Assembly Line Digital Twin
## ~4-Minute Recorded Walkthrough
**Format**: Screen recording with voiceover
**Target**: Customer meeting / booth loop / social share
**Narrative**: "Snowflake powers the digital twin data layer for 8 assembly lines, detecting equipment anomalies, forecasting downtime events, and enabling 3D visualization — replacing fragmented SCADA systems with unified analytics"
**Demo Mode**: Open app with `?demo=true` for presenter notes

---

## Two Personas

| Persona | Role | Tool | What they care about |
|---|---|---|---|
| **Chaiwat Sriprasert** | Plant Director | React App (SPCS) | OEE, unplanned downtime cost, production throughput, capacity utilization |
| **Waraporn Jittamanee** | Maintenance Engineering Manager | Amazon QuickSight | Equipment health scores, vibration analysis, predictive alerts, spare parts inventory |

---

## What's Built

| Layer | Component | Detail |
|---|---|---|
| **RAW** | 8 tables | ASSEMBLY_LINES (8), STATIONS (240), EQUIPMENT_TELEMETRY (750000), PRODUCTION_EVENTS (45000), MAINTENANCE_RECORDS (5000), TWINMAKER_SCENES (8), SPARE_PARTS_INVENTORY (1200), THAI_AUTO_PRODUCTION (12) |
| **CURATED** | 4 Dynamic Tables | LINE_OEE_REALTIME, EQUIPMENT_HEALTH_SCORE, DOWNTIME_COST, VIBRATION_TIMESERIES |
| **ML** | ML.FORECAST + ML.ANOMALY_DETECTION | Forecasting + anomaly detection |
| **AI** | COMPLETE, AI_CLASSIFY, SUMMARIZE | Classification + extraction |
| **Search** | Cortex Search | 5000 documents indexed |
| **Agent** | ASSEMBLY_TWIN_AGENT | Semantic View + Search tools |


---

## The Story

Thailand's automotive assembly plants run 8 lines producing pickups and SUVs for Toyota, Honda, and Isuzu. Unplanned downtime costs ฿420M per quarter — but traditional SCADA systems detect failures only after they happen. A digital twin powered by IoT TwinMaker visualization and Snowflake ML predicts failures 4-7 days early.

---

## Script

### [0:00–0:45] EXECUTIVE COCKPIT

**Show**: Executive Cockpit tab

> "Four hundred twenty million baht in unplanned downtime cost across 8 assembly lines this quarter."

**Action**: Point at the ฿420M downtime cost KPI

### [0:45–1:30] DIGITAL TWIN VIEW

**Show**: Digital Twin View tab

> "3D visualization of Line-02 body shop — 30 robot stations color-coded by health score."

**Action**: Show 3D assembly line visualization

### [1:30–2:15] PREDICTIVE MAINTENANCE

**Show**: Predictive Maintenance tab

> "ML.ANOMALY_DETECTION flags 19 stations with abnormal vibration patterns."

**Action**: Show anomaly timeline for W-12

### [2:15–3:00] ASK AI

**Show**: Ask AI tab

> "Chaiwat asks: 'What's our total unplanned downtime cost this month by line?'"

**Action**: Type: 'Unplanned downtime cost by line this month'

### [3:00–3:45] ARCHITECTURE & DATA

**Show**: Architecture & Data tab

> "Eight Snowflake capabilities, six AWS services."

**Action**: Walk through architecture diagram


---

## Key Demo Differentiators

1. **ML.ANOMALY_DETECTION on vibration data** — Only demo applying anomaly detection to assembly robot vibration patterns
2. **IoT TwinMaker + React Canvas visualization** — 3D digital twin view backed by Snowflake Dynamic Tables for real-time state
3. **OEE calculation via Dynamic Tables** — Real-time Overall Equipment Effectiveness from streaming production events
4. **Thai automotive assembly context** — Realistic Thai plant names, station IDs, and Eastern Seaboard industrial locations
5. **Time-to-failure prediction** — ML.FORECAST on equipment health metrics with confidence intervals
6. **Maintenance-to-production optimization** — AI recommends PM scheduling around production demand to minimize impact


---

## Demo Prep Checklist

### Data Verification
- [ ] `SELECT COUNT(*) FROM ASSEMBLY_TWIN.RAW.EQUIPMENT_TELEMETRY` → 750000
- [ ] `SELECT COUNT(*) FROM ASSEMBLY_TWIN.RAW.PRODUCTION_EVENTS` → 45000
- [ ] `SELECT COUNT(*) FROM ASSEMBLY_TWIN.CURATED.LINE_OEE_REALTIME WHERE OEE < 0.65` → 2

### ML Model Verification
- [ ] `SELECT COUNT(*) FROM ASSEMBLY_TWIN.ML.DOWNTIME_FORECAST_RESULTS` → >0
- [ ] `SELECT SUM(CASE WHEN IS_ANOMALY THEN 1 ELSE 0 END) FROM ASSEMBLY_TWIN.ML.VIBRATION_ANOMALY_RESULTS` → >=15

### AI/Agent Verification
- [ ] `SELECT COUNT(*) FROM ASSEMBLY_TWIN.AI.DOWNTIME_CLASSIFICATIONS` → >1000

