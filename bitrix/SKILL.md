---
name: bitrix
description: >
  1C-Bitrix Site Management project onboarding, analysis, and development guide.
  Helps developers take over, understand, and direct existing Bitrix projects (online stores,
  corporate sites, portals). Covers all Bitrix systems: architecture, modules, components,
  infoblocks, e-commerce, security, deploy, and development workflow.
  Trigger on: bitrix, битрикс, 1с битрикс, онбординг битрикс, разработка битрикс,
  аудит битрикс, настройка битрикс, помощь с битрикс, как работает битрикс.
user-invokable: true
argument-hint: "<command> [path|topic]"
allowed-tools:
  - Read
  - Grep
  - Glob
  - Bash
  - WebFetch
  - Agent
  - Write
---

# 1C-Bitrix Skill — Главный оркестратор

Comprehensive skill for working with 1C-Bitrix Site Management projects. Handles onboarding,
full project audits, analysis of specific systems, and development guidance.

## Routing Table

| Command | Sub-skill | Description |
|---------|-----------|-------------|
| `/bitrix audit [path]` | `skills/bitrix-audit/SKILL.md` | Full project audit, 5 parallel agents |
| `/bitrix setup` | `skills/bitrix-setup/SKILL.md` | Dev environment, git workflow, license |
| `/bitrix modules [path]` | `skills/bitrix-modules/SKILL.md` | Module inventory, versions, deps |
| `/bitrix components [path]` | `skills/bitrix-components/SKILL.md` | Components in local/, overrides |
| `/bitrix db [path]` | `skills/bitrix-database/SKILL.md` | Infoblocks, ORM, custom tables |
| `/bitrix security [path]` | `skills/bitrix-security/SKILL.md` | Security audit |
| `/bitrix ecommerce [path]` | `skills/bitrix-ecommerce/SKILL.md` | Catalog, orders, payment, 1C sync |
| `/bitrix deploy` | `skills/bitrix-deploy/SKILL.md` | Deploy workflow dev→staging→prod |
| `/bitrix explain <topic>` | inline (use references/) | Explain any Bitrix concept |
| `/bitrix onboard` | inline (use references/) | Full onboarding checklist |

## Inline Commands (handled directly, no sub-skill needed)

### `/bitrix explain <topic>`

Load the relevant reference file and explain the concept clearly:

| Topic keywords | Reference file |
|----------------|---------------|
| d7, orm, legacy, архитектура, компоненты, модули, события, кеш | `references/architecture.md` |
| модуль, iblock, sale, catalog, crm, search | `references/modules-catalog.md` |
| сервер, php, mysql, nginx, redis, docker, требования | `references/server-requirements.md` |
| инфоблок, товары, sku, заказ, оплата, доставка, 1с | `references/ecommerce-systems.md` |

If topic unclear, load `references/architecture.md` as starting point.

### `/bitrix onboard`

Guide the user through the complete onboarding process. Load `references/onboarding-checklist.md`
and present it phase by phase, asking the user to confirm each phase before moving to the next.

Format:
```
## Onboarding: Phase 1 of 5 — First Day

[checklist items for Phase 1]

✅ Ready to start Phase 2? (reply "да" or ask questions about Phase 1)
```

## Industry Detection

Auto-detect project type from provided path or URL context:
- `b_sale_order` table, `sale` module → Online Store
- `b_crm_*` tables → CRM/Bitrix24
- Only content infoblocks, no catalog → Corporate site / Portal
- Multiple sites in one Bitrix installation → Multi-site project

## Progressive Disclosure

Always load reference files on-demand, not upfront:
- Metadata (SKILL.md header): always loaded
- Sub-skill instructions: loaded on routing
- Reference files: loaded only when relevant to current command

## Error Handling

| Scenario | Response |
|----------|---------|
| No path provided for audit/modules/etc | Ask user for Bitrix root path |
| Command not recognized | Show available commands table |
| Non-Bitrix project at path | Confirm project type, offer help |
| User asks general Bitrix question | Use `/bitrix explain` inline flow |
| User says "помоги с битрикс" (no command) | Ask: audit existing project or explain concept? |

## Bitrix Health Score Summary

When running a full audit, calculate and display:

```
🏥 Bitrix Health Score: [N]/100

  Code Structure    ████████░░  [N]%  (weight 20%)
  Security          ██████████  [N]%  (weight 20%)
  Core Freshness    ███████░░░  [N]%  (weight 15%)
  E-commerce        ████████░░  [N]%  (weight 20%)
  Data Model        █████████░  [N]%  (weight 10%)
  Git & Deploy      ████████░░  (weight 10%)
  Performance       █████████░  (weight  5%)
```

Thresholds:
- **85–100** 🟢 Excellent
- **65–84** 🟡 Good — some improvements needed
- **45–64** 🟠 Fair — significant technical debt
- **0–44** 🔴 Critical — requires immediate attention

## Quick Reference Card

When user asks "что делать в первую очередь" (what to do first):

1. Run `/bitrix audit /path/to/project` for full assessment
2. Fix all 🔴 Critical security issues first
3. Understand infoblock structure (`/bitrix db`)
4. Set up local dev environment (`/bitrix setup`)
5. Follow onboarding checklist (`/bitrix onboard`)
