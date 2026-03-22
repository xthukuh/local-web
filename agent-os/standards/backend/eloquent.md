# Eloquent Patterns

## Model Structure Order
Follow consistent property/method ordering in models:

```php
class Order extends Model
{
    use HasFactory, SoftDeletes;

    // 1. Constants
    const STATUS_PENDING = 'pending';

    // 2. Fillable / guarded
    protected $fillable = ['user_id', 'status', 'total'];

    // 3. Casts
    protected $casts = [
        'metadata' => 'array',
        'shipped_at' => 'datetime',
    ];

    // 4. Relationships
    public function user(): BelongsTo { ... }
    public function items(): HasMany { ... }

    // 5. Scopes
    public function scopePending(Builder $query): Builder { ... }

    // 6. Accessors / Mutators
    protected function formattedTotal(): Attribute { ... }

    // 7. Business methods
    public function markAsShipped(): void { ... }
}
```

## Query Patterns
- Use query scopes for reusable filters: `Order::pending()->forUser($user)->get()`
- Chunk large datasets: `User::chunk(200, fn($users) => ...)`
- Select only needed columns: `User::select(['id', 'name', 'email'])->get()`
- Avoid `all()` on large tables — always filter/paginate

## Relationships
- Always define both sides of a relationship
- Use `withCount` for counts: `Post::withCount('comments')->get()`
- Avoid lazy loading in loops — always eager load: `->with('relation')`
- Use `has()` / `whereHas()` for existence-based filtering

## Soft Deletes
- Use `SoftDeletes` for user-facing models that may need recovery
- Scope to exclude trashed: `->withoutTrashed()` when needed
- Include `deleted_at` in relevant queries explicitly

## Observers vs Events
- Use Observers for model lifecycle hooks tied to a single model
- Use Events+Listeners when multiple handlers need to react
- Register observers in `AppServiceProvider::boot()`
