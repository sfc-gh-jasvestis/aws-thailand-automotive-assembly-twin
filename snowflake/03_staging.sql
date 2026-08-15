-- ============================================================================
-- 03_STAGING.SQL — Generate synthetic data for Assembly Line Digital Twin
-- Country: THAILAND | Currency: THB
-- ============================================================================
USE DATABASE ASSEMBLY_TWIN;
USE SCHEMA RAW;

-- Data generation scripts are demo-specific.
-- See the handcrafted SQL in the aws-malaysia-semiconductor-yield demo for
-- the full pattern: GENERATOR + UNIFORM + LATERAL for distribution,
-- Cortex Complete for text generation, engineered key demo numbers.

-- Target row counts:
-- ASSEMBLY_LINES: 8 rows — Assembly lines across 3 plants (body, paint, trim, final)
-- STATIONS: 240 rows — Work stations with robot and equipment details
-- EQUIPMENT_TELEMETRY: 750,000 rows — IoT sensor data (vibration, temperature, current, cycle time)
-- PRODUCTION_EVENTS: 45,000 rows — Production start/stop/downtime events with reason codes
-- MAINTENANCE_RECORDS: 5,000 rows — Work orders, PM schedules, breakdown history
-- TWINMAKER_SCENES: 8 rows — IoT TwinMaker scene metadata for 3D visualization
-- SPARE_PARTS_INVENTORY: 1,200 rows — Critical spare parts stock levels and lead times
-- THAI_AUTO_PRODUCTION: 12 rows — Thailand automotive production statistics
