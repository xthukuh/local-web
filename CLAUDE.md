# Claude Code — Project Configuration

## Environment
- **Docker**: Apache + PHP 8.3 (Alpine) serving multiple Laravel projects
- **Projects**: `/www/html/` — 18 Laravel applications
- **PHP**: 8.3 inside container (8.2+ required for all projects)
- **DB**: MySQL 8.x, Redis (caching/queues/sessions)
- **Mail**: Mailpit (local dev, `localhost:8025`)
- **SSL**: Self-signed certs per vhost

## Tech Stack
- **Backend**: Laravel 12.x, PHP 8.2+
- **Admin Panel**: Filament v5.x
- **Frontend**: Blade + Alpine.js + Livewire v3 + Tailwind CSS v4
- **Auth**: Laravel Sanctum (SPA/mobile) or Passport (OAuth2)
- **Testing**: Pest PHP (preferred), PHPUnit

## Standards
This project uses **agent-os** for standards management. Standards live in `agent-os/standards/`.

Use `/inject-standards` to pull relevant standards into context before implementing features.
Use `/discover-standards` to extract new patterns from the codebase.
Use `/shape-spec` (in plan mode) to plan significant features.

### Key Standards
- `agent-os/standards/global/naming.md` — naming conventions (PHP, Laravel, Filament)
- `agent-os/standards/backend/laravel.md` — Laravel 12.x patterns
- `agent-os/standards/backend/eloquent.md` — Eloquent model conventions
- `agent-os/standards/backend/validation.md` — Form Requests & Filament validation
- `agent-os/standards/filament/resources.md` — Resource structure & navigation
- `agent-os/standards/filament/forms.md` — Form component patterns
- `agent-os/standards/filament/tables.md` — Table columns, filters, actions
- `agent-os/standards/filament/actions.md` — Action types & notifications
- `agent-os/standards/filament/widgets.md` — Dashboard widgets
- `agent-os/standards/api/responses.md` — API response envelope
- `agent-os/standards/api/authentication.md` — Sanctum/Passport auth
- `agent-os/standards/database/migrations.md` — Migration conventions
- `agent-os/standards/testing/feature.md` — Feature & Filament testing

## Working with Projects
- Each project under `/www/html/{project}/` is a standalone Laravel app
- Run `composer`, `artisan`, etc. from inside the container or via `docker exec`
- Vhosts configured in `/www/config/vhosts/` — one `.conf` per project

## Code Style
- PSR-12 coding standard
- Strict types: `declare(strict_types=1)` in all PHP files
- No `var_dump`, `dd()`, or `dump()` left in committed code
- All public methods must have return types
- Prefer value objects / enums over magic strings for status fields

## Filament v5 Specifics
- Import from `Filament\Tables\Actions`, `Filament\Forms\Components`, `Filament\Infolists\Components`
- Always send `Notification` after action completion
- Use `->badge()` modifier on `TextColumn` (not deprecated `BadgeColumn`)
- Panels registered in `app/Providers/Filament/AdminPanelProvider.php`

## Do Not
- Do not commit `.env` files
- Do not use `Route::get()` for state-changing operations
- Do not return raw Eloquent models from API endpoints — always use Resources
- Do not skip Form Request classes for validation
- Do not use `sleep()` in tests — use `Carbon::setTestNow()` for time manipulation
