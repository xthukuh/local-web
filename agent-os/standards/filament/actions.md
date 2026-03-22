# Filament v4 Actions

All action types import from `Filament\Actions\*` — a single namespace for everything.

---

## 1. Import Namespace (Critical)

```php
// ✅ All actions from one namespace in v4
use Filament\Actions\Action;
use Filament\Actions\CreateAction;
use Filament\Actions\EditAction;
use Filament\Actions\DeleteAction;
use Filament\Actions\ViewAction;
use Filament\Actions\BulkAction;
use Filament\Actions\BulkActionGroup;
use Filament\Actions\DeleteBulkAction;

// ❌ Wrong in v4 — these no longer exist as separate namespaces
use Filament\Tables\Actions\EditAction;
use Filament\Pages\Actions\Action;
```

---

## 2. Standard Row Actions

```php
// Resource table:
->recordActions([
    EditAction::make(),
    DeleteAction::make(),
])

// Relation manager table:
->actions([
    EditAction::make(),
    DeleteAction::make(),
])
```

---

## 3. Bulk Actions

```php
// Resource table:
->groupedBulkActions([
    DeleteBulkAction::make(),
])

// Relation manager table:
->bulkActions([
    BulkActionGroup::make([
        DeleteBulkAction::make(),
    ]),
])
```

---

## 4. Custom Action with Modal Form

```php
Action::make('changeStatus')
    ->label('Change Status')
    ->icon('heroicon-o-arrow-path')
    ->form([
        Select::make('status')
            ->options(StatusEnum::class)
            ->required(),
    ])
    ->action(function (Model $record, array $data): void {
        $record->update(['status' => $data['status']]);
        Notification::make()->title('Status updated')->success()->send();
    }),
```

---

## 5. Confirmation Actions

```php
Action::make('void')
    ->label('Void Invoice')
    ->color('danger')
    ->requiresConfirmation()
    ->modalHeading('Void this invoice?')
    ->modalDescription('This cannot be undone.')
    ->action(function (Model $record): void {
        $record->update(['status' => 'void', 'voided_at' => now()]);
        Notification::make()->title('Invoice voided')->success()->send();
    }),
```

---

## 6. Bulk Action with Collection

```php
BulkAction::make('requestPayout')
    ->label('Request Payout')
    ->requiresConfirmation()
    ->action(function (Collection $records): void {
        $records->each(fn ($r) => $r->update(['status' => 'requested']));
        Notification::make()->title('Payout requested')->success()->send();
    }),
```

---

## 7. Notifications — Always Send After Action

```php
// Success
Notification::make()->title('Saved')->success()->send();

// With body
Notification::make()
    ->title('Email sent')
    ->body("User notified at {$record->email}")
    ->success()
    ->send();

// Error / halt
Notification::make()->title('Failed')->body($e->getMessage())->danger()->send();
$action->halt(); // stop execution inside action callback
```

---

## 8. Visibility / Authorization

```php
->visible(fn (Model $record): bool => $record->status !== 'paid')
->hidden(fn (Model $record): bool => $record->is_locked)
->disabled(fn (Model $record): bool => !$record->canBeEdited())
```
