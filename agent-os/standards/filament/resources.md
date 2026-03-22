# Filament v4 Resources

---

## 1. Resource Structure

```php
use BackedEnum;
use UnitEnum;
use Filament\Resources\Resource;
use Filament\Schemas\Schema;
use Filament\Tables\Table;

class UserResource extends Resource
{
    protected static ?string $model = User::class;

    protected static string | BackedEnum | null $navigationIcon = 'heroicon-o-users';
    protected static string | UnitEnum | null $navigationGroup = 'User Management';
    protected static ?string $navigationLabel = 'Users';
    protected static ?int $navigationSort = 1;

    public static function form(Schema $schema): Schema { ... }
    public static function table(Table $table): Table { ... }
    public static function getRelations(): array { return [...]; }
    public static function getPages(): array { return [...]; }
}
```

---

## 2. Navigation Property Types — Critical

PHP will throw a fatal error if the declared type doesn't match the parent class.

```php
// ✅ Required — match parent's union types exactly
use BackedEnum;  // PHP built-in interface, no namespace needed
use UnitEnum;    // PHP built-in interface, no namespace needed

protected static string | BackedEnum | null $navigationIcon = 'heroicon-o-users';
protected static string | UnitEnum | null $navigationGroup = 'Sales';

// ✅ These simpler types are fine (parent also uses ?string / ?int)
protected static ?string $navigationLabel = 'Accounts';
protected static ?int $navigationSort = 2;
protected static ?string $recordTitleAttribute = 'name';
protected static ?string $slug = 'sales/accounts';
```

> `?string` for `$navigationIcon` or `$navigationGroup` causes PHP fatal: "Type must be ... as in parent class".

---

## 3. `form()` and `table()` Signatures

```php
// ✅ Filament v4 signatures
public static function form(Schema $schema): Schema { ... }
public static function table(Table $table): Table { ... }

// ❌ Filament v3 — wrong in v4
public static function form(Form $form): Form { ... }
```

See `filament/forms.md` for full form API details.

---

## 4. Pages Structure

```php
public static function getPages(): array
{
    return [
        'index'  => Pages\ListUsers::route('/'),
        'create' => Pages\CreateUser::route('/create'),
        'edit'   => Pages\EditUser::route('/{record}/edit'),
        'view'   => Pages\ViewUser::route('/{record}'),  // optional
    ];
}
```

---

## 5. Relation Managers

- Place in `ResourceName/RelationManagers/`
- Use `form(Schema $schema): Schema` (instance method, not static)
- Use `->actions()` / `->bulkActions()` / `->headerActions()` (relation manager table API)

```php
class ContactsRelationManager extends RelationManager
{
    protected static string $relationship = 'contacts';

    public function form(Schema $schema): Schema { ... }
    public function table(Table $table): Table { ... }
}
```

---

## 6. Cross-Tenant / Global Queries (Root Panel)

```php
public static function getEloquentQuery(): Builder
{
    return parent::getEloquentQuery()->withoutGlobalScopes();
}
```

---

## 7. Global Search

```php
public static function getGloballySearchableAttributes(): array
{
    return ['name', 'email', 'number'];
}

public static function getGlobalSearchResultTitle(Model $record): string|Htmlable
{
    return $record->name;
}

public static function getGlobalSearchResultDetails(Model $record): array
{
    return ['Email' => $record->email];
}
```

---

## 8. Navigation Badge (count indicator)

```php
public static function getNavigationBadge(): ?string
{
    return (string) static::getModel()::where('status', 'new')->count();
}
```
