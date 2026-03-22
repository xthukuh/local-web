# Filament v5.x Resources

## Resource Structure
Each Filament resource lives in `app/Filament/Resources/` and follows this pattern:

```php
class UserResource extends Resource
{
    protected static ?string $model = User::class;
    protected static ?string $navigationIcon = 'heroicon-o-users';
    protected static ?string $navigationGroup = 'User Management';
    protected static ?int $navigationSort = 1;

    public static function form(Form $form): Form { ... }
    public static function table(Table $table): Table { ... }
    public static function infolist(Infolist $infolist): Infolist { ... }
    public static function getRelations(): array { ... }
    public static function getPages(): array { ... }
}
```

## Navigation Organization
- Group related resources with `$navigationGroup`
- Use `$navigationSort` for explicit ordering within groups
- Set `$navigationBadge` for count indicators: `return static::getModel()::count()`
- Use Heroicons for `$navigationIcon` — always `heroicon-o-` (outline) prefix

## Pages
- Default pages: `ListRecords`, `CreateRecord`, `EditRecord`
- Add `ViewRecord` page when a read-only detail view is needed
- Custom pages extend `Page` and register in `getPages()`

## Relation Managers
- Place in `app/Filament/Resources/{Resource}/RelationManagers/`
- Use for managing hasMany/belongsToMany from a parent resource
- Each relation manager has its own `form()` and `table()` methods

## Authorization
- Use `canAccess()`, `canCreate()`, `canEdit()`, `canDelete()` to gate resource actions
- Wire to Laravel Policies: `return auth()->user()->can('update', $record)`
- Use `$record` parameter in permission checks for instance-level gates

## Global Search
- Enable with `protected static bool $shouldRegisterNavigation = true`
- Implement `getGlobalSearchResultTitle()` and `getGlobalSearchResultDetails()`
- Index searchable attributes in `getGloballySearchableAttributes()`
# Filament v5.x Forms

## Form Layout Patterns
Organize fields using layout components for clarity:

```php
public static function form(Form $form): Form
{
    return $form->schema([
        Section::make('Basic Information')
            ->schema([
                TextInput::make('name')->required()->columnSpan(1),
                TextInput::make('email')->email()->required()->columnSpan(1),
            ])->columns(2),

        Section::make('Settings')
            ->schema([...])
            ->collapsible(),
    ]);
}
```

## Common Field Patterns
- `TextInput` — standard text, use `->email()`, `->numeric()`, `->tel()` modifiers
- `Select` — use `->relationship()` for Eloquent relations, `->options()` for static lists
- `Toggle` — for boolean fields, not Checkbox (better UX)
- `DateTimePicker` — use `->timezone(config('app.timezone'))` for consistency
- `FileUpload` — use `->disk('public')` and `->directory('uploads/model-name')`
- `RichEditor` — for HTML content; limit toolbar buttons via `->toolbarButtons([])`
- `Repeater` — for JSON arrays or hasMany inline editing
- `KeyValue` — for simple key-value metadata fields

## Reactive Fields
Use `->live()` for fields that affect others dynamically:

```php
Select::make('category_id')
    ->live()
    ->afterStateUpdated(fn (Set $set) => $set('subcategory_id', null)),

Select::make('subcategory_id')
    ->options(fn (Get $get) => Subcategory::where('category_id', $get('category_id'))->pluck('name', 'id')),
```

## Relationship Fields
- `Select::make()->relationship()` for BelongsTo
- `CheckboxList::make()->relationship()` for BelongsToMany
- `Repeater::make()->relationship()` for HasMany inline editing

## Validation
- Chain validation directly on fields: `->required()`, `->minLength(3)`, `->unique()`
- Use `->unique(ignorable: fn ($record) => $record)` on edit forms
- Add custom rules: `->rules(['regex:/^[A-Z]/'])`

## Hidden / Computed Fields
```php
Hidden::make('created_by')->default(fn () => auth()->id()),
Placeholder::make('created_at')->content(fn ($record) => $record?->created_at->diffForHumans()),
```
# Filament v5.x Tables

## Table Structure

```php
public static function table(Table $table): Table
{
    return $table
        ->columns([...])
        ->filters([...])
        ->actions([...])
        ->bulkActions([...])
        ->defaultSort('created_at', 'desc')
        ->paginated([10, 25, 50]);
}
```

## Column Patterns
- `TextColumn` — default for most text; use `->description()` for secondary text
- `BadgeColumn` → use `->badge()` on TextColumn with `->color()` for status fields
- `IconColumn` — for boolean fields: `->boolean()`
- `ImageColumn` — for media: `->circular()` for avatars
- `TextColumn::make('relation.column')` — for related model values (auto eager loads)

```php
TextColumn::make('status')
    ->badge()
    ->color(fn (string $state) => match ($state) {
        'active'   => 'success',
        'pending'  => 'warning',
        'inactive' => 'danger',
    }),
```

## Searchable & Sortable
- Add `->searchable()` to columns users need to search by
- Add `->sortable()` to columns that need sorting
- For relation columns: `->searchable(query: fn ($q, $s) => $q->whereHas('relation', fn($q) => $q->where('name', 'like', "%{$s}%")))`

## Filters
```php
SelectFilter::make('status')->options(UserStatus::class),
Filter::make('created_this_month')
    ->query(fn ($query) => $query->whereMonth('created_at', now()->month)),
TernaryFilter::make('email_verified_at')->nullable(),
```

## Actions
- Row actions: `EditAction`, `DeleteAction`, `ViewAction` — import from `Filament\Tables\Actions`
- Custom actions with confirmation: use `->requiresConfirmation()` with `->modalDescription()`
- Bulk actions: wrap in `BulkActionGroup` for dropdown grouping

## Empty State
```php
->emptyStateHeading('No records yet')
->emptyStateDescription('Create your first record to get started.')
->emptyStateActions([CreateAction::make()])
```

## Query Modification
- Override `getTableQuery()` in the resource page to scope data:
```php
protected function getTableQuery(): Builder
{
    return parent::getTableQuery()->where('user_id', auth()->id());
}
```
# Filament v5.x Actions

## Action Types
- **Table Row Actions** — `Tables\Actions\Action` — appear per row
- **Table Bulk Actions** — `Tables\Actions\BulkAction` — operate on selected rows
- **Header Actions** — `Actions\Action` on pages — appear in page header
- **Form Actions** — `Forms\Components\Actions\Action` — inline in forms
- **Infolist Actions** — appear in view pages

## Basic Action Pattern

```php
Action::make('approve')
    ->label('Approve')
    ->icon('heroicon-o-check-circle')
    ->color('success')
    ->requiresConfirmation()
    ->modalHeading('Approve this record?')
    ->modalDescription('This action cannot be undone.')
    ->action(function (Model $record): void {
        $record->update(['status' => 'approved']);
        Notification::make()->title('Approved')->success()->send();
    }),
```

## Modal Actions with Forms

```php
Action::make('reject')
    ->form([
        Textarea::make('reason')->required()->label('Rejection Reason'),
    ])
    ->action(function (array $data, Model $record): void {
        $record->reject($data['reason']);
        Notification::make()->title('Rejected')->warning()->send();
    }),
```

## Bulk Actions

```php
BulkAction::make('mark_active')
    ->label('Mark as Active')
    ->icon('heroicon-o-check')
    ->requiresConfirmation()
    ->action(function (Collection $records): void {
        $records->each->update(['status' => 'active']);
        Notification::make()->title(count($records) . ' records activated')->success()->send();
    })
    ->deselectRecordsAfterCompletion(),
```

## Notifications
Always send a notification after action completion:

```php
// Success
Notification::make()->title('Saved')->success()->send();

// With body
Notification::make()->title('Email sent')->body('User notified at ' . $record->email)->success()->send();

// Error
Notification::make()->title('Failed')->body($e->getMessage())->danger()->send();
```

## Action Authorization
```php
->visible(fn ($record) => auth()->user()->can('approve', $record))
->hidden(fn ($record) => $record->status === 'approved')
->disabled(fn ($record) => !$record->canBeEdited())
```

## Halting Actions
Use `$this->halt()` to stop execution on validation failure:

```php
->action(function (Model $record, Action $action): void {
    if (!$record->isEligible()) {
        Notification::make()->title('Not eligible')->danger()->send();
        $action->halt();
    }
    // proceed...
}),
```
