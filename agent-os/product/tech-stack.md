# Tech Stack

## Backend
- PHP 8.2+ with Laravel 12.x
- Modular packages in `packages/Phoenix/*` (PSR-4, registered via composer path repositories)
- Laravel Passport (OAuth2 for API authentication)
- Laravel Sanctum (SPA/mobile token auth)
- Laravel Queues (Redis driver) for background jobs
- Laravel Cashier (Stripe) for subscription billing
- Laravel Boost (dev tool, AI agent context)

## Admin Panels (Filament v5.x)
- Root Panel (`/root`) — system administration
- Partner Panel (`/partner`) — reseller/agent management
- Owner Panel (`/owner`) — business owner management
- Business Panel (`/`) — business operations (default)
- Customer Portal (`/portal`) — self-service

## Database
- MySQL 8.x (primary, shared DB multi-tenancy via tenant_id)
- Redis (caching, sessions, queues, broadcast)

## Frontend
- Blade + Alpine.js + Livewire v3 (via Filament)
- Tailwind CSS v4
- Customer Portal: Blade + Alpine.js (lightweight SPA)

## Infrastructure
- Docker (Apache + PHP 8.3 Alpine, local dev)
- GitHub (code management + CI/CD)
- GitHub Actions (CI: test, lint, deploy)

## Testing
- Pest PHP (feature + unit tests)
- PHPUnit (base runner)
- Filament testing helpers

## Key Packages
- `stancl/tenancy` or custom tenant middleware (shared DB approach)
- `spatie/laravel-permission` (roles & permissions)
- `spatie/laravel-media-library` (file/media management)
- `spatie/laravel-settings` (business settings)
- `spatie/laravel-activity-log` or custom audit trait
- `barryvdh/laravel-dompdf` (PDF generation)
- `maatwebsite/excel` (Excel export)
- `brick/money` (Money value objects)
- `squirephp/countries-en` + `squirephp/currencies-en` (locale data)

## Dev Tools
- Laravel Pint (code style)
- PHPStan / Larastan (static analysis)
- Rector (refactoring)
- Laravel Boost (AI context)
- Agent OS + Claude Code (AI-assisted development)
- Mailpit (local email testing)
