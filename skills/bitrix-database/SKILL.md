---
name: bitrix-database
description: >
  Analyzes 1C-Bitrix infoblock structure, database schema, ORM entities, and data model.
  Maps all infoblocks, finds custom tables, checks ORM usage, and data integrity.
  Trigger on: bitrix db, битрикс база данных, инфоблоки битрикс, структура данных.
user-invokable: true
argument-hint: "[path-to-bitrix-root]"
allowed-tools:
  - Read
  - Grep
  - Glob
  - Bash
---

# Bitrix Database & Infoblock Analysis

Analyzes the data model of a 1C-Bitrix project including infoblocks, ORM entities, and custom database structures.

## Understanding Bitrix Data Model

```
Infoblock (IBlock)
├── Type → groups related infoblocks (e.g., "catalog", "content", "services")
├── Section → hierarchical categories (b_iblock_section table)
├── Element → actual records/items (b_iblock_element table)
│   └── Properties → custom fields (b_iblock_element_property / b_iblock_property_s*)
└── Settings → active status, sort, display settings

For catalog:
  Infoblock "Products" (type=catalog)
  └── Links to Infoblock "Offers/SKU" (type=catalog, OFFERS=Y)
      └── Each SKU has its own price (b_catalog_price) and stock (b_catalog_store_product)
```

## Analysis Process

### 1. Map IBLOCK_IDs from code

```bash
# Find all IBLOCK_ID references in custom code
grep -rn "IBLOCK_ID\s*[=\>]\s*[0-9]" /var/www/html/local/ --include="*.php" | \
  grep -o "IBLOCK_ID.*[0-9]\+" | sort | uniq -c | sort -rn | head -30

# Find defined constants
grep -rn "define.*IBLOCK\|IBLOCK.*=\s*[0-9]\+" /var/www/html/local/php_interface/init.php 2>/dev/null

# Find in component parameters
grep -rn "IBLOCK_ID\|OFFERS_IBLOCK_ID" \
  /var/www/html/local/ --include=".parameters.php" 2>/dev/null
```

### 2. Find all ORM DataManager entities

```bash
# Find all DataManager extensions
grep -rn "extends DataManager\|extends \\\Bitrix\\\Main\\\ORM\\\Data\\\DataManager" \
  /var/www/html/local/ --include="*.php" -l

# For each found file, extract class name and table
grep -rn "class \|getTableName\|getMap" \
  /var/www/html/local/modules/ --include="*.php" | grep -A2 "extends DataManager"
```

### 3. Find custom SQL tables

```bash
# Find SQL install files
find /var/www/html/local/modules/ -path "*/db/mysql/install.sql" 2>/dev/null

# Find CREATE TABLE statements
grep -rn "CREATE TABLE" /var/www/html/local/modules/ --include="*.sql" 2>/dev/null

# Find raw SQL queries (potential issues)
grep -rn "\\\$DB->Query\|mysqli_query\|mysql_query" \
  /var/www/html/local/ --include="*.php" | head -20
```

### 4. Cache configuration

```bash
# Read .settings.php for cache backend
cat /var/www/html/bitrix/.settings.php 2>/dev/null | grep -A 10 "'cache'"
cat /var/www/html/local/.settings.php 2>/dev/null | grep -A 10 "'cache'"
```

### 5. Check for N+1 query patterns

```bash
# Find GetList inside loops (common performance anti-pattern)
grep -rn "GetList\|getList" /var/www/html/local/ --include="component.php" | head -20
# Manual review needed — check if these are inside while/foreach loops
```

### 6. Infoblock properties analysis

```bash
# Find property-heavy code (many properties = complex queries)
grep -rn "PROPERTY_\|arResult\[.PROPERTIES.\]" \
  /var/www/html/local/ --include="template.php" | wc -l
```

## Output Format

```
# Bitrix Database & Infoblock Analysis

## Infoblock Map
| ID | Name (inferred) | Type | Purpose |
|----|----------------|------|---------|
[table of all found iblock IDs with context]

### Catalog Structure
- Products Iblock: ID=[N], Name=[inferred]
- SKU/Offers Iblock: ID=[N] or NOT FOUND (no SKU variants)
- Category depth: [shallow/deep — inferred from section usage]

## ORM Entities (D7 DataManager)
| Class | Table | Module | Fields |
[table]

## Custom Database Tables
| Table name | Purpose | Has ORM? | Migration needed? |
[table]

## Data Access Patterns
- D7 ORM usage: [N occurrences]
- Legacy GetList: [N occurrences]
- Direct SQL queries: [N occurrences] [🔴 if > 0]
- Raw mysqli/mysql: [N occurrences] [🔴 if > 0]

## Cache Configuration
- Backend: [Redis / Memcache / Filesystem (default)]
- Session: [Redis / DB / Files]

## Issues
🔴 Direct SQL queries: [file:line list]
🔴 Hardcoded IBLOCK_IDs (not constants): [list]
🟡 Legacy GetList in heavy pages: [list]
🟡 Missing cache tags on DB writes: [list]
🟢 Proper ORM usage: [examples]

## Recommendations
1. [Define IBLOCK_IDs as constants in init.php]
2. [Migrate X from raw SQL to ORM]
3. [Add Redis cache backend for managed cache]
```
