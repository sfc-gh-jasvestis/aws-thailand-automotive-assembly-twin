-- ============================================================================
-- 05_SEARCH.SQL — Cortex Search for Assembly Line Digital Twin
-- ============================================================================
USE DATABASE ASSEMBLY_TWIN;
USE SCHEMA SEARCH;

CREATE OR REPLACE CORTEX SEARCH SERVICE SEARCH.MAINTENANCE_DOCS_SEARCH
  ON WORK_ORDER_NOTES
  ATTRIBUTES EQUIPMENT_TYPE, LINE_ID, PRIORITY
  WAREHOUSE = ASSEMBLY_WH
  TARGET_LAG = '1 hour'
AS (
  SELECT * FROM RAW.MAINTENANCE_RECORDS
);
