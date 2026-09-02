-- Generated from generator/demo_specs/aws-thailand-automotive-assembly-twin.json
-- Regenerate with: python3 generator/gen_repo_docs.py aws-thailand-automotive-assembly-twin
-- This is the schema that is actually deployed for THAILAND_AUTOMOTIVE_ASSEMBLY_TWIN.

-- THAILAND_AUTOMOTIVE_ASSEMBLY_TWIN  (Assembly Line Digital Twin)
-- generated from generator/demo_specs/aws-thailand-automotive-assembly-twin.json - do not hand-edit
CREATE DATABASE IF NOT EXISTS THAILAND_AUTOMOTIVE_ASSEMBLY_TWIN;
CREATE SCHEMA IF NOT EXISTS THAILAND_AUTOMOTIVE_ASSEMBLY_TWIN.RAW;
CREATE SCHEMA IF NOT EXISTS THAILAND_AUTOMOTIVE_ASSEMBLY_TWIN.CURATED;
CREATE SCHEMA IF NOT EXISTS THAILAND_AUTOMOTIVE_ASSEMBLY_TWIN.APP;
USE DATABASE THAILAND_AUTOMOTIVE_ASSEMBLY_TWIN;

-- 5 real regions; entity names carry their region so the two always agree
