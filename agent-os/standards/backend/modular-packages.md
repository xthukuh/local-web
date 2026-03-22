# Modular Package Architecture (Phoenix Sys)

## Structure
All modules live in `packages/Phoenix/{Module}/`:

```
packages/
└── Phoenix/
    ├── Core/               Foundation classes, traits, base providers
    ├── Platform/           Settings, metadata, permissions, menus
    ├── Auth/               Authentication, users, roles, tenancy
    ├── Licensing/          Plans, subscriptions, billing lifecycle
    ├── CRM/                Accounts, contacts, leads, opportunities, quotes
    ├── POS/                Products, orders, payments, receipts
    ├── Inventory/          Stock, warehouses, stock movements
    ├── Finance/            Invoices, expenses, cash accounts, accounting
    ├── HRMS/               Employees, departments, attendance, leave, payroll
    ├── Reporting/          Report engine, templates, exports
    └── Approval/           Approval workflows, steps, notifications
```

## Per-Package Structure
```
packages/Phoenix/{Module}/
├── composer.json
├── src/
│   ├── Contracts/              (Interfaces)
│   ├── Models/                 (Eloquent models)
│   ├── Services/               (Business logic services)
│   ├── Repositories/           (Data access layer - optional)
│   ├── Http/
│   │   ├── Controllers/
│   │   ├── Requests/
│   │   └── Resources/
│   ├── Filament/
│   │   ├── Resources/
│   │   ├── Pages/
│   │   └── Widgets/
│   ├── Providers/
│   │   └── {Module}ServiceProvider.php
│   ├── Events/
│   ├── Listeners/
│   ├── Jobs/
│   ├── Notifications/
│   ├── Enums/
│   ├── Database/
│   │   ├── Migrations/
│   │   └── Seeders/
│   ├── Config/
│   │   └── {module}.php
│   └── Routes/
│       ├── web.php
│       └── api.php
└── tests/
```

## Package composer.json
```json
{
    "name": "phoenix/{module-name}",
    "description": "Phoenix {Module} module",
    "type": "library",
    "require": {
        "php": "^8.2",
        "phoenix/core": "*"
    },
    "autoload": {
        "psr-4": {
            "Phoenix\\{Module}\\": "src/"
        }
    },
    "extra": {
        "laravel": {
            "providers": ["Phoenix\\{Module}\\Providers\\{Module}ServiceProvider"]
        }
    }
}
```

## Root composer.json Registration
```json
{
    "repositories": [
        {
            "type": "path",
            "url": "packages/Phoenix/*",
            "options": {"symlink": true}
        }
    ],
    "require": {
        "phoenix/core": "*",
        "phoenix/platform": "*",
        "phoenix/auth": "*",
        "phoenix/licensing": "*",
        "phoenix/crm": "*"
    }
}
```

## Service Provider Pattern
```php
namespace Phoenix\{Module}\Providers;

use Illuminate\Support\ServiceProvider;

class {Module}ServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        $this->mergeConfigFrom(__DIR__.'/../Config/{module}.php', '{module}');
    }

    public function boot(): void
    {
        $this->loadMigrationsFrom(__DIR__.'/../Database/Migrations');
        $this->loadRoutesFrom(__DIR__.'/../Routes/web.php');
        $this->loadRoutesFrom(__DIR__.'/../Routes/api.php');

        if ($this->app->runningInConsole()) {
            $this->publishes([
                __DIR__.'/../Config/{module}.php' => config_path('{module}.php'),
            ], '{module}-config');
        }
    }
}
```

## Rules
- Each package must be independently autoloadable
- Cross-package dependencies go in package's `composer.json`
- Never import a package's internals from another package — use contracts/interfaces
- Filament resources live in the package that owns the model
- Panel providers in the root app register resources from packages
