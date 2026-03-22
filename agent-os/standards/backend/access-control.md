# Access Control — Multi-Panel ACL (Phoenix Sys)

## Access Level Hierarchy
```
root          → system administrator (manages everything)
partner       → reseller/agent (manages owners, earns commission)
owner         → business owner (manages businesses, billed)
business      → business entity admin (manages business resources)
business-user → staff/user within a business
business-admin → can configure business settings
business-customer → self-service portal access only
```

## Filament Panels per Access Level
- `/root` — RootPanelProvider — access: `root` users only
- `/partner` — PartnerPanelProvider — access: `partner` tenants
- `/owner` — OwnerPanelProvider — access: `owner` tenants
- `/` — BusinessPanelProvider — access: business users (default)
- `/portal` — CustomerPortalProvider — access: business customers

## Role & Permission Pattern (spatie/laravel-permission)
```php
// Roles: root, partner, owner, business_admin, business_user, business_customer
// Permissions: module-level (e.g., crm.contacts.view, pos.orders.create)

$user->assignRole('business_admin');
$user->givePermissionTo('crm.contacts.view');
```

## Panel Access Gates
```php
// In each PanelProvider
->authGuard('web')
->authMiddleware([Authenticate::class])
->middleware([
    EnsureCorrectPanel::class,    // prevent cross-panel access
    EnsureActiveSubscription::class,
])
```

## EnsureCorrectPanel Middleware
```php
class EnsureCorrectPanel
{
    public function handle(Request $request, Closure $next, string $requiredRole): Response
    {
        if (!auth()->user()?->hasRole($requiredRole)) {
            abort(403, 'Incorrect access panel.');
        }
        return $next($request);
    }
}
```

## License-Based Feature Flags
Gate features behind license checks in Filament:
```php
// In Filament resource
public static function canViewAny(): bool
{
    return app(LicenseManager::class)->check('feature.crm', app('tenant'));
}
```

## Impersonation (Partner → Owner)
```php
class ImpersonateOwner extends Action
{
    public function action(Tenant $owner, Action $action): void
    {
        // Validate partner can impersonate
        auth()->user()->impersonate($owner->admin_user);
        AuditLog::record(action: 'partner.impersonation.started', subject: $owner);
        redirect()->to('/owner');
    }
}
```
