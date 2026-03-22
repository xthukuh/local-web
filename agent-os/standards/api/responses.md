# API Response Format

## Standard Envelope
All API responses use a consistent JSON envelope:

```json
// Success (single resource)
{ "success": true, "data": { "id": 1, "name": "..." } }

// Success (collection)
{ "success": true, "data": [...], "meta": { "total": 50, "per_page": 15, "current_page": 1 } }

// Error
{ "success": false, "message": "Validation failed", "errors": { "email": ["already taken"] } }
```

## API Resources
Always use Laravel API Resources — never return Eloquent models directly:

```php
// app/Http/Resources/UserResource.php
class UserResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id'         => $this->id,
            'name'       => $this->name,
            'email'      => $this->email,
            'created_at' => $this->created_at->toISOString(),
        ];
    }
}

// Controller
return new UserResource($user);
return UserResource::collection($users);
```

## Pagination
- Always paginate collection endpoints: `->paginate(15)`
- Use `->cursorPaginate()` for infinite scroll / large datasets
- Include pagination links via Resource Collections

## HTTP Status Codes
- `200` — OK (GET, PUT success)
- `201` — Created (POST success)
- `204` — No Content (DELETE success)
- `400` — Bad Request
- `401` — Unauthenticated
- `403` — Forbidden
- `404` — Not Found
- `422` — Validation Error (always include `errors` key)
- `429` — Too Many Requests (rate limited)
- `500` — Server Error
