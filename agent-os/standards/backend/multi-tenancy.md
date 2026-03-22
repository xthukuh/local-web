# Multi-Tenancy Standards (Phoenix Sys)

Shared-database multi-tenancy: every tenant-scoped table has `tenant_id`.
No separate databases per tenant.

---

## Tenant Hierarchy

```
system (Root admins) → partner (resellers) → owner → business → business-user / business-admin / business-customer
```

---

## 1. Static Scope State — Thread-Safety Warning

`TenantScope` stores the active tenant ID in a **static property**, not the request object.

```php
class TenantScope implements Scope
{
    private static ?int $tenantId = null;

    public static function setTenant(object $tenant): void { self::$tenantId = $tenant->id; }
    public static function getTenantId(): ?int { return self::$tenantId; }
    public static function clear(): void { self::$tenantId = null; }

    public function apply(Builder $builder, Model $model): void
    {
        if (self::$tenantId !== null) {
            $builder->where($model->getTable() . '.tenant_id', self::$tenantId);
        }
    }
}
```

**Implications:**
- Safe on PHP-FPM (fresh process per request)
- **Breaks on Swoole/RoadRunner** — static state leaks between concurrent requests
- If async workers are introduced, migrate to a request-bound context object

---

## 2. Dual Binding — Always Set Both

`ResolveTenant` middleware sets the tenant in **two places**. Both are required:

```php
app()->instance('tenant', $tenant);  // for auto-fill on model create
TenantScope::setTenant($tenant);     // for global scope WHERE clause
```

| Binding | Used by |
|---------|---------|
| `app('tenant')` | `BelongsToTenant` → auto-fills `tenant_id` on create |
| `TenantScope::$tenantId` | `TenantScope::apply()` → adds `WHERE tenant_id = ?` to all queries |

> Setting only one causes silent failures: missing tenant_id on new records, or unscoped reads.

---

## 3. Auto Tenant ID Injection on Create

`BelongsToTenant` silently fills `tenant_id` in the `creating` hook:

```php
static::creating(function (Model $model): void {
    if (app()->has('tenant') && empty($model->tenant_id)) {
        $model->tenant_id = app('tenant')->id;
    }
});
```

**Rules:**
- Never set `tenant_id` manually in application code — let the trait handle it
- If the container binding is missing (e.g. in tests without setup), `tenant_id` stays null — **no exception is thrown**
- `empty()` treats `0`, `''`, and `null` as empty — only falsy values are auto-filled

> Tests that create models without calling `TenantScope::setTenant()` first will produce records with null tenant_id.

---

## 4. Scope Bracketing — Seeders and Tests

Any code that creates or queries tenant-scoped records outside a normal request must bracket the scope:

```php
// Seeder pattern:
$tenant = Tenant::withoutGlobalScopes()->where('slug', 'system')->first();
TenantScope::setTenant($tenant);

// ... scoped operations here ...

TenantScope::clear(); // always clear after

// Test pattern (Pest):
beforeEach(function () {
    $this->tenant = Tenant::factory()->create();
    TenantScope::setTenant($this->tenant);
});

afterEach(function () {
    TenantScope::clear();
});
```

**Warning:** There is no `try/finally` protection. If an exception is thrown before `clear()`, subsequent code in the same process runs with a leaked tenant scope. For long-running test suites, always clear in `afterEach`.

---

## 5. Tenant Resolution — Subdomain + Route Parameter

`ResolveTenant` tries route parameter first, then falls back to subdomain:

```php
$slug = $request->route('tenant') ?? $this->fromSubdomain($request->getHost());

private function fromSubdomain(string $host): ?string
{
    $parts = explode('.', $host);
    return count($parts) >= 3 ? $parts[0] : null; // 'acme.app.com' → 'acme'
}
```

- `localhost` or `app.com` (< 3 parts) → no tenant resolved (null is safe)
- `acme.app.com` → resolves slug `acme`
- Route `{tenant}` parameter takes precedence over subdomain

The lookup always uses `withoutGlobalScopes()` to bypass the TenantScope when resolving:
```php
$tenant = Tenant::withoutGlobalScopes()->where('slug', $slug)->firstOrFail();
```

---

## 6. Cross-Tenant Queries — Escape Hatch

Use `scopeForTenant()` for explicitly authorized cross-tenant reads (e.g. root admin views):

```php
// Read a specific tenant's records without the global scope:
Invoice::scopeForTenant($tenantId)->get();

// Implementation in BelongsToTenant:
public function scopeForTenant(Builder $query, int $tenantId): Builder
{
    return $query->withoutGlobalScope(TenantScope::class)
        ->where($this->getTable() . '.tenant_id', $tenantId);
}
```

> `scopeForTenant()` has **no authorization check**. Only use in Root panel resources or explicit admin services. Never expose it to business-tier code paths.

For root admin resources that need to see all tenants, disable the scope entirely:
```php
public static function getEloquentQuery(): Builder
{
    return parent::getEloquentQuery()->withoutGlobalScopes();
}
```

---

## 7. Audit Trail — saveQuietly() Is Mandatory

`ModelHandler` listens to wildcard Eloquent events and writes audit fields:

```php
Event::listen('eloquent.created: *', fn($event, $models) => $handler->handleCreated($models[0]));
Event::listen('eloquent.updated: *', fn($event, $models) => $handler->handleUpdated($models[0]));
Event::listen('eloquent.deleted: *', fn($event, $models) => $handler->handleDeleted($models[0]));
```

Inside `setAuditField()`, the model is saved with `saveQuietly()`:

```php
$model->$column = auth()->id();
$model->saveQuietly(); // REQUIRED — skips event dispatch to prevent infinite loop
```

**Why:** Without `saveQuietly()`, saving triggers another `updated` event → handler fires again → infinite recursion.

> Never change `saveQuietly()` to `save()` in `ModelHandler`. The wildcard listener applies to every model in the system.

---

## 8. Subscription Status Whitelist

`trial`, `active`, and `grace` all count as an active subscription:

```php
public function activeSubscription(): ?Subscription
{
    return $this->subscriptions()
        ->whereIn('status', ['trial', 'active', 'grace'])
        ->latest()
        ->first();
}
```

- **trial** — within trial period, full feature access
- **active** — paid and current
- **grace** — expired but within 15-day grace window (still accessible)
- `past_due`, `suspended`, `cancelled` — not active, subscription wall applies

> Do not compare `$subscription->status === 'active'` alone. Use `$tenant->hasActiveSubscription()` or `$subscription->isActive()`.

---

## 9. Table Migration Convention

Every tenant-scoped table must include:

```php
$table->foreignId('tenant_id')->constrained()->cascadeOnDelete()->index();
```

---

## 10. Jobs Must Capture Tenant ID at Dispatch Time

Jobs that run asynchronously lose the static scope. Capture tenant ID on dispatch:

```php
class ProcessOrderJob implements ShouldQueue
{
    public function __construct(
        private readonly int $tenantId,
        private readonly int $orderId,
    ) {}

    public function handle(): void
    {
        $tenant = Tenant::find($this->tenantId);
        TenantScope::setTenant($tenant);

        // ... scoped work ...

        TenantScope::clear();
    }
}
```
