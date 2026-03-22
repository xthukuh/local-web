# API Authentication

## Sanctum (SPA / Mobile)
Standard for most projects — use Laravel Sanctum for token-based auth:

```php
// Issue token
$token = $user->createToken('api-token', ['*'])->plainTextToken;
return response()->json(['token' => $token]);

// Revoke (logout)
$request->user()->currentAccessToken()->delete();

// Route protection
Route::middleware('auth:sanctum')->group(function () { ... });
```

## Passport (OAuth2 / Third-party)
Use for projects requiring OAuth2 flows (authorization code, client credentials):

```php
// Protected routes
Route::middleware('auth:api')->group(function () { ... });
```

## Token Scopes
- Define fine-grained scopes when needed: `['read:orders', 'write:orders']`
- Check scopes in controllers: `$request->user()->tokenCan('write:orders')`

## Auth Responses
```php
// Successful login
return response()->json([
    'success' => true,
    'data'    => ['token' => $token, 'user' => new UserResource($user)],
], 200);

// Failed login
return response()->json([
    'success' => false,
    'message' => 'Invalid credentials',
], 401);
```

## Middleware Order
Always stack in this order for API routes:
1. `throttle:api`
2. `auth:sanctum` (or `auth:api`)
3. Custom middleware
