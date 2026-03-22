# Phoenix System — Shape Document

**Feature:** Full SaaS Platform Foundation
**Date:** 2026-03-22
**Status:** Approved for implementation

## Problem Statement
Build a production-grade multi-tenant SaaS platform from scratch that can serve multiple business verticals (CRM, POS, Finance, HRMS) with a modular, extensible architecture.

## Scope Decision
- **In scope:** Full platform as described in plan.md
- **Out of scope (for now):** Mobile apps, white-labeling, marketplace/plugin store

## Key Design Decisions

### 1. Shared DB Multi-tenancy (not separate DB per tenant)
- **Decision:** Single database, `tenant_id` on every table
- **Why:** Simpler operations, easier cross-tenant analytics for root, lower cost at scale
- **Trade-off:** Must be disciplined with global scopes — test tenant isolation rigorously

### 2. Modular Packages in `packages/Phoenix/*`
- **Decision:** Each domain as a Composer path package
- **Why:** Inspired by ncmstb (Krayin CRM) pattern; enables independent development, testing, and future open-sourcing
- **How:** Path repositories with symlinks; each package has its own ServiceProvider

### 3. Money as Integer Minor Units
- **Decision:** Store all monetary values as integers (e.g., KES 1500.00 → `150000`)
- **Why:** Eliminates float rounding errors in financial calculations
- **Library:** `brick/money` for all arithmetic

### 4. 5 Filament Panels
- **Decision:** Separate panels per access level, not role-based single panel
- **Why:** Clean UX per persona, different navigation/features per panel, easier to license-gate

### 5. No Stancl/Tenancy — Custom Tenant Middleware
- **Decision:** Build custom tenant resolution and scoping
- **Why:** More control, simpler shared-DB approach, avoid stancl's complexity for our pattern
- **Reference:** ekoapp pattern (businessid isolation) + intent pattern (Team model scoping)

## Reference Projects
- **intent** — Filament patterns, ModelHandler audit, CRM pipeline, Gym memberships
- **ekoapp** — Double-entry accounting, POS transaction flow, Chart of Accounts structure
- **ncmstb** — Modular package architecture, Repository pattern, CustomAttribute trait, event automation

## Standards to Apply
- `agent-os/standards/backend/multi-tenancy.md`
- `agent-os/standards/backend/modular-packages.md`
- `agent-os/standards/backend/licensing.md`
- `agent-os/standards/backend/audit-trail.md`
- `agent-os/standards/backend/access-control.md`
- `agent-os/standards/backend/finance-accounting.md`
- `agent-os/standards/filament/multi-panel.md`
- `agent-os/standards/filament/resources.md`
- `agent-os/standards/backend/laravel.md`
- `agent-os/standards/backend/eloquent.md`
