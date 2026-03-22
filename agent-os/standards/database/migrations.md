# Database Migrations

## Migration Conventions
- One table per migration file — never combine unrelated changes
- File naming: `{verb}_{description}_table` — `create_users_table`, `add_status_to_orders_table`
- Always write both `up()` and `down()` methods

## Column Standards
```php
Schema::create('orders', function (Blueprint $table) {
    $table->id();                         // auto-increment bigint PK (always first)
    $table->foreignId('user_id')->constrained()->cascadeOnDelete();
    $table->string('status', 50)->default('pending');
    $table->decimal('total', 10, 2)->default(0);
    $table->text('notes')->nullable();
    $table->json('metadata')->nullable();
    $table->timestamps();                 // created_at, updated_at (always last)
    $table->softDeletes();                // deleted_at (before timestamps if used)
});
```

## Foreign Keys
- Use `foreignId()->constrained()` shorthand — it auto-resolves table/column
- Always define cascade behavior: `->cascadeOnDelete()` or `->nullOnDelete()`
- For non-standard references: `$table->foreign('author_id')->references('id')->on('users')`

## Indexes
- Add index on columns used in `WHERE`, `ORDER BY`, `JOIN`:
```php
$table->index('status');
$table->index(['user_id', 'status']); // composite index
$table->unique('email');
```

## Altering Tables
```php
// Adding columns
Schema::table('users', function (Blueprint $table) {
    $table->string('phone')->nullable()->after('email');
});

// Dropping columns — always nullable or have default first
Schema::table('users', function (Blueprint $table) {
    $table->dropColumn('legacy_field');
});
```

## Never In Migrations
- Never reference Eloquent models in migrations (models change, migrations are permanent)
- Never use `DB::table()` for data seeding — use Seeders instead
- Never skip the `down()` method for rollback safety
