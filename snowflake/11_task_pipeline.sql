-- ============================================================================
-- 11_TASK_PIPELINE.SQL — Task DAG for Assembly Line Digital Twin
-- ============================================================================
USE DATABASE ASSEMBLY_TWIN;
USE SCHEMA APP;

CREATE OR REPLACE TASK APP.TASK_RETRAIN_MODELS
  WAREHOUSE = ASSEMBLY_WH
  SCHEDULE = 'USING CRON 0 */4 * * * UTC'
  COMMENT = 'Retrain predictive maintenance ML models'
AS
  SELECT 1; -- Replace with actual refresh logic

CREATE OR REPLACE TASK APP.TASK_REFRESH_HEALTH_SCORES
  WAREHOUSE = ASSEMBLY_WH
  AFTER APP.TASK_RETRAIN_MODELS
  COMMENT = 'Refresh equipment health scores'
AS
  SELECT 1; -- Replace with actual refresh logic

CREATE OR REPLACE TASK APP.TASK_SYNC_TWINMAKER
  WAREHOUSE = ASSEMBLY_WH
  AFTER APP.TASK_REFRESH_HEALTH_SCORES
  COMMENT = 'Sync digital twin state to IoT TwinMaker'
AS
  SELECT 1; -- Replace with actual refresh logic

ALTER TASK APP.TASK_SYNC_TWINMAKER RESUME;
ALTER TASK APP.TASK_REFRESH_HEALTH_SCORES RESUME;
ALTER TASK APP.TASK_RETRAIN_MODELS RESUME;
