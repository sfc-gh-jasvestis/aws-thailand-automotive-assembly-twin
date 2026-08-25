-- ============================================================================
-- 09_AWS_INTEGRATION.SQL — AWS services for Assembly Line Digital Twin
-- Account: <YOUR_AWS_ACCOUNT_ID> | Region: ap-southeast-1
-- Skip this script for Snowflake-only build
-- ============================================================================
USE DATABASE ASSEMBLY_TWIN;
USE SCHEMA APP;

-- ==================== AMAZON SNS ====================
CREATE OR REPLACE NETWORK RULE APP.SNS_NETWORK_RULE
  MODE = EGRESS
  TYPE = HOST_PORT
  VALUE_LIST = ('sns.ap-southeast-1.amazonaws.com:443');

CREATE OR REPLACE EXTERNAL ACCESS INTEGRATION aws_thailand_automotive_assembly_twin_SNS_EAI
  ALLOWED_NETWORK_RULES = (ASSEMBLY_TWIN.APP.SNS_NETWORK_RULE)
  ALLOWED_AUTHENTICATION_SECRETS = (ASSEMBLY_TWIN.APP.AWS_BEDROCK_SECRET)
  ENABLED = TRUE
  COMMENT = 'SNS access for Assembly Line Digital Twin alerts';

-- SNS Topic ARN: arn:aws:sns:ap-southeast-1:<YOUR_AWS_ACCOUNT_ID>:sea-demos-aws-thailand-automotive-assembly-twin

-- ==================== KINESIS / IOT CORE INGESTION ====================
-- Snowpipe from Kinesis Data Stream
-- Stream ARN: arn:aws:kinesis:ap-southeast-1:<YOUR_AWS_ACCOUNT_ID>:stream/aws-thailand-automotive-assembly-twin-stream

CREATE OR REPLACE PIPE RAW.REALTIME_PIPE
  AUTO_INGEST = TRUE
  INTEGRATION = 'aws_thailand_automotive_assembly_twin_S3_INT'
  COMMENT = 'Auto-ingest from Kinesis via S3 delivery stream'
AS
COPY INTO RAW.ASSEMBLY_LINES
FROM @RAW.LANDING_STAGE/realtime/
FILE_FORMAT = (TYPE = 'JSON');

