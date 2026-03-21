---
name: bitrix-components
description: >
  Analyzes 1C-Bitrix custom components in local/ directory. Maps component usage,
  identifies Legacy vs D7 API, finds template overrides, and assesses code quality.
  Trigger on: bitrix components, компоненты битрикс, анализ компонентов.
user-invokable: true
argument-hint: "[path-to-bitrix-root]"
allowed-tools:
  - Read
  - Grep
  - Glob
  - Bash
---

# Bitrix Components Analysis

Analyzes custom components and template overrides in a 1C-Bitrix project.

## Bitrix Component Architecture (context)

```
Component = Controller (component.php) + View (templates/*/template.php)

Types:
1. Custom component     → /local/components/vendor.name/
2. Template override    → /local/templates/<site>/components/bitrix/<name>/.default/
3. Modified standard    → /bitrix/components/bitrix/<name>/ [RED FLAG - in ядре]
```

## Analysis Process

### 1. Find all custom components

```bash
# Custom components in local/
find /var/www/html/local/components/ -name "component.php" 2>/dev/null

# Template overrides in site template
find /var/www/html/local/templates/ -name "template.php" -path "*/components/*" 2>/dev/null

# Potentially modified standard components (BAD PRACTICE)
find /var/www/html/bitrix/components/ -newer /var/www/html/bitrix/modules/main/install/version.php \
  -name "*.php" 2>/dev/null | head -20
```

### 2. For each custom component, analyze

```bash
# Read component.php
cat /var/www/html/local/components/VENDOR/NAME/component.php

# Check API style
grep -c "Bitrix\\\\\|DataManager\|new \\\\" component.php  # D7 signs
grep -c "CIBlock::\|CSale::\|CUser::\|CModule::" component.php  # Legacy signs

# Check caching
grep -c "startResultCache\|endResultCache\|initComponentTemplate" component.php

# List templates
ls /var/www/html/local/components/VENDOR/NAME/templates/
```

### 3. Catalog-related components (critical for shop)

```bash
# Find catalog display components
find /var/www/html/local/ -name "component.php" | xargs grep -l "iblock\|catalog\|IBLOCK_ID" 2>/dev/null

# Find checkout/order components
find /var/www/html/local/ -name "component.php" | xargs grep -l "sale\|basket\|order\|checkout" 2>/dev/null
```

### 4. Template overrides analysis

```bash
# What standard components are overridden?
find /var/www/html/local/templates/ -path "*/components/bitrix/*" -name "template.php" | \
  sed 's|.*/components/bitrix/||' | sed 's|/.*||' | sort | uniq
```

### 5. Component parameter files

```bash
# .parameters.php declares configurable params (iblock IDs etc.)
find /var/www/html/local/components/ -name ".parameters.php" 2>/dev/null | while read f; do
  echo "=== $f ==="
  cat "$f"
done
```

### 6. JavaScript and CSS in components

```bash
# Find components with non-minified JS (performance issue)
find /var/www/html/local/components/ -name "*.js" ! -name "*.min.js" 2>/dev/null

# Find inline styles in templates (anti-pattern)
grep -rn "style=\"" /var/www/html/local/components/ --include="template.php" -l 2>/dev/null
```

## Output Format

```
# Bitrix Components Analysis

## Summary
- Custom components: [N]
- Template overrides of standard components: [N]
- Standard components modified directly: [N] [🔴 if > 0]

## Custom Components
### [vendor.component-name]
- **Location**: /local/components/vendor/name/
- **Purpose**: [inferred from code]
- **API style**: D7 / Legacy / Mixed ([D7 count]D7 / [Legacy count] Legacy calls)
- **Caching**: Enabled / Disabled / Unknown
- **Templates**: [list of template variants]
- **Issues**: [list or none]

## Template Overrides (Standard Components)
### bitrix:[component-name]
- **Override location**: /local/templates/.../
- **Reason**: [inferred — style customization / logic fix / feature add]

## Standard Components Modified Directly 🔴
[List with file paths — these will be OVERWRITTEN on Bitrix update]
[For each: recommended migration path to local/ override]

## Code Quality

### API Style Distribution
- D7 API usage: [N]% of component files
- Legacy API usage: [N]% of component files
- Files needing D7 migration: [list]

### Caching
- Components with result_cache: [N]
- Components without caching: [list] ← potential performance issue

### Catalog/Shop Components
- Product listing: [component path]
- Product detail: [component path]
- Cart: [component path]
- Checkout: [component path]
- Order list: [component path]

## Issues
🔴 Modified standard components (will break on update): [list]
🔴 Legacy API in checkout flow: [list]
🟡 Missing caching in heavy components: [list]
🟡 Hardcoded IDs in component.php: [list]
🟢 Well-structured D7 components: [list]

## Recommendations
1. [Migrate X component from Legacy to D7]
2. [Move Y from bitrix/ to local/ override]
3. [Add caching to Z component]
```
