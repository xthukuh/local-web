# Filament v4 Schema/Table Delegation & Custom Fields

---

## 1. Form/Table Delegation Pattern

Resources stay thin. Form and table logic is delegated to dedicated classes.

**Resource (thin):**
```php
class OrderResource extends Resource
{
    public static function form(Schema $schema): Schema
    {
        return OrderForm::configure($schema);
    }

    public static function table(Table $table): Table
    {
        return OrdersTable::configure($table);
    }
}
```

**Form class** at `ResourceName/Schemas/OrderForm.php`:
```php
namespace App\Filament\Resources\Shop\Orders\Schemas;

use Filament\Schemas\Schema;
use Filament\Schemas\Components\Section;
use Filament\Forms\Components\TextInput;

class OrderForm
{
    public static function configure(Schema $schema): Schema
    {
        return $schema->components([
            Section::make()->schema([
                TextInput::make('number')->disabled(),
                // ...
            ])->columns(2),
        ]);
    }
}
```

**Table class** at `ResourceName/Tables/OrdersTable.php`:
```php
namespace App\Filament\Resources\Shop\Orders\Tables;

use Filament\Actions\EditAction;
use Filament\Actions\DeleteBulkAction;
use Filament\Tables\Table;

class OrdersTable
{
    public static function configure(Table $table): Table
    {
        return $table
            ->columns([...])
            ->filters([...])
            ->recordActions([EditAction::make()])
            ->groupedBulkActions([DeleteBulkAction::make()]);
    }
}
```

---

## 2. Directory Structure

```
app/Filament/Root/Resources/
└── LicensePlanResource/
    ├── Pages/
    │   ├── ListLicensePlans.php
    │   ├── CreateLicensePlan.php
    │   └── EditLicensePlan.php
    ├── RelationManagers/
    │   └── LicensePlanLimitsRelationManager.php
    ├── Schemas/               ← form logic
    │   └── LicensePlanForm.php
    └── Tables/                ← table logic
        └── LicensePlansTable.php
```

---

## 3. Custom Form Field

Extend `Filament\Forms\Components\Field`. Use instance `$view` (NOT static).

```php
namespace App\Filament\Fields;

use Closure;
use Filament\Forms\Components\Field;

class StageIndicator extends Field
{
    protected string $view = 'filament.fields.stage-indicator'; // instance, not static

    public array | Closure $stages = [];

    protected function setUp(): void
    {
        parent::setUp();

        $this->afterStateHydrated(function (StageIndicator $component, $state): void {
            if ($state === null) {
                $component->state($component->getDefaultState());
            }
        });
    }

    public function stages(array | Closure $stages): static
    {
        $this->stages = $stages;
        return $this;
    }

    public function getViewData(): array
    {
        return array_merge(parent::getViewData() ?? [], [
            'stages' => $this->evaluate($this->stages),
        ]);
    }
}
```

---

## 4. Custom Composite Field (embedded children)

For fields that render a group of sub-fields (like an address form):

```php
namespace App\Forms\Components;

use Filament\Forms\Components\Field;
use Filament\Forms\Components\TextInput;
use Filament\Schemas\Components\Grid;

class AddressForm extends Field
{
    protected string $view = 'filament-schemas::components.grid'; // reuse Grid view

    public function getDefaultChildComponents(): array
    {
        return [
            Grid::make()
                ->schema([
                    TextInput::make('street')->maxLength(255),
                    TextInput::make('city')->maxLength(255),
                ]),
        ];
    }

    protected function setUp(): void
    {
        parent::setUp();

        $this->afterStateHydrated(function (AddressForm $component, ?Model $record): void {
            $address = $record?->getRelationValue($this->getRelationship());
            $component->state($address ? $address->toArray() : [
                'street' => null, 'city' => null,
            ]);
        });

        $this->dehydrated(false); // don't submit as a single field value
    }
}
```

---

## 5. Key Rules

- `protected string $view` — instance property (NOT static) on both Pages and custom Fields
- `Field::setUp()` — always call `parent::setUp()` first
- `$this->dehydrated(false)` — use on composite fields that save via `saveRelationships()`
- `$this->evaluate($closure)` — evaluates a Closure or returns a plain value
