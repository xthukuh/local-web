# Filament v4 Forms (Schema API)

In Filament v4, `form()` accepts `Schema`, not `Form`. `Section` moved to the Schemas namespace.

---

## 1. Resource `form()` Signature

```php
use Filament\Schemas\Schema;

public static function form(Schema $schema): Schema
{
    return $schema->components([
        Section::make()->schema([...]),
    ]);
}
```

> `->components([...])` is the Schema method. Do not use `->schema([...])` on `Schema` — that is the v3 API.

---

## 2. Section Namespace

```php
// ✅ Filament v4
use Filament\Schemas\Components\Section;

// ❌ Filament v3 — causes runtime errors in v4
use Filament\Forms\Components\Section;
```

---

## 3. Form Field Namespaces (unchanged)

Standard fields remain in `Filament\Forms\Components\*`:

```php
use Filament\Forms\Components\TextInput;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\Textarea;
use Filament\Forms\Components\Toggle;
use Filament\Forms\Components\DateTimePicker;
```

---

## 4. Reactive `Get` Utility

```php
// ✅ Filament v4
use Filament\Schemas\Components\Utilities\Get;

// ❌ Filament v3 — no longer correct
use Filament\Forms\Get;

// Usage (unchanged):
->visible(fn (Get $get) => $get('type') === 'individual')
```

---

## 5. Relation Manager `form()` Signature

Relation managers use the same `Schema` signature:

```php
use Filament\Schemas\Schema;

public function form(Schema $schema): Schema
{
    return $schema->components([...]);
}
```

---

## 6. Read-Only Fields Inside Schema (TextEntry)

Audit/display fields (created_at, updated_by, etc.) use `TextEntry` inside Schema sections:

```php
use Filament\Infolists\Components\TextEntry;

Section::make()
    ->schema([
        TextEntry::make('created_at')
            ->state(fn (Model $record): string => $record->created_at->diffForHumans()),
    ])
    ->hidden(fn (?Model $record) => $record === null), // hide on create
```

---

## 7. Common Field Patterns

- `TextInput` — use `->email()`, `->numeric()`, `->tel()` modifiers
- `Select` — use `->relationship()` for Eloquent BelongsTo, `->options()` for static lists
- `Toggle` — for boolean fields (better UX than Checkbox)
- `DateTimePicker` — use `->timezone(config('app.timezone'))`
- `Select::make()->live()` — triggers reactive updates on change

```php
Select::make('type')
    ->options(AccountType::class) // pass Enum class directly
    ->live()
    ->required(),

TextInput::make('company')
    ->visible(fn (Get $get) => $get('type') !== AccountType::Person->value),
```
