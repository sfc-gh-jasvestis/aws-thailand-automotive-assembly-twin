-- ============================================================================
-- 08_AGENT.SQL — Cortex Agent for Assembly Line Digital Twin
-- ============================================================================
USE DATABASE ASSEMBLY_TWIN;
USE SCHEMA APP;

CREATE OR REPLACE CORTEX AGENT APP.ASSEMBLY_TWIN_AGENT
  COMMENT = 'Assembly Line Digital Twin AI Assistant'
  MODEL = 'claude-opus-4-8'
  TOOLS = (
    SEMANTIC_VIEW_TOOL(SEMANTIC_VIEW => 'ASSEMBLY_TWIN.APP.ASSEMBLY_ANALYTICS'),    CORTEX_SEARCH_TOOL(CORTEX_SEARCH_SERVICE => 'ASSEMBLY_TWIN.SEARCH.MAINTENANCE_DOCS_SEARCH', TOOL_DESCRIPTION => 'Search documents for Automotive Manufacturing information')
  )
  SYSTEM_PROMPT = 'You are the Assembly Line Digital Twin Agent for 8 automotive assembly lines across Thailand''s Eastern Seaboard.';
