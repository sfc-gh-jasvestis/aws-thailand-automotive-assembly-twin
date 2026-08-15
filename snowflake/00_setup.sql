-- ============================================================================
-- Assembly Line Digital Twin
-- Digital twin of 8 automotive assembly lines across Thailand's Eastern Seaboard — IoT TwinMaker syncs with Snowflake ML to predict downtime, detect anomalies, and visualize real-time production in a React Canvas.
-- ============================================================================
USE ROLE ACCOUNTADMIN;
CREATE DATABASE IF NOT EXISTS ASSEMBLY_TWIN;
CREATE WAREHOUSE IF NOT EXISTS ASSEMBLY_WH WAREHOUSE_SIZE = 'MEDIUM' AUTO_SUSPEND = 120 AUTO_RESUME = TRUE;
USE DATABASE ASSEMBLY_TWIN;
CREATE SCHEMA IF NOT EXISTS RAW;
CREATE SCHEMA IF NOT EXISTS CURATED;
CREATE SCHEMA IF NOT EXISTS ML;
CREATE SCHEMA IF NOT EXISTS AI;
CREATE SCHEMA IF NOT EXISTS SEARCH;
CREATE SCHEMA IF NOT EXISTS APP;

USE WAREHOUSE ASSEMBLY_WH;
