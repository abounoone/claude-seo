---
name: bitrix-audit
description: >
  Full 1C-Bitrix project audit. Spawns 5 parallel agents to analyze codebase structure,
  installed modules, database/infoblocks, security, and e-commerce configuration.
  Outputs BITRIX-AUDIT-REPORT.md and BITRIX-ACTION-PLAN.md. Trigger on: bitrix audit,
  аудит битрикс, проверить проект битрикс.
user-invokable: true
argument-hint: "<path-to-bitrix-root>"
allowed-tools:
  - Read
  - Grep
  - Glob
  - Bash
  - Agent
  - Write
---

# Bitrix Full Project Audit

Performs a comprehensive audit of a 1C-Bitrix Site Management project by running 5 specialist agents in parallel, then synthesizing results into a unified report with actionable priorities.

## Pre-flight Checks

1. Verify the provided path exists and is a Bitrix project:
   ```bash
   ls <path>/bitrix/modules/main/install/version.php
   ```
2. If path not provided, attempt auto-detection: `/var/www/html`, `/var/www/bitrix`, `/home/*/public_html`
3. Read Bitrix version and edition before launching agents

## Parallel Agents (launch simultaneously)

Launch all 5 agents at the same time via Agent tool with `context: fork`:

| Agent | File | Focus |
|-------|------|-------|
| Codebase | `agents/bitrix-codebase.md` | File structure, templates, local/, init.php |
| Modules | `agents/bitrix-modules-agent.md` | Installed modules, versions, custom modules |
| Database | `agents/bitrix-database-agent.md` | Infoblocks, ORM entities, custom tables |
| Security | `agents/bitrix-security-agent.md` | Permissions, .htaccess, exposed secrets |
| E-commerce | `agents/bitrix-ecommerce-agent.md` | Catalog, orders, payment, delivery, 1C |

Pass the project root path to each agent as context.

## Bitrix Health Score Calculation

After all agents complete, calculate the weighted score:

| Category | Weight | Agent Source |
|----------|--------|-------------|
| Code Structure (local/ discipline) | 20% | bitrix-codebase |
| Security | 20% | bitrix-security |
| Core Freshness (version, updates) | 15% | bitrix-modules |
| E-commerce Configuration | 20% | bitrix-ecommerce |
| Data Model (infoblocks, ORM) | 10% | bitrix-database |
| Git & Deploy Hygiene | 10% | bitrix-codebase |
| Performance (caching config) | 5% | bitrix-database |

Score thresholds:
- **85–100** 🟢 Excellent — project is well-maintained
- **65–84** 🟡 Good — some improvements needed
- **45–64** 🟠 Fair — significant technical debt
- **0–44** 🔴 Critical — requires immediate attention

## Output Files

### BITRIX-AUDIT-REPORT.md

Structure:
```markdown
# Bitrix Project Audit Report
Generated: [date]
Project: [path]
Bitrix Version: [version] | Edition: [edition]

## 🏥 Bitrix Health Score: [N]/100

| Category | Score | Weight | Weighted |
[score table]

## Executive Summary
[2-3 sentences describing overall project health]

## 1. Codebase Structure
[findings from bitrix-codebase agent]

## 2. Modules Inventory
[findings from bitrix-modules agent]

## 3. Database & Infoblocks
[findings from bitrix-database agent]

## 4. Security Audit
[findings from bitrix-security agent]

## 5. E-commerce Configuration
[findings from bitrix-ecommerce agent]

## 6. Critical Issues Summary
[all 🔴 issues from all agents in one list]
```

### BITRIX-ACTION-PLAN.md

Structure:
```markdown
# Bitrix Action Plan
[Project path] | Generated: [date]

## 🔴 Immediate (fix within 24 hours)
[Security critical, broken e-commerce, data loss risks]

## 🟡 Short-term (fix within 1 week)
[Code quality, outdated modules, performance]

## 🟢 Roadmap (plan for next sprint)
[Architecture improvements, D7 migration, dev workflow]

## Development Workflow Recommendations
[git, deploy, local dev environment]
```

## Error Handling

| Scenario | Action |
|----------|--------|
| Path not found | Ask user to provide correct Bitrix root path |
| No `bitrix/` directory | Confirm this is actually a Bitrix project |
| No read permissions | Report and skip that section |
| No `local/` directory | Note as finding (all code may be in bitrix/ — critical) |
| Empty project | Report minimal structure, suggest onboarding guide |
