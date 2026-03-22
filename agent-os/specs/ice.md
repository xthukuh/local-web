# Ice — Future Modules & Improvements

Deferred from MVP. Architecture accommodates all of these via the modular package structure in `packages/Phoenix/*`. Each module gets its own ServiceProvider, models, migrations, and Filament resources registered into the appropriate panels.

---

## Business Modules

| Module | Package | Panel | Notes |
|---|---|---|---|
| CRM | `packages/Phoenix/CRM` | Business (`/`) | Contacts, leads, pipeline, deals, tasks, notes |
| POS | `packages/Phoenix/POS` | Business (`/`) | Products, orders, receipts, MPesa integration |
| Inventory | `packages/Phoenix/Inventory` | Business (`/`) | Stock management, warehouses, stock movements |
| Finance | `packages/Phoenix/Finance` | Business (`/`) + Owner | Double-entry GL, journals, P&L, balance sheet |
| HRMS | `packages/Phoenix/HRMS` | Business (`/`) | Employees, payroll, leave management, payslips |
| Reporting | `packages/Phoenix/Reporting` | Business + Owner | Scheduled reports, export (CSV/PDF), dashboards |
| Approval | `packages/Phoenix/Approval` | Business (`/`) | Multi-step approval engine for any model |

---

## Platform Improvements

### Payment Gateways
- **Stripe** integration for card payments (subscriptions + invoices)
- **MPesa Daraja** for Kenya mobile money (STK Push)
- **Manual bank transfer** already supports via PlatformPayment model
- Integration point: `PlatformInvoice` → `PlatformPayment` (provider, reference, amount)

### PDF Invoices
- Generate PDF via DomPDF or Browsershot
- Triggered from Owner panel InvoiceHistoryPage download action
- Template: `resources/views/pdf/invoice.blade.php`

### Email / SMS Notifications
- Trial expiry warning (7 days, 3 days, 1 day before)
- Subscription renewal confirmation
- Payment received confirmation
- Suspension warning (past due → grace period)
- Integration: `packages/Phoenix/Core/src/Notifications/`

### Business Panel UI
- `app/Filament/Business/` — currently empty scaffold
- Bootstrap with dashboard widget showing plan usage
- Each module registers its own resources/pages into Business panel via ServiceProvider

### Customer Portal
- `app/Filament/Portal/` — currently empty scaffold
- B2C panel for business customers (e.g., viewing their own orders/invoices)
- Requires CRM or POS module to be meaningful

---

## Architectural Notes

- **Module registration**: Each package ServiceProvider calls `Filament::serving()` to register resources into the Business panel
- **Feature gating**: `LicenseManager::hasFeature()` and `checkLimit()` gate module access per subscription plan
- **Multi-currency**: All monetary values stored as integer minor units; `Money::format()` handles display
- **Approval engine**: Generic — any model can be wired to require approval workflows via `packages/Phoenix/Approval`
- **Reporting engine**: Should pull from other modules via registered data providers (interface in Core)
- **Finance module**: When built, `ProfitLossWidget` in Owner panel should read from Finance journals grouped by account type

---

## Foundation Architecture (already in place)

These exist and are ready for modules to use:

- `BelongsToTenant` trait + `TenantScope` global scope — tenant isolation
- `HasAuditTrail` trait — automatic audit log for any model
- `LicenseManager::checkLimit()` — usage enforcement
- `packages/Phoenix/Auth/src/Models/Tenant.php` — `parent_id` for business hierarchy
- `app/Enums/TenantType.php` — System / Partner / Owner / Business
- `app/Enums/AccessLevel.php` — 7 user levels mapped to 5 panels
