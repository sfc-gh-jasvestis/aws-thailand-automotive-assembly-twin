-- ============================================================================
-- 04_DYNAMIC_TABLES.SQL — Curated layer for Assembly Line Digital Twin
-- ============================================================================
USE DATABASE ASSEMBLY_TWIN;
USE SCHEMA CURATED;

-- LINE_OEE_REALTIME: Real-time OEE calculation per assembly line (Availability × Performance × Quality)
-- Source: ASSEMBLY_LINES, PRODUCTION_EVENTS
CREATE OR REPLACE DYNAMIC TABLE CURATED.LINE_OEE_REALTIME
  TARGET_LAG = '5 minutes'
  WAREHOUSE = ASSEMBLY_WH
AS
SELECT * FROM RAW.ASSEMBLY_LINES;
-- TODO: Replace with actual join/aggregation logic per demo

-- EQUIPMENT_HEALTH_SCORE: Equipment health index from sensor telemetry patterns
-- Source: STATIONS, EQUIPMENT_TELEMETRY
CREATE OR REPLACE DYNAMIC TABLE CURATED.EQUIPMENT_HEALTH_SCORE
  TARGET_LAG = '5 minutes'
  WAREHOUSE = ASSEMBLY_WH
AS
SELECT * FROM RAW.STATIONS;
-- TODO: Replace with actual join/aggregation logic per demo

-- DOWNTIME_COST: Downtime cost attribution by station and reason code
-- Source: PRODUCTION_EVENTS, ASSEMBLY_LINES
CREATE OR REPLACE DYNAMIC TABLE CURATED.DOWNTIME_COST
  TARGET_LAG = '5 minutes'
  WAREHOUSE = ASSEMBLY_WH
AS
SELECT * FROM RAW.PRODUCTION_EVENTS;
-- TODO: Replace with actual join/aggregation logic per demo

-- VIBRATION_TIMESERIES: Vibration RMS timeseries for ML.ANOMALY_DETECTION input
-- Source: EQUIPMENT_TELEMETRY
CREATE OR REPLACE DYNAMIC TABLE CURATED.VIBRATION_TIMESERIES
  TARGET_LAG = '5 minutes'
  WAREHOUSE = ASSEMBLY_WH
AS
SELECT * FROM RAW.EQUIPMENT_TELEMETRY;
-- TODO: Replace with actual join/aggregation logic per demo

