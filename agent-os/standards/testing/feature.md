# Feature Testing Patterns

## Test Structure
Use Pest PHP (preferred) or PHPUnit for feature tests:

```php
// Pest PHP style
it('allows admin to create a user', function () {
    $admin = User::factory()->admin()->create();

    $response = $this->actingAs($admin)
        ->postJson('/api/v1/users', [
            'name'  => 'John Doe',
            'email' => 'john@example.com',
            'role'  => 'editor',
        ]);

    $response->assertCreated()
             ->assertJsonPath('data.name', 'John Doe');

    $this->assertDatabaseHas('users', ['email' => 'john@example.com']);
});
```

## Test Organization
- Feature tests in `tests/Feature/` — test HTTP endpoints end-to-end
- Unit tests in `tests/Unit/` — test isolated classes/methods
- Name test files after the feature: `UserManagementTest.php`, `OrderCheckoutTest.php`

## Database
- Use `RefreshDatabase` trait on every test class that hits the DB
- Use factories for test data — never hardcode IDs
- Use `->state()` for specific scenarios: `User::factory()->suspended()->create()`

## API Testing Patterns
```php
// Auth
$this->actingAs($user, 'sanctum');

// Assert structure
$response->assertJsonStructure(['data' => ['id', 'name', 'email']]);

// Assert pagination
$response->assertJsonCount(15, 'data');

// Assert 422 validation
$response->assertUnprocessable()
         ->assertJsonValidationErrors(['email']);
```

## Filament Testing
```php
use Filament\Tests\TestCase;

it('can list users in Filament', function () {
    $this->actingAs(User::factory()->admin()->create());

    livewire(ListUsers::class)
        ->assertCanSeeTableRecords(User::factory(5)->create());
});

it('can create a user via Filament form', function () {
    livewire(CreateUser::class)
        ->fillForm(['name' => 'Test', 'email' => 'test@example.com'])
        ->call('create')
        ->assertHasNoFormErrors();

    $this->assertDatabaseHas('users', ['email' => 'test@example.com']);
});
```

## What to Always Test
- Happy path (successful operation)
- Auth: unauthenticated returns 401, unauthorized returns 403
- Validation: required fields, invalid formats, duplicate uniques
- Edge cases relevant to business rules
