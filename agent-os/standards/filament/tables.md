# Filament v4 Tables

---

## 1. Table Structure

```php
use Filament\Tables\Table;

public static function table(Table $table): Table
{
    return $table
        ->columns([...])
        ->filters([...])
        ->recordActions([...])          // row-level actions (v4)
        ->groupedBulkActions([...])     // bulk actions (v4)
        ->defaultSort('created_at', 'desc');
}
```

> **v4 change:** Resource tables use `->recordActions()` and `->groupedBulkActions()`.
> `->actions()` / `->bulkActions()` are the v3 API — do not use in resource tables.

---

## 2. Action Methods by Context

| Context | Row actions | Bulk actions | Header actions |
|---|---|---|---|
| Resource table | `->recordActions([])` | `->groupedBulkActions([])` | — |
| Relation manager table | `->actions([])` | `->bulkActions([])` | `->headerActions([])` |

---

## 3. Action Import Namespace

**All** actions come from `Filament\Actions\*` in v4 — not from `Filament\Tables\Actions\*`:

```php
// ✅ Filament v4
use Filament\Actions\CreateAction;
use Filament\Actions\EditAction;
use Filament\Actions\DeleteAction;
use Filament\Actions\ViewAction;
use Filament\Actions\Action;
use Filament\Actions\BulkActionGroup;
use Filament\Actions\DeleteBulkAction;
use Filament\Actions\BulkAction;

// ❌ Filament v3 — wrong in v4
use Filament\Tables\Actions\EditAction;
use Filament\Tables\Actions\DeleteBulkAction;
```

---

## 4. Column Patterns

```php
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Columns\IconColumn;
use Filament\Tables\Columns\ToggleColumn;

TextColumn::make('status')
    ->badge()
    ->color(fn (string $state): string => match ($state) {
        'active'  => 'success',
        'pending' => 'warning',
        default   => 'gray',
    }),

IconColumn::make('is_active')->boolean(),

TextColumn::make('relation.column')  // auto eager-loads
    ->searchable()
    ->sortable()
    ->placeholder('-'),  // shown when null
```

---

## 5. Filters

```php
use Filament\Tables\Filters\SelectFilter;

SelectFilter::make('status')->options(StatusEnum::class),  // pass Enum class directly
SelectFilter::make('plan_id')->relationship('plan', 'name'),
```

---

## 6. Custom Search on Relation Columns

```php
TextColumn::make('contact.full_name')
    ->searchable(
        query: fn (Builder $query, string $search): Builder =>
            $query->whereHas('contact', fn (Builder $q) =>
                $q->where('first_name', 'like', "%{$search}%")
                  ->orWhere('last_name', 'like', "%{$search}%")
            )
    ),
```

---

## 7. Empty State

```php
->emptyStateHeading('No records yet')
->emptyStateDescription('Create your first record to get started.')
->emptyStateIcon('heroicon-o-inbox'),
```
