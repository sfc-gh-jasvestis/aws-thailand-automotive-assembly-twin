-- Synthetic station-day observations for the digital twin of a fictional
-- Thai vehicle assembler; no seeded predictions or invented station counts.
-- Randomness is HASH-seeded so every rebuild is reproducible yet varied:
-- per-station reliability and age, shift patterns, wear between planned
-- maintenance, missed PM, variable restoration times, station-type-weighted
-- stop causes and two plant-wide power dips.
USE DATABASE IDENTIFIER($DEMO_DB);
USE SCHEMA RAW;
USE WAREHOUSE IDENTIFIER($DEMO_WH);

CREATE TABLE RAW.STATIONS AS
WITH station_seq AS (
  SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) - 1 AS STATION_INDEX
  FROM TABLE(GENERATOR(ROWCOUNT => 24))
), draws AS (
  SELECT STATION_INDEX,
         MOD(ABS(HASH(STATION_INDEX, 'thaat-twin-plantcity')), 1000000) / 1e6 AS U_REGION,
         MOD(ABS(HASH(STATION_INDEX, 'thaat-twin-sttype')), 1000000) / 1e6 AS U_CATEGORY,
         MOD(ABS(HASH(STATION_INDEX, 'thaat-twin-age')), 1000000) / 1e6 AS U_AGE,
         MOD(ABS(HASH(STATION_INDEX, 'thaat-twin-rate')), 1000000) / 1e6 AS U_RATE,
         MOD(ABS(HASH(STATION_INDEX, 'thaat-twin-shift')), 1000000) / 1e6 AS U_SHIFT,
         MOD(ABS(HASH(STATION_INDEX, 'thaat-twin-pm')), 1000000) / 1e6 AS U_PM,
         MOD(ABS(HASH(STATION_INDEX, 'thaat-twin-discipline')), 1000000) / 1e6 AS U_DISCIPLINE
  FROM station_seq
)
SELECT 'STN-' || LPAD(STATION_INDEX::VARCHAR, 4, '0') AS ID,
       'Synthetic station ' || LPAD(STATION_INDEX::VARCHAR, 4, '0') AS NAME,
       CASE WHEN U_REGION < 0.24 THEN 'Rayong' WHEN U_REGION < 0.42 THEN 'Chonburi'
            WHEN U_REGION < 0.58 THEN 'Chachoengsao' WHEN U_REGION < 0.74 THEN 'Ayutthaya'
            WHEN U_REGION < 0.88 THEN 'Samut Prakan' ELSE 'Prachinburi' END AS REGION,
       CASE WHEN U_CATEGORY < 0.30 THEN 'Body Weld Cell' WHEN U_CATEGORY < 0.52 THEN 'Paint Booth'
            WHEN U_CATEGORY < 0.80 THEN 'Trim and Chassis Station' ELSE 'End-of-Line Test Cell' END AS CATEGORY,
       STATION_INDEX,
       ROUND(1 + U_AGE * 12, 1) AS AGE_YEARS,
       -- Base daily stop probability 0.3%-4.8% (skewed); ~12% of stations are chronic stoppers (x3).
       (0.003 + U_RATE * U_RATE * 0.045) * IFF(U_RATE > 0.88, 3, 1) AS BASE_FAILURE_RATE,
       IFF(U_SHIFT < 0.60, 20, 16) AS SHIFT_HOURS,
       7 * (1 + FLOOR(U_PM * 3)) AS PM_INTERVAL_DAYS,
       0.52 + U_DISCIPLINE * 0.46 AS PM_COMPLETION_PROB,
       'Active' AS STATUS
FROM draws;

CREATE TABLE RAW.SENSOR_READINGS AS
WITH days AS (
  SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) - 1 AS DAY_INDEX
  FROM TABLE(GENERATOR(ROWCOUNT => 90))
), outages AS (
  -- Two plant-wide power dips in the window.
  SELECT * FROM VALUES (23, 'Ayutthaya', 3.0), (61, 'Chonburi', 2.5) AS o(DAY_INDEX, REGION, HOURS)
), base AS (
  SELECT m.ID AS ENTITY_ID, m.STATION_INDEX, m.CATEGORY, m.REGION, m.AGE_YEARS,
         m.BASE_FAILURE_RATE, m.PM_INTERVAL_DAYS, m.PM_COMPLETION_PROB, d.DAY_INDEX,
         DATEADD('day', d.DAY_INDEX - 89, CURRENT_DATE()) AS EVENT_DATE,
         IFF(MOD(d.DAY_INDEX, 7) = 6, 8.0, m.SHIFT_HOURS) AS PLANNED_HOURS,
         MOD(d.DAY_INDEX + m.STATION_INDEX * 5, m.PM_INTERVAL_DAYS) AS DAYS_SINCE_PM,
         MOD(ABS(HASH(m.ID, d.DAY_INDEX, 'thaat-twin-stop')), 1000000) / 1e6 AS U_FAIL,
         MOD(ABS(HASH(m.ID, d.DAY_INDEX, 'thaat-twin-restore')), 1000000) / 1e6 + 1e-6 AS U_RESTORE,
         MOD(ABS(HASH(m.ID, d.DAY_INDEX, 'thaat-twin-cause')), 1000000) / 1e6 AS U_CAUSE,
         MOD(ABS(HASH(m.ID, d.DAY_INDEX, 'thaat-twin-pmdone')), 1000000) / 1e6 AS U_PMDONE,
         MOD(ABS(HASH(m.ID, d.DAY_INDEX, 'thaat-twin-jobs')), 1000000) / 1e6 AS U_UNITS,
         MOD(ABS(HASH(m.ID, d.DAY_INDEX, 'thaat-twin-noise')), 1000000) / 1e6 AS U_NOISE,
         o.HOURS AS OUTAGE_HOURS
  FROM RAW.STATIONS m CROSS JOIN days d
  LEFT JOIN outages o ON o.DAY_INDEX = d.DAY_INDEX AND o.REGION = m.REGION
), pm AS (
  SELECT *,
         IFF(DAYS_SINCE_PM = 0, 1, 0) AS PM_DUE,
         IFF(DAYS_SINCE_PM = 0 AND U_PMDONE < PM_COMPLETION_PROB, 1, 0) AS PM_COMPLETED,
         -- Wear rises between visits; weak PM discipline adds carried-over wear.
         DAYS_SINCE_PM / PM_INTERVAL_DAYS + (1 - PM_COMPLETION_PROB) AS WEAR,
         -- A hot, humid stretch (day index 30-74) stresses paint booth air handling.
         IFF(CATEGORY = 'Paint Booth' AND DAY_INDEX BETWEEN 30 AND 74, 1.40, 1.0) AS HEAT_FACTOR
  FROM base
), failures AS (
  SELECT *,
         LEAST(0.6, BASE_FAILURE_RATE * (0.4 + 1.6 * WEAR) * (1 + AGE_YEARS / 25) * HEAT_FACTOR) AS P_FAIL
  FROM pm
), events AS (
  SELECT *,
         CASE WHEN OUTAGE_HOURS IS NOT NULL THEN 1
              WHEN U_FAIL < P_FAIL / 4 THEN 2
              WHEN U_FAIL < P_FAIL THEN 1 ELSE 0 END AS FAILURE_COUNT
  FROM failures
), timed AS (
  SELECT *,
         -- Exponential restoration durations; mean depends on station type.
         CASE WHEN FAILURE_COUNT = 0 THEN 0.0
              WHEN OUTAGE_HOURS IS NOT NULL THEN OUTAGE_HOURS
              ELSE LEAST(PLANNED_HOURS - 0.5, ROUND(FAILURE_COUNT * (0.4 - LN(U_RESTORE) *
                     CASE CATEGORY WHEN 'Paint Booth' THEN 3.5 WHEN 'Body Weld Cell' THEN 2.5
                                   WHEN 'Trim and Chassis Station' THEN 1.5 ELSE 2.0 END), 1)) END AS DOWNTIME_HOURS
  FROM events
)
SELECT ENTITY_ID || '-' || TO_CHAR(EVENT_DATE, 'YYYYMMDD') AS EVENT_ID,
       ENTITY_ID, EVENT_DATE, PLANNED_HOURS, DOWNTIME_HOURS,
       PLANNED_HOURS - DOWNTIME_HOURS AS OPERATING_HOURS,
       FAILURE_COUNT,
       CASE WHEN FAILURE_COUNT = 0 THEN 'None'
            WHEN OUTAGE_HOURS IS NOT NULL THEN 'Plant power dip'
            WHEN CATEGORY = 'Body Weld Cell' THEN IFF(U_CAUSE < 0.45, 'Weld tip wear', IFF(U_CAUSE < 0.8, 'Robot servo fault', 'Fixture clamp fault'))
            WHEN CATEGORY = 'Paint Booth' THEN IFF(U_CAUSE < 0.5, 'Booth airflow imbalance', IFF(U_CAUSE < 0.8, 'Atomizer bell fault', 'Conveyor chain wear'))
            WHEN CATEGORY = 'Trim and Chassis Station' THEN IFF(U_CAUSE < 0.55, 'Torque tool fault', IFF(U_CAUSE < 0.85, 'AGV guidance fault', 'Lift assist fault'))
            ELSE IFF(U_CAUSE < 0.5, 'Roller dyno fault', IFF(U_CAUSE < 0.8, 'Alignment rig drift', 'Vision camera fault')) END AS ROOT_CAUSE,
       PM_DUE, PM_COMPLETED,
       ROUND(OPERATING_HOURS * (24 + U_UNITS * 24)) AS TOTAL_UNITS,
       FLOOR(ROUND(OPERATING_HOURS * (24 + U_UNITS * 24)) *
             LEAST(0.995, GREATEST(0.84, 0.986 - 0.032 * WEAR - 0.028 * FAILURE_COUNT - 0.012 * U_NOISE))) AS GOOD_UNITS,
       100.0 * (PLANNED_HOURS - DOWNTIME_HOURS) / PLANNED_HOURS AS KPI_STATION_AVAILABILITY,
       ROUND(1.6 + 4.4 * WEAR + 1.5 * FAILURE_COUNT + U_NOISE * 0.7, 2) AS VIBRATION_MM_S,
       ROUND(44 + 8 * WEAR + IFF(HEAT_FACTOR > 1, 7, 0) + U_NOISE * 3, 1) AS TEMPERATURE_C,
       CURRENT_TIMESTAMP() AS LOADED_AT
FROM timed;

CREATE TABLE RAW.SPARE_PARTS AS
SELECT ID AS ENTITY_ID,
       CASE CATEGORY WHEN 'Body Weld Cell' THEN 'Weld tip and dresser kit' WHEN 'Paint Booth' THEN 'Atomizer bell cup set'
                     WHEN 'Trim and Chassis Station' THEN 'Torque tool transducer' ELSE 'Dyno roller bearing kit' END AS PART_TYPE,
       1 + MOD(ABS(HASH(ID, 'thaat-twin-req')), 4) AS REQUIRED_QTY,
       MOD(ABS(HASH(ID, 'thaat-twin-hand')), 5) AS ON_HAND_QTY,
       IFF(MOD(ABS(HASH(ID, 'thaat-twin-hand')), 5) < 1 + MOD(ABS(HASH(ID, 'thaat-twin-req')), 4),
           MOD(ABS(HASH(ID, 'thaat-twin-order')), 3), 0) AS ON_ORDER_QTY,
       CURRENT_DATE() AS SNAPSHOT_DATE
FROM RAW.STATIONS;
