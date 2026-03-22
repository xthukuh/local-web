# Phoenix System — Master Project Plan

**Project:** Phoenix System (phoenix-sys)
**Company:** Phoenix Software Company
**Domain:** phoenixsys.ke
**Type:** Multi-tenant SaaS Platform
**Status:** In Progress
**Started:** 2026-03-22

---

## Architecture Summary

### Tech Stack
- Laravel 12.x + PHP 8.2+
- Filament v5.x (5 panels)
- Laravel Passport (OAuth2 API)
- MySQL 8.x (shared DB, tenant_id scoping)
- Redis (cache, queues, sessions)
- Laravel Boost (dev, AI context)
- Pest PHP (testing)

### Modular Package Structure
```
packages/Phoenix/
├── Core/         Foundation, base classes, traits
├── Platform/     Settings, metadata, permissions, menus, notifications
├── Auth/         Authentication, users, roles, tenancy resolution
├── Licensing/    Plans, subscriptions, addons, billing lifecycle
├── CRM/          Accounts, contacts, leads, opportunities, quotes
├── POS/          Products, orders, payments, receipts
├── Inventory/    Stock, warehouses, stock movements
├── Finance/      Invoices, expenses, accounts, double-entry accounting
├── HRMS/         Employees, departments, attendance, leave, payroll
├── Reporting/    Report engine, templates, exports
└── Approval/     Approval workflows, multi-step approvals
```

### Access Level Hierarchy
```
root           → system administrator
partner        → reseller/agent (manages owners, earns commission)
owner          → business owner (manages businesses, billed)
business       → business entity
business-user  → staff/operators within a business
business-admin → can configure business settings
business-customer → self-service portal access only
```

### Filament Panels
| Panel | Path | For |
|-------|------|-----|
| Root | `/root` | System administrators |
| Partner | `/partner` | Resellers / agents |
| Owner | `/owner` | Business owners |
| Business | `/` | Business staff (default) |
| Customer Portal | `/portal` | End-customers |

---

## Phase 1 — Foundation ✅ CURRENT

**Goal:** Project scaffold, tenancy, auth, licensing, base panels

### Milestone 1.1 — Project Scaffold
- [x] Create Laravel project: `composer create-project laravel/laravel phoenix-sys`
- [ ] Install core dependencies (Filament v5, Passport, Spatie packages)
- [ ] Configure Docker vhost for phoenix-sys.local
- [ ] Initialize Git repository
- [ ] Run `php artisan boost:install` (generates CLAUDE.md, .mcp.json, boost.json)
- [ ] Register Laravel Boost MCP: `claude mcp add laravel-boost -- php artisan boost:mcp`
- [ ] Create `packages/` directory and set up composer path repositories
- [ ] Initialize all 11 package directories with composer.json and ServiceProviders

### Milestone 1.2 — Database Foundation
- [ ] Design and create migrations for Platform tables:
  - `tenants` (id, uuid, parent_id, type, name, slug, code, email, phone, country, currency, timezone, status, metadata, timestamps, softDeletes)
  - `users` (id, uuid, tenant_id, name, email, password, access_level, email_verified_at, is_active, last_login_at, timestamps, softDeletes)
  - `tenant_user` pivot
- [ ] Design and create Licensing migrations:
  - `license_plan_types`, `license_plans`, `license_plan_limits`
  - `addons`, `addon_limits`
  - `subscriptions`, `subscription_addons`, `subscription_usages`
  - `platform_invoices`, `platform_invoice_items`, `platform_payments`
  - `commissions`, `coupons`
- [ ] Seed: system tenant, root user, default license plans (Launch, Growth, Scale)

### Milestone 1.3 — Multi-Tenancy Engine
- [ ] `BelongsToTenant` trait with global scope
- [ ] `TenantScope` class
- [ ] `ResolveTenant` middleware (subdomain + route-prefix resolver)
- [ ] `EnsureActiveSubscription` middleware
- [ ] `CheckFeatureAccess` middleware

### Milestone 1.4 — Authentication & RBAC
- [ ] User model with `access_level` enum
- [ ] spatie/laravel-permission: define roles + permissions per module
- [ ] Auth guards per panel
- [ ] `EnsureCorrectPanel` middleware

### Milestone 1.5 — Filament Panels (base)
- [ ] RootPanelProvider (route: /root)
- [ ] PartnerPanelProvider (route: /partner)
- [ ] OwnerPanelProvider (route: /owner)
- [ ] BusinessPanelProvider (route: /, default)
- [ ] CustomerPortalProvider (route: /portal)
- [ ] Base navigation groups per panel

### Milestone 1.6 — Core Package (Phoenix/Core)
- [ ] `HasAuditTrail` trait (created_by, updated_by, deleted_by)
- [ ] `ModelHandler` global event listener
- [ ] `LicenseManager` service
- [ ] `AuditLog` service
- [ ] Base ServiceProvider
- [ ] Money value object helpers (brick/money wrapper)
- [ ] `CurrencyService` (conversion, rate snapshots)

### Milestone 1.7 — Licensing Module (Phoenix/Licensing)
- [ ] Models: LicensePlanType, LicensePlan, LicensePlanLimit, Addon, AddonLimit
- [ ] Models: Subscription, SubscriptionAddon, SubscriptionUsage
- [ ] Models: PlatformInvoice, PlatformPayment, Commission, Coupon
- [ ] `LicenseManager` service with limit checking
- [ ] Filament Root resources: LicensePlanResource, SubscriptionResource, etc.
- [ ] Billing jobs: CheckTrialEndingJob, GenerateRenewalInvoiceJob, SuspendAfterGraceJob
- [ ] Events: SubscriptionCreated, SubscriptionUpgraded, InvoicePaid, etc.

### Milestone 1.8 — Platform Package (Phoenix/Platform)
- [ ] Settings system (spatie/laravel-settings per tenant)
- [ ] Permissions (spatie/laravel-permission)
- [ ] Notification templates (email, SMS, in-app)
- [ ] Filament Root: SystemSettingsPage, TenantResource, UserResource

### Milestone 1.9 — API Foundation
- [ ] Laravel Passport install and configure
- [ ] API v1 routes structure (`routes/api/v1/`)
- [ ] Base API authentication endpoints (register, login, refresh, logout)
- [ ] API response envelope middleware
- [ ] OpenAPI/Swagger setup for `/api/v1/docs`

---

## Phase 2 — Business Modules

### Milestone 2.1 — CRM Module (Phoenix/CRM)
- [ ] Models: Account, Contact, Lead, Opportunity, Quote, QuoteLineItem, Activity
- [ ] Lead pipeline stages (configurable)
- [ ] State machines: Lead status, Opportunity status, Quote status
- [ ] Polymorphic Address, Note, Comment
- [ ] Filament Business resources: AccountResource, ContactResource, LeadResource, OpportunityResource, QuoteResource
- [ ] API: CRUD endpoints for CRM entities

### Milestone 2.2 — POS Module (Phoenix/POS)
- [ ] Models: Product, Category, Brand, Order, OrderItem, Receipt, Payment
- [ ] Multi-currency pricing
- [ ] Stock deduction on order
- [ ] POS screen (Livewire + Filament Action)
- [ ] Receipt generation (DOMPDF)
- [ ] Filament Business resources: OrderResource, ProductResource

### Milestone 2.3 — Inventory Module (Phoenix/Inventory)
- [ ] Models: Warehouse, StockLocation, StockMovement, StockTake
- [ ] Stock tracking: purchases, sales, adjustments, transfers
- [ ] Low stock alerts
- [ ] Filament resources: WarehouseResource, StockMovementResource

### Milestone 2.4 — Finance Module (Phoenix/Finance)
- [ ] Models: ChartOfAccounts, AccountGroup, BusinessInvoice, Bill, Expense, CashAccount, Transaction, JournalEntry
- [ ] Double-entry bookkeeping engine (JournalService)
- [ ] Transaction types: Sale, Purchase, Expense, Transfer, Capital, Revenue, Drawings
- [ ] Reports: Trial Balance, Income Statement, Balance Sheet, Account Statement
- [ ] Filament resources: InvoiceResource, ExpenseResource, CashAccountResource

### Milestone 2.5 — Multi-Currency
- [ ] `currencies` and `exchange_rates` tables
- [ ] `CurrencyService` with rate fetching (API) and manual override
- [ ] Money stored as integer minor units throughout
- [ ] Business base currency setting
- [ ] Price books per currency

### Milestone 2.6 — HRMS Module (Phoenix/HRMS)
- [ ] Models: Employee, Department, Designation, Attendance, Leave, LeaveType, Payroll
- [ ] Leave request workflow
- [ ] Attendance tracking
- [ ] Basic payroll calculation
- [ ] Filament resources: EmployeeResource, AttendanceResource, LeaveResource

---

## Phase 3 — Advanced Features

### Milestone 3.1 — Approval Engine (Phoenix/Approval)
- [ ] Configurable approval workflow templates
- [ ] Multi-step approval chains
- [ ] Approval states: pending, approved, rejected, escalated
- [ ] Notification per step
- [ ] Attach to: PO, Leave, Expense, Quote

### Milestone 3.2 — Reporting Engine (Phoenix/Reporting)
- [ ] Report template builder
- [ ] Dynamic filters and date ranges
- [ ] Export: PDF (DOMPDF), Excel (Maatwebsite)
- [ ] Scheduled reports via email
- [ ] Dashboard widgets per module

### Milestone 3.3 — Customer Self-Service Portal
- [ ] Customer registration/login
- [ ] View invoices and pay online
- [ ] Service bookings
- [ ] Support tickets
- [ ] Loyalty points
- [ ] Filament Portal panel with CustomerPanelProvider

### Milestone 3.4 — Notification System
- [ ] Email notifications (SMTP/SES)
- [ ] SMS notifications (configurable gateway)
- [ ] In-app notifications (Filament database notifications)
- [ ] Broadcast (Laravel Echo + Pusher/Soketi)

### Milestone 3.5 — API Documentation
- [ ] OpenAPI 3.0 spec generation
- [ ] Interactive Swagger UI at `/api/v1/docs`
- [ ] Auth flows documented
- [ ] All module endpoints documented

---

## Phase 4 — Polish & Launch

### Milestone 4.1 — Billing UI
- [ ] Stripe integration via Laravel Cashier
- [ ] Subscription checkout flow
- [ ] Addon purchase
- [ ] Payment history
- [ ] PDF invoice download

### Milestone 4.2 — CI/CD
- [ ] GitHub Actions: test, lint (Pint), static analysis (PHPStan)
- [ ] Docker production config
- [ ] Zero-downtime deployment script
- [ ] Database backup automation

### Milestone 4.3 — Security & Performance
- [ ] Security audit (OWASP Top 10)
- [ ] Rate limiting per plan tier
- [ ] Query optimization + DB indexes review
- [ ] Redis caching for expensive queries
- [ ] Telescope / Pulse monitoring

---

## Timeline (16 Weeks)

| Week | Milestone | Output |
|------|-----------|--------|
| 1 | Project Scaffold + Docker | Running phoenix-sys.local |
| 2 | DB Foundation + Migrations | All core tables |
| 3 | Tenancy Engine + Auth | Tenant middleware, RBAC |
| 4 | Filament Panels (base) + Licensing | 5 panels running, license CRUD |
| 5 | Core Package + Platform | Settings, audit, LicenseManager |
| 6 | CRM Module | Full CRM CRUD + API |
| 7 | POS Module | POS screen, orders, receipts |
| 8 | Inventory Module | Stock tracking |
| 9 | Finance Module | Accounting engine, reports |
| 10 | Multi-Currency | Exchange rates, conversions |
| 11 | HRMS Module | HR basics |
| 12 | Approval Engine | Workflow builder |
| 13 | Reporting Engine | Dynamic reports |
| 14 | Customer Portal | Self-service UI |
| 15 | Billing UI + Stripe | Subscription checkout |
| 16 | CI/CD + Security | Production-ready |
