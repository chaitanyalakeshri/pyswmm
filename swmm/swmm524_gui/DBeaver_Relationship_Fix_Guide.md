# Fixing Relationship Lines in DBeaver for DuckDB

## Problem
DBeaver's diagram tab doesn't show relationship lines connecting tables, even though foreign keys are defined in the schema.

## Solution Steps

### Step 1: Refresh DBeaver Metadata
1. Close DBeaver (if the database is open)
2. Reopen DBeaver and connect to your DuckDB database
3. Right-click on your database connection in the Database Navigator
4. Select **Refresh** → **Refresh metadata cache**
5. Wait for the refresh to complete

### Step 2: Verify Foreign Keys Exist
Run the verification script to confirm foreign keys are properly stored:

```bash
duckdb.exe swmm5.db < verify_foreign_keys.sql
```

Or in DBeaver's SQL Editor, run:
```sql
SELECT 
    tc.table_name,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM 
    information_schema.table_constraints AS tc 
    JOIN information_schema.key_column_usage AS kcu
      ON tc.constraint_name = kcu.constraint_name
    JOIN information_schema.constraint_column_usage AS ccu
      ON ccu.constraint_name = tc.constraint_name
WHERE 
    tc.constraint_type = 'FOREIGN KEY'
ORDER BY 
    tc.table_name;
```

### Step 3: Create/Refresh ER Diagram
1. In DBeaver, right-click on your database connection
2. Select **View Diagram** → **Create New Diagram** (or open existing)
3. Add tables to the diagram (drag from Database Navigator or use "Add Tables" button)
4. Click **Arrange Diagram** to auto-arrange tables
5. The relationship lines should appear automatically if foreign keys are detected

### Step 4: Manual Relationship Creation (If Needed)
If relationship lines still don't appear automatically:

1. In the diagram view, click **Show Palette** (upper-left corner)
2. In the Palette panel, select **Connection**
3. Click on the child table (table with foreign key)
4. Click on the parent table (referenced table)
5. Double-click the parent table to finalize the connection
6. Repeat for all relationships

### Alternative: Use Custom Diagram
1. Create a new custom diagram: **View Diagram** → **Create New Diagram**
2. Manually add tables and create connections as described in Step 4
3. Save the diagram for future use

## Why This Happens
- DuckDB stores foreign keys differently than SQLite
- DBeaver may need explicit metadata refresh to detect DuckDB foreign keys
- The foreign keys ARE defined in the schema (68+ relationships), but DBeaver needs to read them from DuckDB's information_schema

## Verification
After refreshing, you should see relationship lines connecting:
- `subcatchments` → `raingages`, `snowpacks`, `patterns`
- `conduits` → `junctions` (inlet/outlet nodes)
- `pumps` → `junctions` (inlet/outlet nodes)
- `orifices` → `junctions` (inlet/outlet nodes)
- `weirs` → `junctions` (inlet/outlet nodes)
- `outlets` → `junctions` (inlet/outlet nodes)
- All curve data tables → their parent curve tables
- And many more relationships...

## Notes
- The schema defines 68+ foreign key relationships
- All relationships are properly normalized
- Foreign keys are stored in DuckDB's information_schema
- DBeaver should detect them after metadata refresh


