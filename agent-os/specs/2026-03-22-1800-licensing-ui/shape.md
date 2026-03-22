# Shape — Licensing UI

**Shaped:** 2026-03-22
**Feature:** Licensing UI across Root, Partner, Owner panels + public pages

---

## Problem

The licensing data layer (models, migrations, LicenseManager service) exists but nothing is exposed to users. Admins can't manage plans, owners can't sign up or create businesses, and partners have no visibility into commissions.

## Scope

### In scope
- Public marketing pages: landing, pricing, terms, privacy
- Owner self-registration (name/email/password)
- Business creation wizard in Owner panel (details + plan selection → trial subscription)
- Root panel: full CRUD for plans, subscriptions, invoices, addons, coupons, partners
- Partner panel: manage owners, view referred businesses, commissions, payout requests
- Owner panel: billing pages per business (subscription status, invoices, upgrade/cancel)
- Money formatting helper (minor units → display string)

### Out of scope
- Stripe/payment gateway integration (manual payments only for now)
- PDF invoice generation (placeholder link)
- Finance module P&L (widget shows placeholder until Finance module built)
- SMS/email notification templates (wired but templates TBD)

---

## Key Decisions

| Decision | Choice | Reason |
|---|---|---|
| Billing unit | Business tenant | Each business has its own plan and feature set independent of other businesses under same owner |
| Owner signup | Name + email + password only | Keep friction low; business details captured during first business creation |
| Plan selection timing | During business creation wizard | Plan determines feature access for that specific business |
| Grace period | 15 days hardcoded | Standard renewal window; configurable in future via system settings |
| Partner creation | Root admin only | Partners are vetted resellers, not self-service |
| Partner → Owner scope | Partner scoped to their portfolio | `partner_id` on Subscription links businesses to partners |
| P&L widget | Placeholder until Finance module | Shows "Finance module required" message if no journal entries |
| Public pages stack | Blade + Tailwind only | No Livewire needed for static content, better SEO |
| Money display | `Money::format()` helper | Centralized, reusable, consistent KES/USD formatting |

---

## Open Questions (resolved)

- **Who selects the plan?** Owner selects during business creation (not at owner signup)
- **Are partners self-service?** No — root admin creates partners and sends credentials
- **Is billing per owner or per business?** Per business tenant
- **What does pricing page CTA do?** Goes to owner signup; plan selected after login when creating a business
