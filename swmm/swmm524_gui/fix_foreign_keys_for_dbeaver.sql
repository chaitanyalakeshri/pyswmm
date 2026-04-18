-- ============================================================================
-- Script to help DBeaver recognize foreign key relationships
-- ============================================================================
-- This script adds explicit constraint names to foreign keys
-- which can help database viewers like DBeaver recognize relationships
-- ============================================================================
-- 
-- NOTE: DuckDB doesn't support ALTER TABLE to add named constraints
-- after table creation, so this is primarily for reference.
-- 
-- The foreign keys ARE already defined in the schema, but DBeaver might
-- need a metadata refresh to see them.
-- ============================================================================

-- First, let's verify foreign keys exist
SELECT 
    'Foreign Keys Found: ' || COUNT(*)::VARCHAR as status
FROM 
    information_schema.table_constraints
WHERE 
    constraint_type = 'FOREIGN KEY'
    AND table_schema = 'main';

-- List all foreign key relationships
SELECT 
    tc.table_name as child_table,
    kcu.column_name as child_column,
    ccu.table_name as parent_table,
    ccu.column_name as parent_column,
    tc.constraint_name
FROM 
    information_schema.table_constraints AS tc 
    JOIN information_schema.key_column_usage AS kcu
      ON tc.constraint_name = kcu.constraint_name
      AND tc.table_schema = kcu.table_schema
    JOIN information_schema.constraint_column_usage AS ccu
      ON ccu.constraint_name = tc.constraint_name
      AND ccu.table_schema = tc.table_schema
WHERE 
    tc.constraint_type = 'FOREIGN KEY'
    AND tc.table_schema = 'main'
ORDER BY 
    tc.table_name, kcu.column_name;


