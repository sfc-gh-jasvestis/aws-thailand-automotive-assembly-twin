-- ============================================================================
-- 01_MARKETPLACE_INSTALL.SQL — Install marketplace data for Assembly Line Digital Twin
-- ============================================================================
USE DATABASE ASSEMBLY_TWIN;
USE SCHEMA RAW;

-- Free listings to install from Snowflake Marketplace:
-- Install: Snowflake Public Data (Free)
--   https://app.snowflake.com/marketplace/listing/GZTSZ290BV255

-- Paid listing (mock): CEIC ASEAN Macro
--   Real data: https://app.snowflake.com/marketplace/listing/GZTSZRC7HPI
--   Using mock table: THAI_AUTO_PRODUCTION
CREATE TABLE IF NOT EXISTS RAW.THAI_AUTO_PRODUCTION (
  ID INT AUTOINCREMENT, DATA VARIANT, LOADED_AT TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
);

