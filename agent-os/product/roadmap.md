# Roadmap

## Phase 1 — Foundation (Weeks 1–4)
- Laravel 12.x project scaffold with modular package structure (`packages/Phoenix/*`)
- Multi-tenancy engine (shared DB, tenant_id scoping, middleware)
- Access level hierarchy: Root → Partner → Owner → Business → Business-User → Business-Customer
- Licensing engine: plans, limits, addons, subscriptions, billing lifecycle
- Filament panels: Root, Partner, Owner, Business, Customer Portal
- Laravel Passport OAuth2 API foundation
- Core platform: Settings, Metadata, Permissions, Audit Log

## Phase 2 — Business Modules (Weeks 5–8)
- CRM: Accounts, Contacts, Leads, Opportunities, Quotes, Activities
- POS: Products, Inventory, Orders, Payments, Receipts
- Finance: Invoices, Bills, Expenses, Payments, Cash Accounts
- Accounting: Chart of Accounts, Double-entry Journal, Reports
- Multi-currency: Exchange rates, auto-conversion, Money value objects
- HRMS: Employees, Departments, Attendance, Leave, Payroll basics

## Phase 3 — Advanced Features (Weeks 9–12)
- Approval Engine: configurable workflows, multi-step approvals
- Reporting Engine: dynamic reports, export (PDF/Excel), dashboards
- Customer Self-Service Portal: invoices, bookings, loyalty, support
- Notification system: email, SMS, in-app (broadcast)
- API documentation: OpenAPI via `/api/v1/docs`
- Mobile app API readiness

## Phase 4 — Polish & Launch (Weeks 13–16)
- Subscription billing UI (Stripe/manual payment)
- Partner commission system
- CI/CD pipeline (GitHub Actions)
- Performance optimization, caching
- Security audit
- Production Docker deployment config
