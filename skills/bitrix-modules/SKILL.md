---
name: bitrix-modules
description: >
  Analyzes 1C-Bitrix installed modules. Inventories standard and custom modules,
  checks versions, maps dependencies, finds outdated or unused modules.
  Trigger on: bitrix modules, модули битрикс, какие модули установлены.
user-invokable: true
argument-hint: "[path-to-bitrix-root]"
allowed-tools:
  - Read
  - Grep
  - Glob
  - Bash
---

# Bitrix Modules Analysis

Performs deep analysis of all installed modules in a 1C-Bitrix project.

## Analysis Process

### 1. Detect project root

If path not provided, attempt: `/var/www/html`, `/var/www/bitrix`, current directory.

Verify: `ls <path>/bitrix/modules/` should list module directories.

### 2. Inventory all modules

```bash
# Standard modules
ls /var/www/html/bitrix/modules/ | sort

# Custom modules
ls /var/www/html/local/modules/ 2>/dev/null | sort

# Get version for each module
for mod in /var/www/html/bitrix/modules/*/; do
  modname=$(basename "$mod")
  version=$(grep -o "'[0-9.]*'" "$mod/install/version.php" 2>/dev/null | head -1 | tr -d "'")
  echo "$modname: $version"
done
```

### 3. E-commerce module validation

Critical modules for an online store. Check each is present and active:

| Module | Required | Purpose |
|--------|----------|---------|
| `iblock` | ★ Mandatory | Content model foundation |
| `catalog` | ★ Mandatory | Product catalog, prices, stock |
| `sale` | ★ Mandatory | Orders, cart, checkout |
| `currency` | ★ Mandatory | Currency management |
| `security` | Strongly recommended | Proactive security |
| `seo` | Recommended | Sitemap, robots.txt |
| `search` | Recommended | Site search |
| `subscribe` | Optional | Email marketing |
| `blog` | Optional | Blog/news |

### 4. Custom modules deep analysis

For each module in `/local/modules/`:

```bash
# Read include.php (event subscriptions, autoloader)
cat /var/www/html/local/modules/MODNAME/include.php

# Read install/index.php (setup/teardown)
cat /var/www/html/local/modules/MODNAME/install/index.php

# List lib/ classes
ls /var/www/html/local/modules/MODNAME/lib/ 2>/dev/null

# Check API style (D7 vs Legacy)
grep -rn "extends DataManager\|Bitrix\\\\Main\\\\" \
  /var/www/html/local/modules/MODNAME/lib/ --include="*.php" | wc -l
```

### 5. Module dependency mapping

```bash
# Find all module include calls
grep -rn "CModule::IncludeModule\|Loader::includeModule" \
  /var/www/html/local/ --include="*.php" | \
  sed "s/.*IncludeModule('\([^']*\)').*/\1/g" | sort | uniq -c | sort -rn
```

### 6. Third-party marketplace modules

Modules not matching standard Bitrix naming (bitrix.*, main, iblock, sale, etc.) are marketplace/custom:
```bash
ls /var/www/html/bitrix/modules/ | grep -v "^bitrix\." | grep "\."
```

## Output Format

```
# Bitrix Modules Analysis Report

## Summary
- Bitrix Core: [version]
- Standard modules installed: [N]
- Custom modules (local/): [N]
- Marketplace modules: [N]

## E-commerce Modules Status
| Module | Present | Version | Status |
[table with ✅/❌/⚠️]

## All Standard Modules
[grouped by category: core, e-commerce, communication, marketing, infrastructure]

## Custom Modules
### [module-name]
- **Purpose**: [inferred from code]
- **API Style**: D7 / Legacy / Mixed
- **Events registered**: [list]
- **Tables**: [custom DB tables if any]

## Marketplace Modules
| Module | Version | Purpose |
[table]

## Dependency Map
[tree showing which modules depend on what]

## Issues
🔴 Missing critical module: [name]
🔴 Severely outdated: [module@version, current: version]
🟡 Outdated: [list]
🟡 Potentially unused: [list]
🟢 Up to date: [count]

## Recommendations
1. [Install missing module X — required for Y]
2. [Update module X from vA to vB]
3. [Remove unused module X to reduce attack surface]
```

## Error Handling

| Scenario | Action |
|----------|--------|
| `/bitrix/modules/` not found | Not a Bitrix project or wrong path |
| Module has no version.php | Note as unknown version |
| `/local/modules/` doesn't exist | No custom modules — normal for simple projects |
