# Plan — Licensing UI (MVP)

**Revised:** 2026-03-23 — MVP restrategization. All Filament resources rewritten to v4 API with schema delegation. Future modules deferred to `agent-os/specs/ice.md`.

---

## MVP Scope

### Delivers
1. Public pages (landing, pricing, terms, privacy) + owner self-registration
2. Root panel: plan types, plans, subscriptions, invoices, addons, coupons, partners
3. Partner panel: managed owners, referred businesses, commissions + payout
4. Owner panel: business creation wizard, subscription status, invoice history
5. Money formatting helper

### Deferred to Ice
- Business panel UI (no modules built yet)
- Customer Portal panel
- CRM, POS, Inventory, Finance, HRMS, Reporting, Approval modules
- Payment gateway (Stripe / M-Pesa)
- PDF invoice generation
- Email/SMS billing notifications

---

## Filament v4 API Rules (Critical)

All resources use these patterns — any deviation will cause fatal errors:

| Rule | Correct |
|---|---|
| Form signature | `form(Schema $schema): Schema` |
| Section import | `use Filament\Schemas\Components\Section` |
| Schema children | `$schema->components([...])` |
| Action imports | `use Filament\Actions\EditAction` (all from `Filament\Actions\*`) |
| Resource row actions | `->recordActions([...])` |
| Resource bulk actions | `->groupedBulkActions([...])` |
| Relation manager row | `->actions([...])` |
| Relation manager bulk | `->bulkActions([...])` / `->headerActions([...])` |
| Nav icon type | `protected static string|\BackedEnum|null $navigationIcon` |
| Nav group type | `protected static string|\UnitEnum|null $navigationGroup` |
| Page `$view` | `protected string $view` (instance, NOT static) |

---

## Architecture

### Schema Delegation Pattern
Every resource is thin — form/table logic lives in separate classes:
```
ResourceName/
├── Pages/
├── RelationManagers/
├── Schemas/        ← SomeForm.php with static configure(Schema): Schema
└── Tables/         ← SomeTable.php with static configure(Table): Table
```

### Critical Files
| File | Purpose |
|---|---|
| `packages/Phoenix/Licensing/src/Models/*.php` | 13 Licensing models |
| `packages/Phoenix/Licensing/src/Services/LicenseManager.php` | Subscription lifecycle |
| `packages/Phoenix/Core/src/Helpers/Money.php` | `Money::format(int, string): string` |
| `app/Enums/AccessLevel.php` | `->panel()` per user type |
| `app/Enums/SubscriptionStatus.php` | `->color()`, `->label()`, `->isAccessible()` |
| `app/Enums/TenantType.php` | System / Partner / Owner / Business |
| `packages/Phoenix/Auth/src/Models/Tenant.php` | `hasActiveSubscription()`, `activeSubscription()` |

---

## Task Breakdown

### Task 1 — Spec documentation (done)
Updated this file, shape.md. Created ice.md.

### Task 2 — Root: License Plan Type + License Plan resources
**LicensePlanTypeResource** — thin + Schemas/LicensePlanTypeForm + Tables/LicensePlanTypesTable
- Form: name, license_type, description, is_active
- Table: name, license_type, is_active boolean, created_at

**LicensePlanResource** — thin + Schemas/LicensePlanForm + Tables/LicensePlansTable + LicensePlanLimitsRelationManager
- Form sections: Details (name, plan_type_id, billing_cycle), Pricing (base_price, currency, trial_days, grace_days), Visibility (is_public, is_active)
- Table: name, planType.name badge, billing_cycle, base_price (Money::format()), trial_days, is_active
- Limits relation manager: key, value, value_type — uses `->actions()` / `->headerActions()`

### Task 3 — Root: Subscription resource
**SubscriptionResource** — no create + Tables/SubscriptionsTable
- Table: tenant.name, plan.name, status badge, billing_cycle, starts_at, ends_at, partner.name
- Filters: status, billing_cycle, plan_id
- Row action: ChangeStatus (modal Select)
- `getEloquentQuery()` → `withoutGlobalScopes()`

### Task 4 — Root: Platform Invoice resource
**PlatformInvoiceResource** — list/view + Tables/InvoicesTable + PlatformPaymentsRelationManager
- Table: invoice_number, subscription.tenant.name, total_amount, status badge, due_at, paid_at
- Row actions: RecordPayment (modal), VoidInvoice (confirm)
- Payments relation manager inline

### Task 5 — Root: Addon + Coupon resources
**AddonResource** — CRUD + Schemas/AddonForm + Tables/AddonsTable + AddonLimitsRelationManager
**CouponResource** — CRUD + Schemas/CouponForm + Tables/CouponsTable

### Task 6 — Root: Partner resource
**PartnerResource** — CRUD + Schemas/PartnerForm + Tables/PartnersTable + PartnerUsersRelationManager
- Create: DB transaction → Tenant (type=partner) + User (access_level=partner)

### Task 7 — Partner panel resources
- ManagedOwnerResource, ReferredBusinessResource, CommissionResource
- All scoped to current user's partner tenant

### Task 8 — Owner panel pages
- ManageBusinessesPage + CreateBusiness wizard (3 steps)
- BusinessSubscriptionPage, InvoiceHistoryPage, ProfitLossWidget (placeholder)

### Task 9 — Verify public pages + registration
### Task 10 — Money helper wire-up

---

## Verification

1. `php artisan route:list` — no errors
2. `php artisan config:cache && php artisan route:cache` — no errors
3. `https://phoenix-sys.site/` → landing page with Vite CSS
4. `https://phoenix-sys.site/pricing` → plans from DB
5. Register as owner → redirected to `/owner`
6. `/root` as `root@phoenixsys.ke` → 7 resources in sidebar, all load
7. Root: create plan, edit limits relation manager
8. Root: change subscription status action
9. `/partner` → managed owners, commissions visible
10. Owner: create business wizard → trial subscription created
