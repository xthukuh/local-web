# Filament Multi-Panel Standards

Phoenix System runs 5 Filament panels, one per access tier. This document covers
confirmed conventions extracted from the working codebase.

---

## Panel Architecture

```
app/Providers/Filament/
├── BusinessPanelProvider.php   → /          (business staff, DEFAULT)
├── CustomerPortalProvider.php  → /portal    (end-customers)
├── OwnerPanelProvider.php      → /owner     (business owners)
├── PartnerPanelProvider.php    → /partner   (resellers/agents)
└── RootPanelProvider.php       → /root      (system admin)
```

---

## 1. Panel Routing via AccessLevel Enum

`AccessLevel::panel()` is the **default** source of truth for user → panel routing.
A config map can override this for non-standard deployments.

```php
// enum default:
AccessLevel::Root->panel()             // 'root'
AccessLevel::Partner->panel()          // 'partner'
AccessLevel::Owner->panel()            // 'owner'
AccessLevel::Business->panel()         // 'business'
AccessLevel::BusinessUser->panel()     // 'business'
AccessLevel::BusinessAdmin->panel()    // 'business'
AccessLevel::BusinessCustomer->panel() // 'portal'

// optional config override (config/phoenix.php):
'panel_map' => ['root' => 'root', ...]
```

**Rule:** Never hardcode panel ID strings in middleware, controllers, or redirects.
Always call `$user->access_level->panel()`. Adding a new access level means adding
one `case` in the enum — nothing else changes.

---

## 2. `canAccessPanel()` — Dual Check

Both conditions must pass or access is denied:

```php
public function canAccessPanel(\Filament\Panel $panel): bool
{
    return $this->access_level->panel() === $panel->getId()
        && $this->is_active;
}
```

- **access_level match** — correct tier for this panel
- **is_active === true** — deactivated users are blocked regardless of role

> Do NOT skip the `is_active` check. Deactivation is a hard lock.

---

## 3. Middleware: No Constructor Injection

Filament resolves `authMiddleware` / `middleware` classes directly from the container.
The Laravel route `ClassName:param` colon syntax is **not supported** and throws
`BindingResolutionException`.

```php
// ✅ Correct — resolve panel context at runtime inside handle()
class EnsureCorrectPanel
{
    public function handle(Request $request, Closure $next): Response
    {
        $panelId = Filament::getCurrentPanel()?->getId();
        // ...
    }
}

// ❌ Wrong — causes BindingResolutionException at boot
->authMiddleware([EnsureCorrectPanel::class . ':root'])

// ❌ Also wrong — constructor parameters can't be satisfied
class EnsureCorrectPanel {
    public function __construct(private string $panel) {}
}
```

When middleware needs the current panel, use `Filament::getCurrentPanel()->getId()`.

---

## 4. Middleware: Logout on Wrong Panel

`EnsureCorrectPanel` **logs the user out** on a panel mismatch — not a 403.
This is intentional: it prevents cross-panel session hijacking.

```php
if ($currentPanelId && $user->access_level->panel() !== $currentPanelId) {
    auth()->logout();
    return redirect('/')->with('error', 'Access denied for this panel.');
}
```

> Do not change this to a simple redirect without logout.

---

## 5. Subscription Gate Exclusions

`EnsureActiveSubscription` is **absent from the Root panel** middleware stack.
On other panels it runs but bypasses these tenant types:

```php
// Never subscription-gated:
['system', 'partner', 'owner']

// Always gated (must have active subscription):
'business', 'portal'
```

```php
// RootPanelProvider — deliberately omits EnsureActiveSubscription:
->middleware([..., ResolveTenant::class])

// All other panels include it:
->middleware([..., ResolveTenant::class, EnsureActiveSubscription::class])
```

> Never add `EnsureActiveSubscription` to the Root panel middleware stack.

---

## 6. Resource Discovery Path Convention

Each panel discovers from a directory named after its panel ID (PascalCase):

```
app/Filament/{PanelId}/Resources/   ← Filament resources
app/Filament/{PanelId}/Pages/       ← custom pages
app/Filament/{PanelId}/Widgets/     ← dashboard widgets
```

| Panel ID | Discovery root            |
|----------|---------------------------|
| root     | app/Filament/Root/        |
| partner  | app/Filament/Partner/     |
| owner    | app/Filament/Owner/       |
| business | app/Filament/Business/    |
| portal   | app/Filament/Portal/      |

For module resources within the Business panel, use sub-folders:
```
app/Filament/Business/Resources/CRM/
app/Filament/Business/Resources/POS/
app/Filament/Business/Resources/Finance/
```

> Resources in the wrong folder are silently ignored by Filament's auto-discovery.

---

## 7. Provider Registration Order

`BusinessPanelProvider` (the `.default()` panel) must be listed **before** all other
panel providers in `bootstrap/providers.php`. Order is load-order-sensitive.

```php
return [
    App\Providers\AppServiceProvider::class,
    App\Providers\Filament\BusinessPanelProvider::class,  // ← default, first
    App\Providers\Filament\CustomerPortalProvider::class,
    App\Providers\Filament\OwnerPanelProvider::class,
    App\Providers\Filament\PartnerPanelProvider::class,
    App\Providers\Filament\RootPanelProvider::class,
];
```

> Never sort providers alphabetically. The order is intentional.

---

## 8. Modular Package Integration

Packages in `packages/Phoenix/*` must **not** register Filament resources in their
`ServiceProvider`. Panel wiring belongs in the app layer.

```
packages/Phoenix/CRM/        ← models, services, migrations only
app/Filament/Business/Resources/CRM/   ← thin Filament wrappers, owned by app
```

```php
// app/Filament/Business/Resources/CRM/AccountResource.php
use Phoenix\CRM\Models\Account;          // ← from package
use Phoenix\CRM\Services\AccountService; // ← from package

class AccountResource extends Resource
{
    protected static ?string $model = Account::class;
}
```

This keeps packages free of Filament dependencies (independently testable) while
the app layer owns all panel wiring.

---

## 9. Tenant-Scoped Table Queries

If a resource model uses the `BelongsToTenant` trait, the `TenantScope` global scope
handles filtering automatically. For cross-tenant resources (Root panel only), use
`withoutGlobalScopes()`:

```php
// Root panel resource — sees all tenants:
public static function getEloquentQuery(): Builder
{
    return parent::getEloquentQuery()->withoutGlobalScopes();
}

// Business panel resource — TenantScope applies automatically, no override needed
```

---

## 10. License-Gated Resources

Use `LicenseManager` in `canViewAny()` to hide resources from tenants without the feature:

```php
public static function canViewAny(): bool
{
    $tenant = app('tenant');
    return $tenant && app(\Phoenix\Licensing\Services\LicenseManager::class)
        ->hasFeature($tenant, 'feature_crm');
}
```
