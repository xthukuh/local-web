# References — Licensing UI

## Existing Models (all ready to use)

| Model | Path | Notes |
|---|---|---|
| Tenant | `packages/Phoenix/Auth/src/Models/Tenant.php` | `hasActiveSubscription()`, `activeSubscription()`, `children()` |
| User | `app/Models/User.php` | `canAccessPanel()`, `access_level` cast, `HasRoles` |
| LicensePlan | `packages/Phoenix/Licensing/src/Models/LicensePlan.php` | `getLimit(string $key)` |
| LicensePlanType | `packages/Phoenix/Licensing/src/Models/LicensePlanType.php` | |
| LicensePlanLimit | `packages/Phoenix/Licensing/src/Models/LicensePlanLimit.php` | |
| Subscription | `packages/Phoenix/Licensing/src/Models/Subscription.php` | `isActive()`, status enum |
| PlatformInvoice | `packages/Phoenix/Licensing/src/Models/PlatformInvoice.php` | All money fields are integer minor units |
| PlatformPayment | `packages/Phoenix/Licensing/src/Models/PlatformPayment.php` | |
| Commission | `packages/Phoenix/Licensing/src/Models/Commission.php` | `partner_id` → Tenant |
| Coupon | `packages/Phoenix/Licensing/src/Models/Coupon.php` | `isValid()` |
| Addon | `packages/Phoenix/Licensing/src/Models/Addon.php` | |

## Existing Services

| Service | Path | Key methods |
|---|---|---|
| LicenseManager | `packages/Phoenix/Licensing/src/Services/LicenseManager.php` | `hasFeature()`, `checkLimit()`, `getRemainingUsage()`, `incrementUsage()` |

## Existing Enums

| Enum | Path | Key methods |
|---|---|---|
| AccessLevel | `app/Enums/AccessLevel.php` | `->panel()`, `->label()` |
| SubscriptionStatus | `app/Enums/SubscriptionStatus.php` | `->color()`, `->label()`, `->isAccessible()` |
| TenantType | `app/Enums/TenantType.php` | |

## Existing Middleware

| Middleware | Path | Used in |
|---|---|---|
| ResolveTenant | `app/Http/Middleware/ResolveTenant.php` | All panels |
| EnsureCorrectPanel | `app/Http/Middleware/EnsureCorrectPanel.php` | All panels (uses `Filament::getCurrentPanel()`) |
| EnsureActiveSubscription | `app/Http/Middleware/EnsureActiveSubscription.php` | Partner, Owner, Business, Portal panels |

## Panel Providers

| Panel | Provider | Path |
|---|---|---|
| Root | RootPanelProvider | `app/Providers/Filament/RootPanelProvider.php` |
| Partner | PartnerPanelProvider | `app/Providers/Filament/PartnerPanelProvider.php` |
| Owner | OwnerPanelProvider | `app/Providers/Filament/OwnerPanelProvider.php` |
| Business | BusinessPanelProvider | `app/Providers/Filament/BusinessPanelProvider.php` |
| Portal | CustomerPortalProvider | `app/Providers/Filament/CustomerPortalProvider.php` |

## Seeders (existing data)

- System tenant: slug=`system`, type=`system`
- Root user: `root@phoenixsys.ke` / `password`, access_level=`root`
- Plans: Launch (KES 2,999), Growth (KES 7,999), Scale (KES 19,999) — monthly, currency=KES
