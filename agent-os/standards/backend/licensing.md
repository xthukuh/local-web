# Licensing & Subscription System (Phoenix Sys)

## Tenant Types
```
System (root) → Partner (reseller) → Owner (manages businesses) → Business (billed unit)
```

## License Plan Tiers
- **Launch** — entry-level, limited users/storage
- **Growth** — mid-tier, more resources, more modules
- **Scale** — full-featured, unlimited resources

## Key Domain Rules
- Subscription attaches ONLY to business tenants
- Plan versions are immutable once active subscriptions exist
- All limits resolved through `LicenseManager` service — never hardcoded
- Never delete invoice or payment records (void instead)
- Commission created only AFTER invoice is paid
- Downgrade must validate actual usage against new plan limits

## LicenseManager Service Pattern
```php
class LicenseManager
{
    public function check(string $key, Business $business): bool
    {
        $limit = $this->getLimit($key, $business->subscription);
        if ($limit === -1) return true; // unlimited
        return $this->getUsage($key, $business) < $limit;
    }

    public function enforce(string $key, Business $business): void
    {
        if (!$this->check($key, $business)) {
            throw new LicenseLimitExceededException($key);
        }
    }

    public function getLimit(string $key, Subscription $sub): int|float
    {
        // Check addon overrides first, then plan limits
        return $sub->addonLimit($key) ?? $sub->plan->limit($key) ?? 0;
    }
}
```

## Subscription Lifecycle States
```
trial → active → past_due → grace → suspended → cancelled
```

## Billing Jobs (Daily Scheduler)
```php
// Scheduled in console kernel
Schedule::job(new CheckTrialEndingJob)->daily();
Schedule::job(new GenerateRenewalInvoiceJob)->daily();
Schedule::job(new AttemptAutoChargeJob)->daily();
Schedule::job(new MarkPastDueJob)->daily();
Schedule::job(new MoveToGracePeriodJob)->daily();
Schedule::job(new SuspendAfterGraceJob)->daily();
Schedule::job(new ResetMonthlyUsageJob)->monthlyOn(1);
```

## Feature Gate Middleware
```php
class EnsureActiveSubscription
{
    public function handle(Request $request, Closure $next): Response
    {
        $business = app('tenant');
        if (!$business->hasActiveSubscription()) {
            return redirect()->route('billing.expired');
        }
        return $next($request);
    }
}

class CheckFeatureAccess
{
    public function handle(Request $request, Closure $next, string $feature): Response
    {
        app(LicenseManager::class)->enforce($feature, app('tenant'));
        return $next($request);
    }
}
```

## Money Storage Rule
Store ALL monetary values as integer minor units (never float):
```php
// KES 1,500.00 → store 150000
// USD 99.99 → store 9999
// Use brick/money package for operations
$money = Money::of(9999, 'USD', new AutoContext());
```
