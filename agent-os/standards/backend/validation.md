# Validation Patterns

## Form Requests
Always use Form Request classes for controller validation — never validate inline in controllers:

```php
// app/Http/Requests/StoreUserRequest.php
class StoreUserRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()->can('create', User::class);
    }

    public function rules(): array
    {
        return [
            'name'  => ['required', 'string', 'max:255'],
            'email' => ['required', 'email', 'unique:users,email'],
            'role'  => ['required', Rule::in(['admin', 'editor', 'viewer'])],
        ];
    }
}
```

## Rule Guidelines
- Use array syntax for rules, not pipe strings: `['required', 'email']` not `'required|email'`
- Use `Rule::in()`, `Rule::exists()`, `Rule::unique()` for complex rules
- Custom rules go in `app/Rules/` — implement `ValidationRule` interface
- Add custom error messages in `messages()` method only when default is unclear

## Filament Forms
Filament handles its own validation via component `->required()`, `->rules()` etc.:

```php
TextInput::make('email')
    ->email()
    ->required()
    ->unique(User::class, ignorable: fn ($record) => $record),
```

- Use `->rules([])` for additional Laravel validation rules on Filament fields
- Use `->validationMessages([])` to customize messages per field
- For cross-field validation, use `->afterStateUpdated()` or form-level `->rules()`
