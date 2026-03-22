# Audit Trail Pattern (Phoenix Sys)

## Approach: ModelHandler Global Listener
Auto-populate `created_by`, `updated_by`, `deleted_by` on all models without boilerplate.

```php
// app/Listeners/ModelHandler.php
class ModelHandler
{
    public function handleCreated(Model $model): void
    {
        if ($this->hasColumn($model, 'created_by') && auth()->id()) {
            $model->created_by = auth()->id();
            $model->saveQuietly();
        }
    }

    public function handleUpdated(Model $model): void
    {
        if ($this->hasColumn($model, 'updated_by') && auth()->id()) {
            $model->updated_by = auth()->id();
            $model->saveQuietly(); // avoids event recursion
        }
    }

    public function handleDeleted(Model $model): void
    {
        if ($this->hasColumn($model, 'deleted_by') && auth()->id() && $model->usesSoftDeletes()) {
            $model->deleted_by = auth()->id();
            $model->saveQuietly();
        }
    }

    private function hasColumn(Model $model, string $column): bool
    {
        return in_array($column, $model->getFillable(), true)
            || Schema::hasColumn($model->getTable(), $column);
    }
}
```

```php
// EventServiceProvider.php
protected $listen = [
    'eloquent.created: *' => [ModelHandler::class . '@handleCreated'],
    'eloquent.updated: *' => [ModelHandler::class . '@handleUpdated'],
    'eloquent.deleted: *' => [ModelHandler::class . '@handleDeleted'],
];
```

## HasAuditTrail Trait
Add to models that need tracking columns:

```php
trait HasAuditTrail
{
    protected function initializeHasAuditTrail(): void
    {
        $this->fillable = array_merge($this->fillable, ['created_by', 'updated_by', 'deleted_by']);
    }
}
```

## Standard Audit Columns
Every major model should have:
```php
// In migration
$table->foreignId('created_by')->nullable()->constrained('users')->nullOnDelete();
$table->foreignId('updated_by')->nullable()->constrained('users')->nullOnDelete();
$table->foreignId('deleted_by')->nullable()->constrained('users')->nullOnDelete();
$table->timestamps();
$table->softDeletes();
```

## Activity Log (Domain Events)
For important domain actions, fire events that get logged:

```php
// Log significant actions separately from CRUD tracking
AuditLog::record(
    tenantId: app('tenant')->id,
    userId: auth()->id(),
    action: 'subscription.upgraded',
    subject: $subscription,
    metadata: ['from_plan' => $oldPlan->id, 'to_plan' => $newPlan->id]
);
```
