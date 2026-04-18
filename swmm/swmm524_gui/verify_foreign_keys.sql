-- ============================================================================
-- Foreign Key Verification Script for DuckDB
-- ============================================================================
-- This script verifies that foreign key constraints are properly defined
-- and can help DBeaver/DB Browser recognize relationships
-- ============================================================================

-- Query to check foreign key constraints
-- Note: DuckDB stores foreign keys in information_schema
SELECT 
    tc.table_name,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name,
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
ORDER BY 
    tc.table_name, kcu.column_name;

-- Alternative query using DuckDB's pragma (if available)
-- PRAGMA foreign_key_list('table_name'); -- This is SQLite syntax, may not work in DuckDB

-- Count foreign keys per table
SELECT 
    tc.table_name,
    COUNT(*) as foreign_key_count
FROM 
    information_schema.table_constraints AS tc
WHERE 
    tc.constraint_type = 'FOREIGN KEY'
    AND tc.table_schema = 'main'
GROUP BY 
    tc.table_name
ORDER BY 
    foreign_key_count DESC, tc.table_name;


