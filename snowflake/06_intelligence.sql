-- ============================================================================
-- 06_INTELLIGENCE.SQL - search, anomaly detection, semantic view, agent,
-- live-telemetry alert and on-demand refresh DAG.
-- Run with snowflake/run_intelligence.py (substitutes validated __DEMO_DB__ /
-- __DEMO_WH__ / __ALERT_EMAIL__). Requires 00-05 and aws/setup_aws.py.
-- Alerts and tasks are created SUSPENDED; run them with EXECUTE ALERT / EXECUTE TASK.
-- ============================================================================
USE DATABASE __DEMO_DB__;
CREATE SCHEMA IF NOT EXISTS SEARCH;
CREATE SCHEMA IF NOT EXISTS APP;

-- ---------- Synthetic line-stop knowledge base (clearly synthetic SOPs) ----------
CREATE OR REPLACE TABLE SEARCH.STATION_DOCS AS
WITH causes AS (
  SELECT DISTINCT r.ROOT_CAUSE, m.CATEGORY
  FROM RAW.SENSOR_READINGS r JOIN RAW.STATIONS m ON m.ID = r.ENTITY_ID
  WHERE r.ROOT_CAUSE IS NOT NULL AND r.FAILURE_COUNT > 0
)
SELECT
  'SOP-' || LPAD(ROW_NUMBER() OVER (ORDER BY CATEGORY, ROOT_CAUSE)::VARCHAR, 3, '0') AS DOC_ID,
  'SOP' AS DOC_TYPE,
  CATEGORY,
  ROOT_CAUSE,
  CATEGORY || ' - ' || ROOT_CAUSE || ' line-stop response' AS TITLE,
  'Synthetic demo SOP. Station type: ' || CATEGORY || '. Stop cause: ' || ROOT_CAUSE || '. '
  || 'Step 1: andon the station, apply lockout-tagout and confirm the stop code on the line PLC. '
  || 'Step 2: ' || CASE
       WHEN ROOT_CAUSE ILIKE '%weld tip%' THEN 'dress or replace the weld tips, verify weld current against the schedule and run a destructive test on the first body after restart.'
       WHEN ROOT_CAUSE ILIKE '%servo%' OR ROOT_CAUSE ILIKE '%clamp%' THEN 'read the robot controller fault log, check the fixture clamp sensors and air pressure, and re-teach the home position.'
       WHEN ROOT_CAUSE ILIKE '%airflow%' OR ROOT_CAUSE ILIKE '%atomizer%' THEN 'check booth downdraft and humidity readings, clean or replace the atomizer bell cup and run a test panel for film build.'
       WHEN ROOT_CAUSE ILIKE '%conveyor%' OR ROOT_CAUSE ILIKE '%AGV%' OR ROOT_CAUSE ILIKE '%lift%' THEN 'inspect chain tension, AGV guidance tape and lift-assist interlocks, then jog the carrier through one full cycle.'
       WHEN ROOT_CAUSE ILIKE '%torque%' THEN 'verify the torque tool against the calibration rig, swap the transducer if out of tolerance and quarantine bodies fastened since the last good check.'
       WHEN ROOT_CAUSE ILIKE '%dyno%' OR ROOT_CAUSE ILIKE '%alignment%' OR ROOT_CAUSE ILIKE '%vision%' THEN 'run the end-of-line rig self-test with a reference vehicle, recalibrate the alignment heads or camera and retest held vehicles.'
       WHEN ROOT_CAUSE ILIKE '%power%' THEN 'confirm supply status with the plant electrical lead, check UPS logs and restart the line in the documented sequence.'
       ELSE 'inspect the affected station, record readings and escalate to the line engineer if readings are out of tolerance.'
     END
  || ' Step 3: if vibration exceeds 6 mm/s or motor temperature exceeds 72 C after restart, raise a work order and keep the station on watch. '
  || 'Step 4: record the stop cause, minutes lost and parts used in the line log.' AS CONTENT
FROM causes;

CREATE OR REPLACE CORTEX SEARCH SERVICE SEARCH.STATION_SOP_SEARCH
  ON CONTENT
  ATTRIBUTES CATEGORY, ROOT_CAUSE
  WAREHOUSE = __DEMO_WH__
  TARGET_LAG = '7 days'
AS (SELECT DOC_ID, TITLE, CATEGORY, ROOT_CAUSE, CONTENT FROM SEARCH.STATION_DOCS);

-- ---------- Station vibration anomaly detection (train first 75 days, detect last 15) ----------
CREATE OR REPLACE VIEW ML.VIBRATION_SERIES AS
SELECT ENTITY_ID, EVENT_DATE::TIMESTAMP_NTZ AS TS, VIBRATION_MM_S::FLOAT AS VIBRATION
FROM RAW.SENSOR_READINGS;
CREATE OR REPLACE VIEW ML.VIBRATION_TRAIN AS
SELECT * FROM ML.VIBRATION_SERIES WHERE TS < (SELECT DATEADD(day, -15, MAX(TS)) FROM ML.VIBRATION_SERIES);
CREATE OR REPLACE VIEW ML.VIBRATION_DETECT AS
SELECT * FROM ML.VIBRATION_SERIES WHERE TS >= (SELECT DATEADD(day, -15, MAX(TS)) FROM ML.VIBRATION_SERIES);

CREATE OR REPLACE SNOWFLAKE.ML.ANOMALY_DETECTION ML.VIBRATION_ANOMALY_MODEL(
  INPUT_DATA => SYSTEM$REFERENCE('VIEW', 'ML.VIBRATION_TRAIN'),
  SERIES_COLNAME => 'ENTITY_ID', TIMESTAMP_COLNAME => 'TS', TARGET_COLNAME => 'VIBRATION',
  LABEL_COLNAME => '');

CREATE OR REPLACE TABLE ML.VIBRATION_ANOMALIES AS
SELECT SERIES::VARCHAR AS ENTITY_ID, TS::DATE AS EVENT_DATE, Y AS VIBRATION, FORECAST AS EXPECTED,
       LOWER_BOUND, UPPER_BOUND, IS_ANOMALY, PERCENTILE
FROM TABLE(ML.VIBRATION_ANOMALY_MODEL!DETECT_ANOMALIES(
  INPUT_DATA => SYSTEM$REFERENCE('VIEW', 'ML.VIBRATION_DETECT'),
  SERIES_COLNAME => 'ENTITY_ID', TIMESTAMP_COLNAME => 'TS', TARGET_COLNAME => 'VIBRATION'));

-- ---------- Semantic view ----------
CREATE OR REPLACE SEMANTIC VIEW APP.ASSEMBLY_TWIN_ANALYTICS
  TABLES (
    stations AS CURATED.PERFORMANCE_SUMMARY PRIMARY KEY (ENTITY_ID)
      COMMENT = 'One row per assembly station, 90-day totals',
    risk AS ML.FAILURE_RISK_SCORES PRIMARY KEY (ENTITY_ID)
      COMMENT = 'Latest next-7-day unplanned-stop probability per station',
    causes AS CURATED.DOWNTIME_CAUSES PRIMARY KEY (ROOT_CAUSE)
      COMMENT = 'Stoppage hours by stop cause, 90 days',
    daily AS CURATED.TREND_ANALYSIS PRIMARY KEY (METRIC_DATE)
      COMMENT = 'Plant-network totals per day'
  )
  RELATIONSHIPS (risk_station AS risk (ENTITY_ID) REFERENCES stations)
  FACTS (
    stations.downtime_hours_f AS DOWNTIME_HOURS,
    stations.operating_hours_f AS OPERATING_HOURS,
    stations.planned_hours_f AS PLANNED_HOURS,
    stations.failures_f AS ALERT_COUNT,
    risk.failure_prob_f AS FAILURE_PROB_7D,
    causes.cause_hours_f AS DOWNTIME_HOURS,
    causes.cause_failures_f AS FAILURE_COUNT,
    daily.day_operating_f AS OPERATING_HOURS,
    daily.day_planned_f AS PLANNED_HOURS,
    daily.day_failures_f AS FAILURE_COUNT
  )
  DIMENSIONS (
    stations.station_id AS ENTITY_ID WITH SYNONYMS = ('station', 'workstation', 'entity', 'station id'),
    stations.station_name AS ENTITY_NAME,
    stations.region AS REGION COMMENT = 'Thai plant city',
    stations.station_type AS CATEGORY WITH SYNONYMS = ('station type', 'category'),
    risk.risk_band AS RISK_BAND COMMENT = 'High >= 0.5, Medium >= 0.25, else Low',
    risk.scored_as_of AS SCORED_AS_OF,
    causes.root_cause AS ROOT_CAUSE,
    daily.metric_date AS METRIC_DATE
  )
  METRICS (
    stations.station_count AS COUNT(stations.station_id) WITH SYNONYMS = ('number of stations', 'entities', 'station count'),
    stations.total_downtime_hours AS SUM(stations.downtime_hours_f),
    stations.unplanned_stops AS SUM(stations.failures_f) WITH SYNONYMS = ('line stops', 'stoppages'),
    stations.uptime_pct AS 100 * SUM(stations.operating_hours_f) / NULLIF(SUM(stations.planned_hours_f), 0)
      COMMENT = 'Operating hours / planned hours',
    stations.mtbf_hours AS SUM(stations.operating_hours_f) / NULLIF(SUM(stations.failures_f), 0)
      COMMENT = 'Mean operating hours between unplanned stops',
    risk.avg_failure_prob AS AVG(risk.failure_prob_f),
    causes.cause_downtime_hours AS SUM(causes.cause_hours_f),
    causes.cause_stops AS SUM(causes.cause_failures_f),
    daily.daily_uptime_pct AS 100 * SUM(daily.day_operating_f) / NULLIF(SUM(daily.day_planned_f), 0),
    daily.daily_stops AS SUM(daily.day_failures_f)
  )
  COMMENT = 'Synthetic Thai vehicle assembly line digital twin (demo)';

-- ---------- Cortex Agent ----------
CREATE OR REPLACE AGENT APP.ASSEMBLY_TWIN_AGENT
  COMMENT = 'Assembly line digital twin assistant over synthetic Thai assembly stations'
  FROM SPECIFICATION
$$
models:
  orchestration: claude-sonnet-4-5
instructions:
  response: "Answer only from tool results. State that data is synthetic. Give station IDs and numbers with units."
  orchestration: "Use twin_analyst for metrics, stations, line-stop risk and stop causes. Use sop_search for line-stop procedures."
tools:
  - tool_spec:
      type: cortex_analyst_text_to_sql
      name: twin_analyst
      description: "Assembly station stoppage hours, availability, MTBF, stops, stop causes and line-stop risk scores"
  - tool_spec:
      type: cortex_search
      name: sop_search
      description: "Synthetic line-stop SOPs by station type and stop cause"
tool_resources:
  twin_analyst:
    semantic_view: __DEMO_DB__.APP.ASSEMBLY_TWIN_ANALYTICS
    execution_environment:
      type: warehouse
      warehouse: __DEMO_WH__
  sop_search:
    name: __DEMO_DB__.SEARCH.STATION_SOP_SEARCH
    max_results: 3
    id_column: DOC_ID
    title_column: TITLE
$$;

-- ---------- Live-telemetry alert (IoT Core -> S3 -> Snowpipe) ----------
CREATE TABLE IF NOT EXISTS APP.ALERT_LOG (
  ALERTED_AT TIMESTAMP_LTZ DEFAULT CURRENT_TIMESTAMP(), STATION_ID VARCHAR,
  EVENT_TS TIMESTAMP_NTZ, VIBRATION_MM_S FLOAT, TEMPERATURE_C FLOAT, SOP_HINT VARCHAR);

CREATE OR REPLACE NOTIFICATION INTEGRATION TH_AUTOMOTIVE_ASSEMBLY_TWIN_EMAIL_INT
  TYPE = EMAIL ENABLED = TRUE ALLOWED_RECIPIENTS = ('__ALERT_EMAIL__');

CREATE OR REPLACE PROCEDURE APP.LOG_LIVE_ALARMS()
RETURNS NUMBER
LANGUAGE SQL
EXECUTE AS OWNER
AS
$$
DECLARE
  n NUMBER;
BEGIN
  INSERT INTO APP.ALERT_LOG (STATION_ID, EVENT_TS, VIBRATION_MM_S, TEMPERATURE_C, SOP_HINT)
    SELECT t.STATION_ID, t.EVENT_TS, t.VIBRATION_MM_S, t.TEMPERATURE_C,
           'Check ' || m.CATEGORY || ' SOPs; current risk band ' || COALESCE(r.RISK_BAND, 'n/a')
    FROM RAW.LIVE_TELEMETRY t
    JOIN RAW.STATIONS m ON m.ID = t.STATION_ID
    LEFT JOIN ML.FAILURE_RISK_SCORES r ON r.ENTITY_ID = t.STATION_ID
    WHERE t.STATUS = 'ALARM'
      AND NOT EXISTS (SELECT 1 FROM APP.ALERT_LOG l WHERE l.STATION_ID = t.STATION_ID AND l.EVENT_TS = t.EVENT_TS);
  n := SQLROWCOUNT;
  IF (n > 0) THEN
    CALL SYSTEM$SEND_EMAIL('TH_AUTOMOTIVE_ASSEMBLY_TWIN_EMAIL_INT', '__ALERT_EMAIL__',
      '[Demo] Thai assembly line live alarm',
      'New live-telemetry alarms logged in APP.ALERT_LOG: ' || :n || '. Data is synthetic.');
  END IF;
  RETURN n;
END;
$$;

CREATE OR REPLACE ALERT APP.LIVE_ALARM_ALERT
  WAREHOUSE = __DEMO_WH__
  SCHEDULE = '5 MINUTE'
  IF (EXISTS (
    SELECT 1 FROM RAW.LIVE_TELEMETRY t
    WHERE t.STATUS = 'ALARM'
      AND NOT EXISTS (SELECT 1 FROM APP.ALERT_LOG l WHERE l.STATION_ID = t.STATION_ID AND l.EVENT_TS = t.EVENT_TS)))
  THEN CALL APP.LOG_LIVE_ALARMS();

-- ---------- On-demand refresh DAG (suspended; run with EXECUTE TASK APP.TASK_REFRESH_CURATED) ----------
CREATE OR REPLACE PROCEDURE APP.REFRESH_CURATED()
RETURNS VARCHAR
LANGUAGE SQL
EXECUTE AS OWNER
AS
$$
BEGIN
  ALTER DYNAMIC TABLE CURATED.PERFORMANCE_SUMMARY REFRESH;
  ALTER DYNAMIC TABLE CURATED.TREND_ANALYSIS REFRESH;
  ALTER DYNAMIC TABLE CURATED.DOWNTIME_CAUSES REFRESH;
  ALTER DYNAMIC TABLE CURATED.KPI_SUMMARY REFRESH;
  RETURN 'refreshed';
END;
$$;

CREATE OR REPLACE TASK APP.TASK_REFRESH_CURATED
  WAREHOUSE = __DEMO_WH__
AS
  CALL APP.REFRESH_CURATED();

CREATE OR REPLACE TASK APP.TASK_RESCORE_RISK
  WAREHOUSE = __DEMO_WH__
  AFTER APP.TASK_REFRESH_CURATED
AS
  CREATE OR REPLACE TABLE ML.FAILURE_RISK_SCORES COPY GRANTS AS
  WITH latest AS (
    SELECT * FROM ML.FAILURE_FEATURES QUALIFY ROW_NUMBER() OVER (PARTITION BY ENTITY_ID ORDER BY EVENT_DATE DESC) = 1
  ), p AS (
    SELECT ENTITY_ID, EVENT_DATE,
           ML.FAILURE_RISK_MODEL!PREDICT(INPUT_DATA => OBJECT_CONSTRUCT(
             'CATEGORY', CATEGORY, 'AGE_YEARS', AGE_YEARS, 'VIBRATION_MM_S', VIBRATION_MM_S,
             'TEMPERATURE_C', TEMPERATURE_C, 'VIBRATION_7D', VIBRATION_7D, 'FAILURES_30D', FAILURES_30D)) AS PRED
    FROM latest
  )
  SELECT ENTITY_ID, EVENT_DATE AS SCORED_AS_OF, PRED:probability:FAIL::FLOAT AS FAILURE_PROB_7D,
         CASE WHEN PRED:probability:FAIL::FLOAT >= 0.5 THEN 'High'
              WHEN PRED:probability:FAIL::FLOAT >= 0.25 THEN 'Medium' ELSE 'Low' END AS RISK_BAND,
         CURRENT_TIMESTAMP() AS SCORED_AT
  FROM p;
