# Assembly Line Digital Twin

**Thailand - Automotive Manufacturing**
Use case: Digital Twin & Predictive Maintenance

> Digital twin of 8 automotive assembly lines across Thailand's Eastern Seaboard — IoT TwinMaker syncs with Snowflake ML to predict downtime, detect anomalies, and visualize real-time production in a React Canvas.

## Why Snowflake

Snowflake powers the digital twin data layer for 8 assembly lines, detecting equipment anomalies, forecasting downtime events, and enabling 3D visualization — replacing fragmented SCADA systems with unified analytics

- **ML.ANOMALY_DETECTION on vibration data** - Only demo applying anomaly detection to assembly robot vibration patterns
- **IoT TwinMaker + React Canvas visualization** - 3D digital twin view backed by Snowflake Dynamic Tables for real-time state
- **OEE calculation via Dynamic Tables** - Real-time Overall Equipment Effectiveness from streaming production events
- **Thai automotive assembly context** - Realistic Thai plant names, station IDs, and Eastern Seaboard industrial locations
- **Time-to-failure prediction** - ML.FORECAST on equipment health metrics with confidence intervals
- **Maintenance-to-production optimization** - AI recommends PM scheduling around production demand to minimize impact

## What is deployed

| | |
|---|---|
| Database | `THAILAND_AUTOMOTIVE_ASSEMBLY_TWIN` |
| Service | `THAILAND_AUTOMOTIVE_ASSEMBLY_TWIN_APP` |
| Compute pool | `SEA_DEMOS_THAILAND_POOL` |
| Dimension table | `RAW.ASSEMBLY_LINES` (20 rows) |
| Fact table | `RAW.EQUIPMENT_TELEMETRY` (250,000 rows, 90 days) |
| Curated layer | `CURATED.PERFORMANCE_SUMMARY`, `CURATED.TREND_ANALYSIS`, `CURATED.KPI_SUMMARY` |
| Currency | THB (฿) |

Regions in play: Bangkok, Chonburi, Rayong, Chiang Mai, Songkhla
Segments: Stamping, Body Weld, Paint, Final Assembly

Dynamic tables are created suspended and refreshed on demand:

```bash
./refresh_demo_data.sh THAILAND_AUTOMOTIVE_ASSEMBLY_TWIN
```

## KPI cards

Every card below is served live from `CURATED.KPI_SUMMARY`. The app keeps the
original literal as a fallback, so it still renders if Snowflake is unreachable.

| Card | Value | Backed by |
|---|---|---|
| Assembly Line OEE | `87.3%` | average per event |
| Digital Twin Sync | `1.2s` | average per event |
| Quality Defects (Today) | `4` | average per event |
| Units Produced (MTD) | `12,847` | total across Assembly Lines |
| Cycle Time Variance | `±2.1s` | average per event |
| Energy per Unit | `48 kWh` | average per event |
| Simulation Accuracy | `99.2%` | average per event |


## Demo flow

1. Executive Cockpit
2. Digital Twin View
3. Predictive Maintenance
4. Ask AI
5. Architecture & Data

## Talking points

- **฿420M** - unplanned downtime cost this quarter (US$12M)
- **72.3% OEE** - average across 8 lines (target: 85%)
- **19 stations** - showing equipment degradation patterns
- **4 days** - predicted time-to-failure for Station W-12 (ML.FORECAST)
- **750K readings** - ingested daily via IoT Core → Snowpipe Streaming
- **240 stations** - monitored across 8 assembly lines in 3 plants

## Business impact

- Thailand's automotive sector contributes 12% of GDP with 1.88M vehicles produced in 2023 (FTI Thailand)
- Predictive maintenance reduces unplanned downtime by 30-50% and maintenance costs by 10-25% (McKinsey Industry 4.0)
- Digital twins in manufacturing improve OEE by 5-15% through real-time optimization (Deloitte Smart Factory)
- Toyota Thailand's Gateway plant produces 300,000 vehicles annually with Industry 4.0 systems (Toyota Thailand)

---
Generated from `generator/demo_specs/aws-thailand-automotive-assembly-twin.json`. Do not hand-edit: run
`python3 generator/gen_repo_docs.py aws-thailand-automotive-assembly-twin` instead.
