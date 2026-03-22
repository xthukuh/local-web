# Laravel 12.x Conventions

## Service Layer
- Extract complex business logic into Service classes in `app/Services/`
- Services are plain PHP classes injected via constructor DI — no base class needed
- Controllers stay thin: validate → call service → return response

```php
// Controller (thin)
public function store(StoreOrderRequest $request, OrderService $service)
{
    $order = $service->create($request->validated());
    return new OrderResource($order);
}
```

## Route Organization
- API routes in `routes/api.php` with version prefixes: `/api/v1/`
- Group related routes: `Route::apiResource('orders', OrderController::class)`
- Web routes for non-API in `routes/web.php`
- Use named routes consistently: `route('orders.show', $order)`

## Dependency Injection
- Always type-hint dependencies in constructors
- Bind interfaces to implementations in `AppServiceProvider` when needed
- Use `app()->make()` only as a last resort (in factories, middleware)

## Eloquent Best Practices
- Define all relationships explicitly with proper return types
- Use scopes for reusable query logic: `scopeActive()`, `scopeForUser()`
- Eager load relationships to prevent N+1: `User::with(['orders.items'])->get()`
- Use `firstOrCreate`, `updateOrCreate` over manual checks
- Cast attributes: `protected $casts = ['settings' => 'array', 'published_at' => 'datetime']`

## Events & Jobs
- Fire events for significant domain actions: `UserRegistered`, `OrderShipped`
- Queue jobs for time-consuming tasks: email, PDF generation, API calls
- Always define `$tries` and `$timeout` on jobs

## Configuration
- Never hardcode config values — use `config('app.key')` and `.env`
- Group related config in dedicated files: `config/invoice.php`, `config/sms.php`
- Use `php artisan config:cache` in production

## Artisan Commands
- One command per file, in `app/Console/Commands/`
- Use `$signature` with typed arguments: `{user : The user ID}`
- Always output progress with `$this->info()` / `$this->error()`
