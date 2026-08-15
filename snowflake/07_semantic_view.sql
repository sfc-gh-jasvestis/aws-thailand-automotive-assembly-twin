-- ============================================================================
-- 07_SEMANTIC_VIEW.SQL — Semantic View for Assembly Line Digital Twin
-- ============================================================================
USE DATABASE ASSEMBLY_TWIN;
USE SCHEMA APP;

CREATE OR REPLACE SEMANTIC VIEW APP.ASSEMBLY_ANALYTICS
  COMMENT = 'Assembly line OEE, downtime, and equipment health analytics'
AS
  TABLES (
    CURATED.LINE_OEE_REALTIME AS line_oee_realtime,CURATED.EQUIPMENT_HEALTH_SCORE AS equipment_health_score,CURATED.DOWNTIME_COST AS downtime_cost,CURATED.VIBRATION_TIMESERIES AS vibration_timeseries
  );
