# References — Phoenix System Foundation

## Legacy Projects (Study References)

### 1. intent — CRM + Gym Management
**Path:** `/home/user/projects/local-web/www/html/intent/`

Key files to reference:
- `app/Listeners/ModelHandler.php` — auto audit created_by/updated_by/deleted_by pattern
- `app/Models/Sales/Account.php` — CRM account model with polymorphic address
- `app/Models/Sales/Lead.php` — lead with state machine (status transitions, closed_at logic)
- `app/Models/Sales/Quote.php` — quote with line items
- `app/Models/Gym/MembershipSubscription.php` — subscription lifecycle with start/end dates
- `app/Models/Shop/Order.php` — order with auto-total calculation
- `app/Providers/Filament/AdminPanelProvider.php` — panel config pattern
- `app/Providers/Filament/AppPanelProvider.php` — multi-tenant panel with Team
- `app/Providers/EventServiceProvider.php` — global model event listening
- `config/crm.php` — pipeline stages config pattern
- `config/gym.php` — module config pattern

### 2. ekoapp — POS + Accounting (custom PHP, reference only)
**Path:** `/home/user/projects/local-web/www/html/ekoapp/`

Key patterns to adapt to Laravel:
- `api_provider/library.php` → `AccountsTransaction()` method — POS transaction with journal posting
- `api_provider/library.php` → `JournalEntry()` — double-entry debit/credit pairs
- `ekoapp.sql` — Chart of Accounts structure (5 categories, account groups)
- `ekoapp.sql` — Transaction types (14 types: Sale, Purchase, Expense, Transfer, etc.)
- `ekoapp.sql` — business_transactions + business_transaction_items — transaction header/line pattern
- `ekoapp.sql` — business_journals + business_journal_entries — journal header/line pattern
- `modules/business_sales/` — POS line item calculation UX pattern (tax modes: included/not included/plus)

### 3. ncmstb — Modular CRM (Krayin)
**Path:** `/home/user/projects/local-web/www/html/ncmstb/`

Key files to reference:
- `composer.json` — path repository + package autoload configuration
- `config/concord.php` — module registration pattern
- `packages/Webkul/Core/src/Providers/BaseModuleServiceProvider.php` — base module provider
- `packages/Webkul/Lead/src/Providers/ModuleServiceProvider.php` — simple module provider
- `packages/Webkul/Lead/src/Models/Lead.php` — model with contracts + proxy pattern
- `packages/Webkul/Attribute/src/Traits/CustomAttribute.php` — dynamic attribute trait
- `packages/Webkul/Activity/src/Traits/LogsActivity.php` — auto activity logging trait
- `packages/Webkul/Core/src/Eloquent/Repository.php` — cacheable repository base
- `packages/Webkul/Lead/src/Repositories/LeadRepository.php` — repository with complex CRUD

## Prompt Planning Documents
- `/home/user/projects/local-web/prompt/Phoenix Sys - Draft.md` — project brief
- `/home/user/projects/local-web/prompt/SaaS Multi-Tenant Setup.md` — setup guide
- `/home/user/projects/local-web/prompt/Agent.md` — user preferences and coding principles
- `/home/user/projects/local-web/prompt/_notes/Chat-GPT ~ SaaS Licensing Plan 01.md` — licensing structure
- `/home/user/projects/local-web/prompt/_notes/Chat-GPT ~ SaaS Licensing Plan 02.md` — DB schema for licensing
- `/home/user/projects/local-web/prompt/_notes/Chat-GPT ~ Multi-currency support planning.md` — multi-currency design
- `/home/user/projects/local-web/prompt/_notes/00 Plans - Features.md` — full feature checklist
