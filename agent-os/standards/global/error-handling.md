# Error Handling

## API Errors
Return consistent JSON envelope for all API errors:

```php
// Always use consistent structure
return response()->json([
    'success' => false,
    'message' => 'Human-readable message',
    'errors'  => $validator->errors(), // only for validation
], 422);
```

- `400` — Bad Request (malformed input)
- `401` — Unauthenticated (missing/expired token)
- `403` — Forbidden (authenticated but unauthorized)
- `404` — Not Found
- `422` — Validation Failed (include `errors` key)
- `500` — Server Error (log full details, return safe message)

## Exception Handling
- Catch specific exceptions, not `\Exception` broadly
- Log with context: `Log::error('Failed to process payment', ['order_id' => $order->id, 'error' => $e->getMessage()])`
- Never expose stack traces or internal details in API responses
- Use custom exception classes for domain errors: `InsufficientStockException`, `PaymentDeclinedException`

## Filament
- Use `Filament::notify('danger', 'Error message')` for user-facing errors in actions
- Wrap risky operations in try/catch within actions, halt with `$this->halt()` on failure
- Never let unhandled exceptions bubble up to Filament UI — always catch and notify
