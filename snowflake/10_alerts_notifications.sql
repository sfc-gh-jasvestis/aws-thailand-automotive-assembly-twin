-- ============================================================================
-- 10_ALERTS_NOTIFICATIONS.SQL — Alerts for Assembly Line Digital Twin
-- ============================================================================
USE DATABASE ASSEMBLY_TWIN;
USE SCHEMA APP;

-- Notification integration (email)
CREATE OR REPLACE NOTIFICATION INTEGRATION aws_thailand_automotive_assembly_twin_EMAIL_INT
  TYPE = EMAIL
  ENABLED = TRUE
  ALLOWED_RECIPIENTS = ('jonathan.asvestis@snowflake.com');

-- Alert: OEE_CRITICAL_ALERT
CREATE OR REPLACE ALERT APP.OEE_CRITICAL_ALERT
  WAREHOUSE = ASSEMBLY_WH
  SCHEDULE = '5 MINUTE'
  COMMENT = 'Assembly line OEE below critical threshold'
IF (EXISTS (
  SELECT 1 FROM CURATED.LINE_OEE_REALTIME
  WHERE 1=1 -- Condition: OEE < 65% for any assembly line
))
THEN
  CALL SYSTEM$SEND_EMAIL(
    'aws_thailand_automotive_assembly_twin_EMAIL_INT',
    'jonathan.asvestis@snowflake.com',
    '[ALERT] Assembly Line Digital Twin: Assembly line OEE below critical threshold',
    'Assembly line OEE below critical threshold'
  );

ALTER ALERT APP.OEE_CRITICAL_ALERT RESUME;

-- Alert: VIBRATION_ANOMALY_ALERT
CREATE OR REPLACE ALERT APP.VIBRATION_ANOMALY_ALERT
  WAREHOUSE = ASSEMBLY_WH
  SCHEDULE = '5 MINUTE'
  COMMENT = 'Equipment vibration anomaly detected'
IF (EXISTS (
  SELECT 1 FROM CURATED.LINE_OEE_REALTIME
  WHERE 1=1 -- Condition: VIBRATION_RMS > 3σ for any station
))
THEN
  CALL SYSTEM$SEND_EMAIL(
    'aws_thailand_automotive_assembly_twin_EMAIL_INT',
    'jonathan.asvestis@snowflake.com',
    '[ALERT] Assembly Line Digital Twin: Equipment vibration anomaly detected',
    'Equipment vibration anomaly detected'
  );

ALTER ALERT APP.VIBRATION_ANOMALY_ALERT RESUME;

